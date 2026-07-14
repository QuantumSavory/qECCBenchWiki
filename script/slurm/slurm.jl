#! /usr/bin/env julia

# This is the working version of our script

# Run with a command like:
# sbatch -N 3 -n 9 -t 06:00:00 --mem-per-cpu=8g script/slurm/slurm.jl
# Should be run from repo root!

# Do instatiate in julia REPL
#ENV["ECCBENCHWIKI_QUICKCHECK"]="true"

using Pkg

Pkg.activate(pwd())

include(joinpath(pwd(), "script/slurm/slurm_manifest_generator.jl"))

using .SlurmManifestGenerator: expand_slurm_tasks, write_slurm_manifest
using Dates
using TOML

include(joinpath(pwd(), "wiki_database_passes.jl"))

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

const TASK_DETAIL_FIELDS = ("code_instance", "decoder", "setup")

# Slurm evaluation model
#
# The manifest below expands light code families into one task for every
# decoder/setup combination, and heavy code families into one task for every
# code instance/decoder/setup combination present in CodeMetadata.code_metadata.
# In other words, the distributed unit is:
#
#     light: code family/type + decoder + setup
#     heavy: code family/type + code instance + decoder + setup
#
# Each task gets its own database, log, and status file. When the task runs,
# run_task_body passes the manifest code_instance/decoder/setup fields back into
# run_evaluations as filters, so the task evaluates exactly that requested slice.
#
# This is usually the right granularity for Slurm: it improves load balancing,
# makes failures smaller and easier to retry, and keeps logs/status reports tied
# to the failing task slice instead of rerunning an entire family. The cost is
# extra scheduling and Julia task overhead. For very small families the old
# decoder/setup batching can be cheaper; for heavy or uneven workloads, the
# finer split should normally finish sooner and produce more actionable failure
# artifacts.
manifest_task_descriptors = vcat(
    expand_slurm_tasks(CodeMetadata.code_metadata, LIGHT_TASKS),
    expand_slurm_tasks(CodeMetadata.code_metadata, HEAVY_TASKS; split_code_instances=true),
)
manifest = write_slurm_manifest(manifest_task_descriptors)
@info "Wrote Slurm manifest" manifest_path=manifest["manifest_path"] run_dir=manifest["run_dir"]

function manifest_tasks(manifest, task_names)
    requested = Set(Symbol.(task_names))
    return [task for task in manifest["tasks"] if Symbol(task["family"]) in requested]
end

const LIGHT_MANIFEST_TASKS = manifest_tasks(manifest, LIGHT_TASKS)
const HEAVY_MANIFEST_TASKS = manifest_tasks(manifest, HEAVY_TASKS)
const MANIFEST_DB_DIR = manifest["db_dir"]

const RUN_SUMMARY_TIMESTAMP_FORMAT = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")

run_summary_timestamp_utc(t=Dates.now(Dates.UTC)) = Dates.format(t, RUN_SUMMARY_TIMESTAMP_FORMAT) * "Z"

function parse_run_summary_timestamp(timestamp)
    return Dates.DateTime(chopsuffix(string(timestamp), "Z"), RUN_SUMMARY_TIMESTAMP_FORMAT)
end

function maybe_parse_run_summary_timestamp(timestamp)
    try
        return parse_run_summary_timestamp(timestamp)
    catch
        return nothing
    end
end

function duration_seconds(started_at, finished_at)
    return Dates.value(parse_run_summary_timestamp(finished_at) - parse_run_summary_timestamp(started_at)) / 1000
end

function maybe_duration_seconds(started_at, finished_at)
    try
        return duration_seconds(started_at, finished_at)
    catch
        return nothing
    end
end

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

    for key in TASK_DETAIL_FIELDS
        haskey(task_manifest, key) && (entry[key] = task_manifest[key])
    end

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
        "code_instance",
        "decoder",
        "setup",
        "duration_seconds",
    )
        haskey(status, key) && (entry[key] = status[key])
    end

    if !haskey(entry, "duration_seconds") && haskey(entry, "started_at") && haskey(entry, "finished_at")
        duration = maybe_duration_seconds(entry["started_at"], entry["finished_at"])
        !isnothing(duration) && (entry["duration_seconds"] = duration)
    end

    return entry
end

function timed_task_entries(entries)
    return [
        entry for entry in entries
        if haskey(entry, "duration_seconds")
    ]
end

function aggregate_duration!(aggregates, key, duration)
    group = string(key)
    aggregate = get!(aggregates, group) do
        Dict{String,Any}(
            "task_count" => 0,
            "total_duration_seconds" => 0.0,
            "max_duration_seconds" => 0.0,
        )
    end
    aggregate["task_count"] += 1
    aggregate["total_duration_seconds"] += duration
    aggregate["max_duration_seconds"] = max(aggregate["max_duration_seconds"], duration)
    return aggregate
end

function duration_groups(entries, source_key, output_key)
    aggregates = Dict{String,Any}()

    for entry in entries
        haskey(entry, source_key) || continue
        duration = Float64(entry["duration_seconds"])
        aggregate_duration!(aggregates, entry[source_key], duration)
    end

    return [
        merge(Dict{String,Any}(output_key => key), aggregate)
        for (key, aggregate) in sort(collect(aggregates); by=first)
    ]
end

