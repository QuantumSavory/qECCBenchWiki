#!/usr/bin/env julia

module SlurmManifestGenerator

using Dates
using TOML

# ---------------------------------------------------------------------------
# Configuration
#
# Edit these constants to change the default manifest generation plan.
# This script only writes a manifest; it does not submit Slurm jobs or run
# benchmarks.
# ---------------------------------------------------------------------------

const SCHEMA_VERSION = "1"
const RUN_ROOT = "run/slurm"
const RUN_ID = "" # Empty means use a timestamp-based run id.

const LIGHT_FAMILIES = [
    :Gottesman,
    :Toric,
    :Shor9,
    :Steane7,
    :Perfect5,
    :Cleve8,
    :Surface,
]

const HEAVY_FAMILIES = [
    :GeneralizedBicycle,
    :TwoBlockGroupAlgebra,
    :Triangular488,
    :Triangular666,
]

const INCLUDE_FAMILIES = vcat(LIGHT_FAMILIES, HEAVY_FAMILIES)
const ERROR_CHUNK_SIZE = 5
const ALLOW_OVERWRITE = false

Base.@kwdef struct ManifestConfig
    run_root::String = RUN_ROOT
    run_id::Union{Nothing,String} = isempty(RUN_ID) ? nothing : RUN_ID
    include_families::Vector{Symbol} = copy(INCLUDE_FAMILIES)
    heavy_families::Vector{Symbol} = copy(HEAVY_FAMILIES)
    error_chunk_size::Int = ERROR_CHUNK_SIZE
    allow_overwrite::Bool = ALLOW_OVERWRITE
end

export ManifestConfig,
    artifact_paths,
    build_manifest,
    chunk_ranges,
    default_run_id,
    main,
    planned_nsamples,
    validate_manifest!,
    write_manifest_file

timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
default_run_id(t=now(UTC)) = "slurm_" * Dates.format(t, dateformat"yyyymmdd_HHMMSS")
resolved_run_id(config::ManifestConfig) = isnothing(config.run_id) || isempty(config.run_id) ? default_run_id() : config.run_id

"""
Split a collection of items into contiguous chunks of a specified size, returning the index ranges for each chunk. 
"""
function chunk_ranges(nitems::Integer, chunk_size::Integer)
    chunk_size > 0 || throw(ArgumentError("error_chunk_size must be positive; got $chunk_size"))
    nitems >= 0 || throw(ArgumentError("nitems must be nonnegative; got $nitems"))

    ranges = UnitRange{Int}[]
    first_index = 1
    while first_index <= nitems
        last_index = min(first_index + chunk_size - 1, nitems)
        push!(ranges, first_index:last_index)
        first_index = last_index + 1
    end
    return ranges
end

function artifact_paths(run_root::AbstractString, run_id::AbstractString)
    run_dir = joinpath(run_root, run_id)
    return Dict{String,Any}(
        "run_dir" => run_dir,
        "manifest" => joinpath(run_dir, "manifest.toml"),
        "db_dir" => joinpath(run_dir, "db"),
        "log_dir" => joinpath(run_dir, "logs"),
        "status_dir" => joinpath(run_dir, "status"),
        "failure_report" => joinpath(run_dir, "failures.toml"),
        "merged_db" => joinpath(run_dir, "merged_results.sqlite"),
    )
end

# Keep manifest sample planning aligned with the current benchmark pass without
# loading the benchmark module and its runtime dependencies.
planned_nsamples(error_rate::Real) = get(ENV, "ECCBENCHWIKI_QUICKCHECK", "") == "" ? Int(ceil(40 / error_rate)) : 10

default_family_name(family) = family isa Symbol ? string(family) : string(nameof(family))
default_object_name(x) = string(x)
manifest_value(x) = string(x)

function errrange_values(errrange)
    errmin, errmax, steps = errrange
    steps > 0 || throw(ArgumentError("errrange steps must be positive; got $steps"))
    errmin > 0 || throw(ArgumentError("errrange minimum must be positive; got $errmin"))
    errmax > 0 || throw(ArgumentError("errrange maximum must be positive; got $errmax"))
    return collect(exp.(range(log(errmin), log(errmax), length=steps)))
