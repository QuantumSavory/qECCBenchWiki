#!/usr/bin/env julia

# Run with a command like:
# sbatch -N 4 -n 12 -t 01:00:00 --mem-per-cpu=8g script/slurm/slurm.jl
#
# Edit the config block below for each run. Each task calls run_evaluations for
# one code family and lets the existing project helpers create result files.

const REPO_ROOT = abspath(joinpath(@__DIR__, "..", ".."))

using Pkg
Pkg.activate(REPO_ROOT)
cd(REPO_ROOT)

using Dates
using Distributed
using SlurmClusterManager
using TOML

include(joinpath(@__DIR__, "slurm_manifest_generator.jl"))
include(joinpath(REPO_ROOT, "_0.helpers_and_metadata", "db_join_helper.jl"))

using .SlurmManifestGenerator: ManifestConfig, build_manifest, write_manifest_file
using .DBJoinHelper: join_results

# ---------------------------------------------------------------------------
# Runner config
# ---------------------------------------------------------------------------

const RUN_ROOT = "runs/slurm"
const RUN_ID = "" # Empty means use a timestamp-based run id.
const ALLOW_OVERWRITE = false

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

const MERGE_SUCCESSFUL_DBS = true
const WRITE_FAILURE_REPORT = true

# ---------------------------------------------------------------------------
# Runner helpers
# ---------------------------------------------------------------------------

timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
resolve_run_root(path) = isabspath(path) ? path : joinpath(REPO_ROOT, path)

function write_toml_file(path, data)
    mkpath(dirname(path))
    open(path, "w") do io
        TOML.print(io, data)
    end
    return path
end

function build_run_manifest()
    project = SlurmManifestGenerator.load_project_metadata(REPO_ROOT)
    config = ManifestConfig(
        run_root=resolve_run_root(RUN_ROOT),
        run_id=isempty(RUN_ID) ? nothing : RUN_ID,
        include_families=copy(INCLUDE_FAMILIES),
        allow_overwrite=ALLOW_OVERWRITE,
    )

    manifest = build_manifest(
        project.code_metadata,
        config;
        repo_root=REPO_ROOT,
        family_name_fn=project.family_name_fn,
    )
    manifest_path = write_manifest_file(manifest; allow_overwrite=config.allow_overwrite)
    println("Wrote Slurm run manifest: $manifest_path")
    println("Planned family tasks: $(length(manifest["tasks"]))")
    return manifest
end

function load_worker_code!()
    @everywhere begin
        using Dates
        using TOML

        cd($REPO_ROOT)
        include(joinpath($REPO_ROOT, "wiki_database_passes.jl"))

        function slurm_timestamp_utc(t=now(UTC))
            return Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
        end

        function slurm_sqlite_files(dir)
            isdir(dir) || return String[]
            files = filter(path -> isfile(path) && endswith(lowercase(path), ".sqlite"), readdir(dir; join=true))
            return sort(files)
        end

        function slurm_write_toml_file(path, data)
            mkpath(dirname(path))
            open(path, "w") do io
                TOML.print(io, data)
            end
            return path
        end

        function slurm_family_from_task(task)
            for family in keys(CodeMetadata.code_metadata)
                string(Helpers.typenameof(family)) == task["family"] && return family
            end
            error("unknown code family in manifest task: $(task["family"])")
        end

        function slurm_task_summary(task)
            return Dict{String,Any}(
                "id" => task["id"],
                "task_index" => task["task_index"],
                "family" => task["family"],
                "family_symbol" => task["family_symbol"],
            )
        end

        function run_slurm_manifest_task(task)
            artifacts = task["artifacts"]
            db_dir = artifacts["db_dir"]
            log_path = artifacts["log"]
            status_path = artifacts["status"]
            started_time = time()

            status = Dict{String,Any}(
                "id" => task["id"],
                "state" => "running",
                "worker" => myid(),
                "started_at" => slurm_timestamp_utc(),
                "task" => slurm_task_summary(task),
                "artifacts" => artifacts,
                "sqlite_files" => String[],
            )

            try
                family = slurm_family_from_task(task)
                mkpath(db_dir)
                mkpath(dirname(log_path))

                open(log_path, "w") do log_io
                    redirect_stdout(log_io) do
                        redirect_stderr(log_io) do
                            println("Starting task $(task["id"]) for $(task["family"]) on worker $(myid()) at $(status["started_at"])")
                            run_evaluations(
                                CodeMetadata.code_metadata;
                                include=[family],
                                db_path=db_dir,
                                worker_db=true,
                            )
                            println("Finished task $(task["id"]) at $(slurm_timestamp_utc())")
                        end
                    end
                end
                status["state"] = "success"
            catch err
                error_text = sprint(showerror, err, catch_backtrace())
                status["state"] = "failed"
                status["exception"] = error_text

                try
                    mkpath(dirname(log_path))
                    open(log_path, "a") do log_io
                        println(log_io)
                        println(log_io, "Task $(task["id"]) failed at $(slurm_timestamp_utc())")
                        println(log_io, error_text)
                    end
                catch log_err
                    status["log_write_exception"] = sprint(showerror, log_err, catch_backtrace())
                end
            end

            status["sqlite_files"] = slurm_sqlite_files(db_dir)
            status["finished_at"] = slurm_timestamp_utc()
            status["elapsed_seconds"] = time() - started_time
            slurm_write_toml_file(status_path, status)
            return status
        end
    end
    return nothing
