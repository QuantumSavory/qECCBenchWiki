using Logging
using TerminalLoggers
using ProgressLogging

export run_evaluations, prep_everything, code_metadata

global_logger(TerminalLogger(right_justify=120))

include("_0.helpers_and_metadata/helpers.jl")
include("_0.helpers_and_metadata/db_helpers.jl")

using .Helpers: logrange, instancenameof, skipredundantfix
using .DBHelpers: dbrow, dbnarray, dbrow!, init_db!

include("_0.helpers_and_metadata/code_metadata.jl")

using .CodeMetadata: code_metadata
using .Helpers: typenameof

include("_1.code_benchmark_pass/benchmark.jl")
include("_2.markdown_generation_pass/markdown.jl")
include("_2.markdown_generation_pass/figures.jl")

using .CodeBenchmark: evaluate_codes_decoders_setups
using .CodeFigures: prep_figures
using .CodeMarkdown: prep_markdown

#

filter_items(filters::AbstractString) = (filters,)
filter_items(filters::AbstractVector) = filters
filter_items(filters::Tuple) = filters
filter_items(filters) = (filters,)

function matches_filter(entry, filter)
    entry == filter && return true
    return skipredundantfix(entry) == skipredundantfix(filter)
end

function filtered_entries(entries, filters)
    isnothing(filters) && return entries
    selected = filter_items(filters)
    return [entry for entry in entries if any(filter -> matches_filter(entry, filter), selected)]
end

function code_instance_name(codetype, instance_args)
    args = instance_args isa Tuple ? instance_args : (instance_args,)
    return "$(typenameof(codetype))($(join(string.(args), ", ")))"
end

function code_instance_filter_name(codetype, filter)
    filter isa AbstractString && return filter
    filter isa Tuple && return code_instance_name(codetype, filter)

    try
        return instancenameof(filter)
    catch
        return filter
    end
end

function matches_code_instance_filter(codetype, instance_args, filter)
    instance_name = code_instance_name(codetype, instance_args)
    instance_name == filter && return true
    return skipredundantfix(instance_name) == skipredundantfix(code_instance_filter_name(codetype, filter))
end

function filtered_code_instance_args(codetype, instance_args_list, filters)
    isnothing(filters) && return instance_args_list
    selected = filter_items(filters)
    return [
        instance_args for instance_args in instance_args_list
        if any(filter -> matches_code_instance_filter(codetype, instance_args, filter), selected)
    ]
end

function run_evaluations(code_metadata; include=nothing, code_instances=nothing, decoders=nothing, setups=nothing, db_path="codes/", db_filename=nothing)
    if isnothing(db_filename)
        init_db!(db_path)
    else
        init_db!(db_path; filename=db_filename)
    end
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        !isnothing(include) && codetype ∉ include && continue
        instance_args_list = filtered_code_instance_args(codetype, metadata[:family], code_instances)
        codes = [codetype(instance_args...) for instance_args in instance_args_list]
        family_decoders = filtered_entries(metadata[:decoders], decoders)
        family_setups = filtered_entries(metadata[:setups], setups)
        (isempty(codes) || isempty(family_decoders) || isempty(family_setups)) && continue
        errrange = metadata[:errrange]
        @info "Evaluating $(codetypename) ..."
        warn = !get(metadata, :redundantrows, false)
        e, n, r = evaluate_codes_decoders_setups(codes, family_decoders, family_setups; errrange, warn)
    end
end

function prep_folders(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        isdir("codes/$codetypename") || mkdir("codes/$codetypename")
    end
end

function prep_everything(code_metadata; plot=true, markdown=true)
    prep_folders(code_metadata)
    plot && prep_figures(code_metadata)
    markdown && prep_markdown(code_metadata)
end