end

function family_lookup(code_metadata; family_name_fn=default_family_name)
    lookup = Dict{Symbol,Any}()
    for family in keys(code_metadata)
        name = Symbol(family_name_fn(family))
        haskey(lookup, name) && error("duplicate code family name in metadata: $name")
        lookup[name] = family
    end
    return lookup
end

function tuple_display(args)
    values = string.(collect(args))
    isempty(values) && return "()"
    suffix = length(values) == 1 ? "," : ""
    return "(" * join(values, ", ") * suffix * ")"
end

function task_artifacts(paths, task_id)
    return Dict{String,Any}(
        "db" => joinpath(paths["db_dir"], "$task_id.sqlite"),
        "log" => joinpath(paths["log_dir"], "$task_id.log"),
        "status" => joinpath(paths["status_dir"], "$task_id.toml"),
        "failure" => joinpath(paths["status_dir"], "$task_id.failure.toml"),
    )
end

function build_tasks(code_metadata, config::ManifestConfig, paths;
    family_name_fn=default_family_name,
    object_name_fn=default_object_name,
)
    config.error_chunk_size > 0 || throw(ArgumentError("error_chunk_size must be positive; got $(config.error_chunk_size)"))

    lookup = family_lookup(code_metadata; family_name_fn)
    missing_families = setdiff(config.include_families, collect(keys(lookup)))
    isempty(missing_families) || error("unknown code families in include_families: $(join(string.(missing_families), ", "))")

    tasks = Dict{String,Any}[]
    task_index = 0
    heavy = Set(config.heavy_families)

    for family_symbol in config.include_families
        family = lookup[family_symbol]
        metadata = code_metadata[family]
        family_name = string(family_symbol)
        errrange = metadata[:errrange]
        errors = errrange_values(errrange)
        ranges = chunk_ranges(length(errors), config.error_chunk_size)
        weight_class = family_symbol in heavy ? "heavy" : "light"

        for (family_index, family_args) in enumerate(metadata[:family])
            code_instance = family_name * tuple_display(family_args)
            for (decoder_index, decoder) in enumerate(metadata[:decoders])
                for (setup_index, setup) in enumerate(metadata[:setups])
                    for (chunk_index, error_range) in enumerate(ranges)
                        task_index += 1
                        task_id = "task_" * lpad(string(task_index), 6, "0")
                        chunk_errors = errors[error_range]
                        push!(tasks, Dict{String,Any}(
                            "id" => task_id,
                            "task_index" => task_index,
                            "weight_class" => weight_class,
                            "family" => family_name,
                            "family_index" => family_index,
                            "family_args" => manifest_value.(collect(family_args)),
                            "family_args_display" => tuple_display(family_args),
                            "code_instance" => code_instance,
                            "decoder_index" => decoder_index,
                            "decoder" => string(object_name_fn(decoder)),
                            "setup_index" => setup_index,
                            "setup" => string(object_name_fn(setup)),
                            "error_chunk_index" => chunk_index,
                            "error_indices" => collect(error_range),
                            "errors" => Float64.(chunk_errors),
                            "planned_nsamples" => planned_nsamples.(chunk_errors),
                            "artifacts" => task_artifacts(paths, task_id),
                        ))
                    end
                end
            end
        end
    end

    validate_unique!(getindex.(tasks, "id"), "task id")
    for artifact_name in ("db", "log", "status", "failure")
        validate_unique!([task["artifacts"][artifact_name] for task in tasks], "$artifact_name artifact path")
    end
    return tasks
end

function validate_unique!(values, label)
    seen = Set{Any}()
    duplicates = Any[]
    for value in values
        if value in seen
            push!(duplicates, value)
        end
        push!(seen, value)
    end
    isempty(duplicates) || error("duplicate $label values: $(join(string.(unique(duplicates)), ", "))")
    return values
end

