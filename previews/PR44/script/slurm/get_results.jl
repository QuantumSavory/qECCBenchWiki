#! /usr/bin/env julia

using Pkg

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

Pkg.activate(REPO_ROOT)

include(joinpath(REPO_ROOT, "_0.helpers_and_metadata/db_join_helper.jl"))

using .DBJoinHelper: join_results

function usage()
    script = basename(PROGRAM_FILE)
    return "Usage: julia --project=. script/slurm/$(script) <run_dir>"
end

function sqlite_files(dir)
    return filter(f -> isfile(f) && endswith(lowercase(f), ".sqlite"), readdir(dir; join=true))
end

function main(args)
    if length(args) != 1
        error(usage())
    end

    run_dir = abspath(only(args))
    db_dir = joinpath(run_dir, "db")
    output_path = joinpath(run_dir, "results.sqlite")

    isdir(run_dir) || error("Slurm run directory does not exist: $(run_dir)")
    isdir(db_dir) || error("Slurm run database directory does not exist: $(db_dir)")
    isempty(sqlite_files(db_dir)) && error("No .sqlite files found in Slurm run database directory: $(db_dir)")

    result_path = join_results(db_dir; output_path=output_path)
    println("Wrote merged Slurm results to $(result_path)")
end

main(ARGS)