function slowest_task_entries(entries; limit=10)
    sorted_entries = sort(entries; by=entry -> Float64(entry["duration_seconds"]), rev=true)

    return [
        Dict{String,Any}(
            key => entry[key]
            for key in ("task_id", "family", "code_instance", "decoder", "setup", "state", "duration_seconds")
            if haskey(entry, key)
        )
        for entry in sorted_entries[1:min(limit, length(sorted_entries))]
    ]
end

function timing_summary(entries)
    started_timestamps = [
        parse_run_summary_timestamp(entry["started_at"])
        for entry in entries
        if haskey(entry, "started_at") && !isnothing(maybe_parse_run_summary_timestamp(entry["started_at"]))
    ]
    finished_timestamps = [
        parse_run_summary_timestamp(entry["finished_at"])
        for entry in entries
        if haskey(entry, "finished_at") && !isnothing(maybe_parse_run_summary_timestamp(entry["finished_at"]))
    ]
    timed_entries = timed_task_entries(entries)

    summary = Dict{String,Any}(
        "total_task_duration_seconds" => sum(Float64(entry["duration_seconds"]) for entry in timed_entries; init=0.0),
        "slowest_tasks" => slowest_task_entries(timed_entries),
        "duration_by_family" => duration_groups(timed_entries, "family", "family"),
        "duration_by_code_instance" => duration_groups(timed_entries, "code_instance", "code_instance"),
        "duration_by_decoder" => duration_groups(timed_entries, "decoder", "decoder"),
        "duration_by_setup" => duration_groups(timed_entries, "setup", "setup"),
    )

    if !isempty(started_timestamps)
        run_started_at = minimum(started_timestamps)
        summary["run_started_at"] = Dates.format(run_started_at, RUN_SUMMARY_TIMESTAMP_FORMAT) * "Z"
    end

    if !isempty(finished_timestamps)
        run_finished_at = maximum(finished_timestamps)
        summary["run_finished_at"] = Dates.format(run_finished_at, RUN_SUMMARY_TIMESTAMP_FORMAT) * "Z"
    end

    if haskey(summary, "run_started_at") && haskey(summary, "run_finished_at")
        summary["run_wall_time_seconds"] = duration_seconds(summary["run_started_at"], summary["run_finished_at"])
    end

    return summary
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

    all_tasks = vcat(succeeded_tasks, failed_tasks, incomplete_tasks, missing_tasks)
    summary = Dict{String,Any}(
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

    merge!(summary, timing_summary(all_tasks))
    return summary
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

    if myid() != 1
        include(joinpath(pwd(), "wiki_database_passes.jl"))
    end

    const SLURM_DB_DIR = $MANIFEST_DB_DIR
    const SLURM_TASK_DETAIL_FIELDS = $TASK_DETAIL_FIELDS

    const SLURM_TIMESTAMP_FORMAT = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")

    timestamp_utc(t=Dates.now(Dates.UTC)) = Dates.format(t, SLURM_TIMESTAMP_FORMAT) * "Z"

    function slurm_timestamp(timestamp)
        return Dates.DateTime(chopsuffix(string(timestamp), "Z"), SLURM_TIMESTAMP_FORMAT)
    end

    function slurm_duration_seconds(started_at, finished_at)
        return Dates.value(slurm_timestamp(finished_at) - slurm_timestamp(started_at)) / 1000
    end

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

        for key in SLURM_TASK_DETAIL_FIELDS
            haskey(task_manifest, key) && (status[key] = task_manifest[key])
        end

        if !isnothing(finished_at)
            status["finished_at"] = finished_at
            status["duration_seconds"] = slurm_duration_seconds(started_at, finished_at)
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

    function task_label(task_manifest)
        parts = String[string(task_manifest["family"])]
        for key in SLURM_TASK_DETAIL_FIELDS
            haskey(task_manifest, key) && push!(parts, string(task_manifest[key]))
        end
        return join(parts, " / ")
    end

    function run_task_body(task_manifest)
        task_name = Symbol(task_manifest["family"])
        task = getproperty(CodeMetadata, task_name)
        code_instance_filter = haskey(task_manifest, "code_instance") ? [task_manifest["code_instance"]] : nothing
        decoder_filter = haskey(task_manifest, "decoder") ? [task_manifest["decoder"]] : nothing
        setup_filter = haskey(task_manifest, "setup") ? [task_manifest["setup"]] : nothing
        label = task_label(task_manifest)
        @info "Running task: $label on $(myid())"
        started_at = timestamp_utc()
        write_task_status(task_manifest; state="running", started_at=started_at)
        try
            run_evaluations(
                CodeMetadata.code_metadata;
                include=[task],
                code_instances=code_instance_filter,
                decoders=decoder_filter,
                setups=setup_filter,
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
        return "Result for $(label)"
    end

    function run_task(task_manifest)
        try
            return with_task_log(task_manifest) do
                result = run_task_body(task_manifest)
                task_result = Dict(
                    "task_id" => task_manifest["id"],
                    "family" => task_manifest["family"],
                    "state" => "succeeded",
                    "result" => result,
                )
                for key in SLURM_TASK_DETAIL_FIELDS
                    haskey(task_manifest, key) && (task_result[key] = task_manifest[key])
                end
                return task_result
            end
        catch err
            task_result = Dict(
                "task_id" => task_manifest["id"],
                "family" => task_manifest["family"],
                "state" => "failed",
                "exception_text" => sprint(showerror, err),
            )
            for key in SLURM_TASK_DETAIL_FIELDS
                haskey(task_manifest, key) && (task_result[key] = task_manifest[key])
            end
            return task_result
        end
    end
end

const HEAVY_WORKER_COUNT = 5

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
