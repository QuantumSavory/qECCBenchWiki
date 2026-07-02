#! /usr/bin/env julia

# This is the working version of our script

# Run with a command like:
# sbatch -N 4 -n 12 -t 01:00:00 --mem-per-cpu=8g script/slurm/slurm.jl
# Should be run from repo root!

# Do instatiate in julia REPL
ENV["ECCBENCHWIKI_QUICKCHECK"]="true"

using Pkg

Pkg.activate(pwd())

include(joinpath(pwd(), "script/slurm/slurm_manifest_generator.jl"))

using .SlurmManifestGenerator: write_slurm_manifest
using Dates
using TOML

const LIGHT_TASKS = [
    :Gottesman,
    :Toric,
    :Shor9,
    :Steane7,
    :Perfect5,
    :Cleve8,
    :Surface,
]

const HEAVY_TASKS = [
    :GeneralizedBicycle,
    :TwoBlockGroupAlgebra,
    :Triangular488,
    :Triangular666,
]

manifest = write_slurm_manifest(vcat(LIGHT_TASKS, HEAVY_TASKS))
@info "Wrote Slurm manifest" manifest_path=manifest["manifest_path"] run_dir=manifest["run_dir"]

function manifest_tasks(manifest, task_names)
    task_by_family = Dict(Symbol(task["family"]) => task for task in manifest["tasks"])
    return [task_by_family[task_name] for task_name in task_names]
end

const LIGHT_MANIFEST_TASKS = manifest_tasks(manifest, LIGHT_TASKS)
const HEAVY_MANIFEST_TASKS = manifest_tasks(manifest, HEAVY_TASKS)
const MANIFEST_DB_DIR = manifest["db_dir"]

const RUN_SUMMARY_TIMESTAMP_FORMAT = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")

run_summary_timestamp_utc(t=Dates.now(Dates.UTC)) = Dates.format(t, RUN_SUMMARY_TIMESTAMP_FORMAT) * "Z"

function task_status(task_manifest)
    status_path = task_manifest["status_path"]
    return isfile(status_path) ? TOML.parsefile(status_path) : nothing
end

function report_task_entry(task_manifest, status)
    entry = Dict{String,Any}(
        "task_id" => task_manifest["id"],
        "family" => task_manifest["family"],
        "log_path" => task_manifest["log_path"],
        "db_path" => task_manifest["db_path"],
        "status_path" => task_manifest["status_path"],
    )

    if isnothing(status)
        entry["state"] = "missing"
        return entry
    end

    for key in (
        "state",
        "worker_id",
        "started_at",
        "finished_at",
        "exception_text",
        "output_database_files",
        "db_filename",
    )
        haskey(status, key) && (entry[key] = status[key])
    end

    return entry
end

function build_run_summary(manifest)
    succeeded_tasks = Dict{String,Any}[]
    failed_tasks = Dict{String,Any}[]
    incomplete_tasks = Dict{String,Any}[]
    missing_tasks = Dict{String,Any}[]

    for task_manifest in manifest["tasks"]
        status = task_status(task_manifest)
        entry = report_task_entry(task_manifest, status)

        if isnothing(status)
            push!(missing_tasks, entry)
        elseif get(status, "state", "") == "succeeded"
            push!(succeeded_tasks, entry)
        elseif get(status, "state", "") == "failed"
            push!(failed_tasks, entry)
        else
            push!(incomplete_tasks, entry)
        end
    end

    return Dict{String,Any}(
        "run_id" => manifest["run_id"],
        "generated_at" => run_summary_timestamp_utc(),
        "manifest_path" => manifest["manifest_path"],
        "total_tasks" => length(manifest["tasks"]),
        "succeeded_count" => length(succeeded_tasks),
        "failed_count" => length(failed_tasks),
        "incomplete_count" => length(incomplete_tasks),
        "missing_count" => length(missing_tasks),
        "succeeded_tasks" => succeeded_tasks,
        "failed_tasks" => failed_tasks,
        "incomplete_tasks" => incomplete_tasks,
        "missing_tasks" => missing_tasks,
    )
end

function write_run_summary(manifest)
    summary = build_run_summary(manifest)
    summary_path = manifest["summary_path"]
    mkpath(dirname(summary_path))
    open(summary_path, "w") do io
        TOML.print(io, summary)
    end
    return summary
end

function unsuccessful_task_count(summary)
    return summary["failed_count"] + summary["incomplete_count"] + summary["missing_count"]
end

using Distributed
using SlurmClusterManager

addprocs(SlurmManager(), exeflags="--project=$(pwd())")