function maybe_command_output(cmd::Cmd)
    try
        value = chomp(read(cmd, String))
        return isempty(value) ? nothing : value
    catch
        return nothing
    end
end

function git_metadata(repo_root=pwd())
    metadata = Dict{String,Any}("available" => false)
    commit = maybe_command_output(`git -C $repo_root rev-parse HEAD`)
    isnothing(commit) && return metadata

    branch = maybe_command_output(`git -C $repo_root branch --show-current`)
    remote = maybe_command_output(`git -C $repo_root config --get remote.origin.url`)
    dirty_status = maybe_command_output(`git -C $repo_root status --short`)

    metadata["available"] = true
    metadata["commit"] = commit
    metadata["branch"] = isnothing(branch) ? "" : branch
    metadata["remote"] = isnothing(remote) ? "" : remote
    metadata["dirty"] = !isnothing(dirty_status)
    return metadata
end

function build_manifest(code_metadata, config::ManifestConfig=ManifestConfig();
    generated_at=timestamp_utc(),
    repo_root=pwd(),
    include_git=true,
    family_name_fn=default_family_name,
    object_name_fn=default_object_name,
)
    run_id = resolved_run_id(config)
    paths = artifact_paths(config.run_root, run_id)
    tasks = build_tasks(code_metadata, config, paths; family_name_fn, object_name_fn)

    manifest = Dict{String,Any}(
        "schema_version" => SCHEMA_VERSION,
        "generated_at" => generated_at,
        "run" => Dict{String,Any}(
            "id" => run_id,
            "root" => config.run_root,
        ),
        "config" => Dict{String,Any}(
            "include_families" => string.(config.include_families),
            "heavy_families" => string.(config.heavy_families),
            "error_chunk_size" => config.error_chunk_size,
            "allow_overwrite" => config.allow_overwrite,
        ),
        "artifacts" => paths,
        "git" => include_git ? git_metadata(repo_root) : Dict{String,Any}("available" => false),
        "tasks" => tasks,
    )
    validate_manifest!(manifest)
    return manifest
end

function validate_manifest!(manifest)
    tasks = manifest["tasks"]
    validate_unique!(getindex.(tasks, "id"), "task id")
    for artifact_name in ("db", "log", "status", "failure")
        validate_unique!([task["artifacts"][artifact_name] for task in tasks], "$artifact_name artifact path")
    end
    return manifest
end

function write_manifest_file(manifest; allow_overwrite=false)
    paths = manifest["artifacts"]
    run_dir = paths["run_dir"]
    if isdir(run_dir) && !allow_overwrite
        error("run directory already exists: $run_dir; set ALLOW_OVERWRITE = true to write into it")
    end

    mkpath(run_dir)
    mkpath(paths["db_dir"])
    mkpath(paths["log_dir"])
    mkpath(paths["status_dir"])

    manifest_path = paths["manifest"]
    open(manifest_path, "w") do io
        TOML.print(io, manifest)
    end
    return manifest_path
end

function load_project_metadata(repo_root=pwd())
    include(joinpath(repo_root, "_0.helpers_and_metadata", "helpers.jl"))
    include(joinpath(repo_root, "_0.helpers_and_metadata", "code_metadata.jl"))
    return (
        code_metadata=CodeMetadata.code_metadata,
        family_name_fn=Helpers.typenameof,
        object_name_fn=Helpers.skipredundantfix,
    )
end

function main()
    repo_root = abspath(joinpath(@__DIR__, ".."))
    project = load_project_metadata(repo_root)
    config = ManifestConfig()
    manifest = build_manifest(
        project.code_metadata,
        config;
        repo_root,
        family_name_fn=project.family_name_fn,
        object_name_fn=project.object_name_fn,
    )
    manifest_path = write_manifest_file(manifest; allow_overwrite=config.allow_overwrite)
    println("Wrote Slurm run manifest: $manifest_path")
    println("Planned tasks: $(length(manifest["tasks"]))")
    return manifest_path
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    SlurmManifestGenerator.main()
end
