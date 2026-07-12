#!/usr/bin/env julia

module SlurmManifestGenerator

using Dates
using TOML
using UUIDs

export build_slurm_manifest, default_run_id, expand_slurm_tasks, write_slurm_manifest

timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
default_run_id(t=now(UTC)) = "slurm_" * Dates.format(t, dateformat"yyyymmdd_HHMMSS")

function task_id(index, family)
    return "task_$(lpad(string(index), 3, '0'))_$(family)"
end

function task_id(index, family, decoder, setup)
    parts = String[string(family)]
    !isnothing(decoder) && push!(parts, string(decoder))
    !isnothing(setup) && push!(parts, string(setup))
    suffix = join(sanitize_task_id_part.(parts), "_")
    return "task_$(lpad(string(index), 3, '0'))_$(suffix)"
end

function sanitize_task_id_part(value)
    sanitized = replace(string(value), r"[^A-Za-z0-9]+" => "_")
    sanitized = replace(sanitized, r"^_+|_+$" => "")
    return isempty(sanitized) ? "task" : sanitized
end

db_filename(uuid) = "db_$(uuid).sqlite"

filter_items(filters::AbstractString) = (filters,)
filter_items(filters::AbstractVector) = filters
filter_items(filters::Tuple) = filters
filter_items(filters) = (filters,)

family_items(families::AbstractVector) = families
family_items(families::Tuple) = families
family_items(families) = (families,)

function skip_redundant_prefix(value)
    return chopprefix(chopprefix(string(value), "QuantumClifford.ECC."), "Main.")
end

function skip_redundant_suffix(value)
    parts = split(string(value), "(")
    fixed = [
        chopsuffix(chopsuffix(part, "Decoder"), "ECCSetup")
        for part in parts
    ]
    return join(fixed, "(")
end

function manifest_name(value)
    if hasproperty(value, :f) && hasproperty(value, :kwargs)
        f = manifest_name(getproperty(value, :f))
        kwargs = getproperty(value, :kwargs)
        return "$f($(join(["$key=$val" for (key, val) in pairs(kwargs)], ", ")))"
    end

    return skip_redundant_suffix(skip_redundant_prefix(value))
end

function matches_filter(entry, filter)
    entry == filter && return true
    return manifest_name(entry) == manifest_name(filter)
end

function filtered_entries(entries, filters)
    isnothing(filters) && return entries
    selected = filter_items(filters)
    return [entry for entry in entries if any(filter -> matches_filter(entry, filter), selected)]
end

function family_name(family)
    hasproperty(family, :code_name) && return string(getproperty(family, :code_name))

    try
        return string(nameof(family))
    catch
        return string(family)
    end
end

function get_task_field(task, field::Symbol, default=nothing)
    haskey(task, field) && return task[field]
    string_field = string(field)
    haskey(task, string_field) && return task[string_field]
    return default
end

function normalized_task(task)
    return Dict{String,Any}(
        "family" => string(task),
    )
end

function normalized_task(task::AbstractDict)
    family = get_task_field(task, :family)
    isnothing(family) && error("Slurm manifest task descriptor is missing required field: family")

    normalized = Dict{String,Any}(
        "family" => string(family),
    )

    decoder = get_task_field(task, :decoder)
    setup = get_task_field(task, :setup)
    !isnothing(decoder) && (normalized["decoder"] = string(decoder))
    !isnothing(setup) && (normalized["setup"] = string(setup))

    return normalized
end

function normalized_task(task::NamedTuple)
    return normalized_task(Dict{Symbol,Any}(pairs(task)))
end

function expand_slurm_tasks(code_metadata, families; decoders=nothing, setups=nothing)
    requested = Symbol.(family_items(families))
    requested_set = Set(requested)
    expanded = Dict{String,Any}[]
    metadata_by_family = Dict{Symbol,Any}()

    for (codetype, metadata) in code_metadata
        family = family_name(codetype)
        family_symbol = Symbol(family)
        family_symbol in requested_set || continue
        metadata_by_family[family_symbol] = (family, metadata)
    end

    missing = setdiff(requested_set, Set(keys(metadata_by_family)))
    !isempty(missing) && error("Slurm manifest task expansion requested unknown family/families: $(join(sort!(string.(collect(missing))), ", "))")

    for family_symbol in requested
        family, metadata = metadata_by_family[family_symbol]
        family_decoders = filtered_entries(metadata[:decoders], decoders)
        family_setups = filtered_entries(metadata[:setups], setups)

        for decoder in family_decoders
            for setup in family_setups
                push!(expanded, Dict(
                    "family" => family,
                    "decoder" => manifest_name(decoder),
                    "setup" => manifest_name(setup),
                ))
            end
        end
    end

    return expanded
end

function build_slurm_manifest(task_names; run_root="runs/slurm", run_id=default_run_id())
    run_dir = joinpath(run_root, run_id)
    manifest_path = joinpath(run_dir, "manifest.toml")
    summary_path = joinpath(run_dir, "summary.toml")
    db_dir = joinpath(run_dir, "db")
    log_dir = joinpath(run_dir, "logs")
    status_dir = joinpath(run_dir, "status")

    tasks = Dict{String,Any}[]
    for (index, task_name) in enumerate(task_names)
        task = normalized_task(task_name)
        family = task["family"]
        decoder = get(task, "decoder", nothing)
        setup = get(task, "setup", nothing)
        id = isnothing(decoder) && isnothing(setup) ? task_id(index, family) : task_id(index, family, decoder, setup)
        uuid = string(uuid4())
        filename = db_filename(uuid)
        task_manifest = Dict(
            "id" => id,
            "index" => index,
            "family" => string(family),
            "uuid" => uuid,
            "db_filename" => filename,
            "db_path" => joinpath(db_dir, filename),
            "log_path" => joinpath(log_dir, "$(id).log"),
            "status_path" => joinpath(status_dir, "$(id).toml"),
        )

        haskey(task, "decoder") && (task_manifest["decoder"] = task["decoder"])
        haskey(task, "setup") && (task_manifest["setup"] = task["setup"])

        push!(tasks, task_manifest)
    end

    return Dict(
        "run_id" => run_id,
        "run_dir" => run_dir,
        "generated_at" => timestamp_utc(),
        "manifest_path" => manifest_path,
        "summary_path" => summary_path,
        "db_dir" => db_dir,
        "log_dir" => log_dir,
        "status_dir" => status_dir,
        "tasks" => tasks,
    )
end

function write_slurm_manifest(task_names; run_root="runs/slurm", run_id=default_run_id())
    manifest = build_slurm_manifest(task_names; run_root, run_id)

    if ispath(manifest["run_dir"])
        error("Slurm run directory already exists: $(manifest["run_dir"])")
    end

    mkpath(manifest["db_dir"])
    mkpath(manifest["log_dir"])
    mkpath(manifest["status_dir"])

    open(manifest["manifest_path"], "w") do io
        TOML.print(io, manifest)
    end

    return manifest
end

end