@info "nprocs=$(nprocs()) nworkers=$(nworkers()) workers=$(workers())"

@everywhere begin
    using Dates
    using Logging
    using TerminalLoggers
    using TOML

    include(joinpath(pwd(), "wiki_database_passes.jl"))

    const SLURM_DB_DIR = $MANIFEST_DB_DIR

    const SLURM_TIMESTAMP_FORMAT = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")

    timestamp_utc(t=Dates.now(Dates.UTC)) = Dates.format(t, SLURM_TIMESTAMP_FORMAT) * "Z"

    function output_database_files(task_manifest)
        db_path = task_manifest["db_path"]
        return isfile(db_path) ? [db_path] : String[]
    end

    function write_task_status(task_manifest; state, started_at, finished_at=nothing, exception_text=nothing)
        status = Dict{String,Any}(
            "task_id" => task_manifest["id"],
            "family" => task_manifest["family"],
            "worker_id" => myid(),
            "started_at" => started_at,
            "state" => state,
            "db_path" => task_manifest["db_path"],
            "db_filename" => task_manifest["db_filename"],
            "output_database_files" => output_database_files(task_manifest),
        )

        if !isnothing(finished_at)
            status["finished_at"] = finished_at
        end

        if !isnothing(exception_text)
            status["exception_text"] = exception_text
        end

        status_path = task_manifest["status_path"]
        mkpath(dirname(status_path))
        open(status_path, "w") do io
            TOML.print(io, status)
        end
    end

    function with_task_log(f, task_manifest)
        log_path = task_manifest["log_path"]
        mkpath(dirname(log_path))

        open(log_path, "w") do log_io
            task_logger = TerminalLogger(log_io; right_justify=120)
            redirect_stdout(log_io) do
                redirect_stderr(log_io) do
                    with_logger(task_logger) do
                        try
                            result = f()
                            flush(log_io)
                            return result
                        catch err
                            println(log_io)
                            println(log_io, "Task failed with exception:")
                            showerror(log_io, err, catch_backtrace())
                            println(log_io)
                            flush(log_io)
                            rethrow()
                        finally
                            flush(log_io)
                        end
                    end
                end
            end
        end
    end

    function run_task_body(task_manifest)
        task_name = Symbol(task_manifest["family"])
        task = getproperty(CodeMetadata, task_name)
        @info "Running task: $task_name on $(myid())"
        started_at = timestamp_utc()
        write_task_status(task_manifest; state="running", started_at=started_at)
        try
            run_evaluations(
                CodeMetadata.code_metadata;
                include=[task],
                db_path=SLURM_DB_DIR,
                db_filename=task_manifest["db_filename"],
            )
            write_task_status(task_manifest; state="succeeded", started_at=started_at, finished_at=timestamp_utc())
        catch err
            write_task_status(
                task_manifest;
                state="failed",
                started_at=started_at,
                finished_at=timestamp_utc(),
                exception_text=sprint(showerror, err),
            )
            rethrow()
        end
        return "Result for $(task_name)"
    end

    function run_task(task_manifest)
        try
            return with_task_log(task_manifest) do
                result = run_task_body(task_manifest)
                return Dict(
                    "task_id" => task_manifest["id"],
                    "family" => task_manifest["family"],
                    "state" => "succeeded",
                    "result" => result,
                )
            end
        catch err
            return Dict(
                "task_id" => task_manifest["id"],
                "family" => task_manifest["family"],
                "state" => "failed",
                "exception_text" => sprint(showerror, err),
            )
        end
    end
end

const HEAVY_WORKER_COUNT = 1

function run_manifest_tasks()
    results = Any[]
    try
        append!(results, pmap(run_task, LIGHT_MANIFEST_TASKS))

        heavy_pool = WorkerPool(workers()[1:min(HEAVY_WORKER_COUNT, nworkers())])
        append!(results, pmap(run_task, heavy_pool, HEAVY_MANIFEST_TASKS))
    catch err
        return results, err
    end
    return results, nothing
end

results, phase_error = run_manifest_tasks()

summary = write_run_summary(manifest)
@info "Wrote Slurm run summary" summary_path=manifest["summary_path"] succeeded=summary["succeeded_count"] failed=summary["failed_count"] incomplete=summary["incomplete_count"] missing=summary["missing_count"]

if !isnothing(phase_error)
    throw(phase_error)
end

unsuccessful = unsuccessful_task_count(summary)
if unsuccessful > 0
    error("Slurm run completed with $(unsuccessful) unsuccessful task(s); see $(manifest["summary_path"])")
end
