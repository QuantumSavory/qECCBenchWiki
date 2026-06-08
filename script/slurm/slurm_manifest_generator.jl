#!/usr/bin/env julia

module SlurmManifestGenerator

using Dates
using TOML
using UUIDs

const SCHEMA_VERSION = "1"
const RUN_ROOT = "runs/slurm"
const RUN_ID = "" # Empty means use a timestamp-based run id.

const INCLUDE_FAMILIES = [
    :Gottesman,
    :Toric,
    :Shor9,
    :Steane7,
    :Perfect5,
    :Cleve8,
    :Surface,
    :GeneralizedBicycle,
    :TwoBlockGroupAlgebra,
    :Triangular488,
    :Triangular666,
]

const ALLOW_OVERWRITE = false

Base.@kwdef struct ManifestConfig
    run_root::String = RUN_ROOT
    run_id::Union{Nothing,String} = isempty(RUN_ID) ? nothing : RUN_ID
    include_families::Vector{Symbol} = copy(INCLUDE_FAMILIES)
    allow_overwrite::Bool = ALLOW_OVERWRITE
end

export ManifestConfig,
    artifact_paths,
    build_manifest,
    default_run_id,
    main,
    validate_manifest!,
    write_manifest_file

timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
default_run_id(t=now(UTC)) = "slurm_" * Dates.format(t, dateformat"yyyymmdd_HHMMSS")
resolved_run_id(config::ManifestConfig) = isnothing(config.run_id) || isempty(config.run_id) ? default_run_id() : config.run_id
task_id() = "task_" * string(uuid4())

function artifact_paths(run_root::AbstractString, run_id::AbstractString)
    run_dir = joinpath(run_root, run_id)
    return Dict{String,Any}(
        "run_dir" => run_dir,
        "manifest" => joinpath(run_dir, "manifest.toml"),
        "db_dir" => joinpath(run_dir, "db"),
        "successful_db_dir" => joinpath(run_dir, "db_successful"),
        "log_dir" => joinpath(run_dir, "logs"),
        "status_dir" => joinpath(run_dir, "status"),
        "failure_report" => joinpath(run_dir, "failures.toml"),
        "merged_db" => joinpath(run_dir, "merged_results.sqlite"),
    )
end

default_family_name(family) = family isa Symbol ? string(family) : string(nameof(family))

function family_lookup(code_metadata; family_name_fn=default_family_name)
    lookup = Dict{Symbol,Any}()
    for family in keys(code_metadata)
        name = Symbol(family_name_fn(family))
        haskey(lookup, name) && error("duplicate code family name in metadata: $name")
        lookup[name] = family
    end
    return lookup
end

function task_artifacts(paths, id)
    return Dict{String,Any}(
        "db_dir" => joinpath(paths["db_dir"], id),
        "log" => joinpath(paths["log_dir"], "$id.log"),
        "status" => joinpath(paths["status_dir"], "$id.toml"),
    )
end

function build_tasks(code_metadata, config::ManifestConfig, paths; family_name_fn=default_family_name)
    lookup = family_lookup(code_metadata; family_name_fn)
    missing_families = setdiff(config.include_families, collect(keys(lookup)))
    isempty(missing_families) || error("unknown code families in include_families: $(join(string.(missing_families), ", "))")

    tasks = Dict{String,Any}[]
    for (task_index, family_symbol) in enumerate(config.include_families)
        family = lookup[family_symbol]
        family_name = string(family_name_fn(family))
        id = task_id()
        push!(tasks, Dict{String,Any}(
            "id" => id,
            "task_index" => task_index,
            "family" => family_name,
            "family_symbol" => string(family_symbol),
            "artifacts" => task_artifacts(paths, id),
        ))
    end

    validate_unique!(getindex.(tasks, "id"), "task id")
    for artifact_name in ("db_dir", "log", "status")
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
)
    run_id = resolved_run_id(config)
    paths = artifact_paths(config.run_root, run_id)
    tasks = build_tasks(code_metadata, config, paths; family_name_fn)

    manifest = Dict{String,Any}(
        "schema_version" => SCHEMA_VERSION,
        "generated_at" => generated_at,
        "run" => Dict{String,Any}(
            "id" => run_id,
            "root" => config.run_root,
        ),
        "config" => Dict{String,Any}(
            "include_families" => string.(config.include_families),
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
    for artifact_name in ("db_dir", "log", "status")
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
    )
end

function main()
    repo_root = abspath(joinpath(@__DIR__, "..", ".."))
    project = load_project_metadata(repo_root)
    config = ManifestConfig()
    manifest = build_manifest(
        project.code_metadata,
        config;
        repo_root,
        family_name_fn=project.family_name_fn,
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