end

function stage_successful_dbs(statuses, stage_dir)
    if isdir(stage_dir)
        rm(stage_dir; recursive=true)
    end
    mkpath(stage_dir)

    staged = String[]
    for status in statuses
        get(status, "state", "") == "success" || continue
        for source in get(status, "sqlite_files", String[])
            destination = joinpath(stage_dir, "$(status["id"])__$(basename(source))")
            try
                symlink(source, destination)
            catch
                cp(source, destination; force=true)
            end
            push!(staged, destination)
        end
    end
    return staged
end

function merge_successful_dbs(statuses, successful_db_dir, output_path)
    staged = stage_successful_dbs(statuses, successful_db_dir)
    if isempty(staged)
        println("No successful task databases to merge.")
        return nothing
    end

    merged_path = join_results(successful_db_dir; output_path=output_path)
    println("Merged $(length(staged)) successful task database(s) into $merged_path")
    return merged_path
end

function write_failure_report(statuses, path)
    failures = [status for status in statuses if get(status, "state", "") != "success"]
    report = Dict{String,Any}(
        "generated_at" => timestamp_utc(),
        "failed_count" => length(failures),
        "failures" => [
            Dict{String,Any}(
                "id" => status["id"],
                "state" => status["state"],
                "worker" => get(status, "worker", ""),
                "task" => status["task"],
                "artifacts" => status["artifacts"],
                "sqlite_files" => get(status, "sqlite_files", String[]),
                "exception" => get(status, "exception", ""),
            )
            for status in failures
        ],
    )
    write_toml_file(path, report)
    println("Wrote failure report: $path ($(length(failures)) failure(s))")
    return path
end

function main()
    manifest = build_run_manifest()
    paths = manifest["artifacts"]

    addprocs(SlurmManager(), exeflags="--project=$(REPO_ROOT)")
    @info "nprocs=$(nprocs()) nworkers=$(nworkers()) workers=$(workers())"

    load_worker_code!()
    statuses = pmap(run_slurm_manifest_task, manifest["tasks"])

    if MERGE_SUCCESSFUL_DBS
        merge_successful_dbs(statuses, paths["successful_db_dir"], paths["merged_db"])
    end
    if WRITE_FAILURE_REPORT
        write_failure_report(statuses, paths["failure_report"])
    end

    failures = count(status -> get(status, "state", "") != "success", statuses)
    println("Completed $(length(statuses) - failures)/$(length(statuses)) family task(s) successfully.")
    return statuses
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
