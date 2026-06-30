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

    timestamp_utc(t=now(UTC)) = Dates.format(t, dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"

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
        return with_task_log(task_manifest) do
            run_task_body(task_manifest)
        end
    end
end

light_results = pmap(run_task, LIGHT_MANIFEST_TASKS)

const HEAVY_WORKER_COUNT = 1
heavy_pool = WorkerPool(workers()[1:min(HEAVY_WORKER_COUNT, nworkers())])
heavy_results = pmap(run_task, heavy_pool, HEAVY_MANIFEST_TASKS)

results = vcat(light_results, heavy_results)
