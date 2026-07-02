#!/usr/bin/env julia

module SlurmManifestGenerator

using Dates
using TOML
using UUIDs

export build_slurm_manifest, default_run_id, write_slurm_manifest

timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
default_run_id(t=now(UTC)) = "slurm_" * Dates.format(t, dateformat"yyyymmdd_HHMMSS")

function task_id(index, family)
    return "task_$(lpad(string(index), 3, '0'))_$(family)"
end

db_filename(uuid) = "db_$(uuid).sqlite"

function build_slurm_manifest(task_names; run_root="runs/slurm", run_id=default_run_id())
    run_dir = joinpath(run_root, run_id)
    manifest_path = joinpath(run_dir, "manifest.toml")
    summary_path = joinpath(run_dir, "summary.toml")
    db_dir = joinpath(run_dir, "db")
    log_dir = joinpath(run_dir, "logs")
    status_dir = joinpath(run_dir, "status")

    tasks = Dict{String,Any}[]
    for (index, family) in enumerate(task_names)
        id = task_id(index, family)
        uuid = string(uuid4())
        filename = db_filename(uuid)
        push!(tasks, Dict(
            "id" => id,
            "index" => index,
            "family" => string(family),
            "uuid" => uuid,
            "db_filename" => filename,
            "db_path" => joinpath(db_dir, filename),
            "log_path" => joinpath(log_dir, "$(id).log"),
            "status_path" => joinpath(status_dir, "$(id).toml"),
        ))
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
