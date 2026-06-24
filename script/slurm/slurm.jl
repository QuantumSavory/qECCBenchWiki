#! /usr/bin/env julia

# This is the working version of our script

# Run with a command like:
# sbatch -N 4 -n 12 -t 01:00:00 --mem-per-cpu=8g script/slurm/slurm.jl
# Should be run from repo root!

# Do instatiate in julia REPL
# ENV["ECCBENCHWIKI_QUICKCHECK"]="true"

using Pkg

Pkg.activate(pwd())

using Distributed
using SlurmClusterManager

addprocs(SlurmManager(), exeflags="--project=$(pwd())")

@info "nprocs=$(nprocs()) nworkers=$(nworkers()) workers=$(workers())"

@everywhere begin
    include(joinpath(pwd(), "wiki_database_passes.jl"))

    function run_task(task_name::Symbol)
        task = getproperty(CodeMetadata, task_name)
        @info "Running task: $task_name on $(myid())"
        run_evaluations(CodeMetadata.code_metadata; include=[task], db_path=joinpath(pwd(), "codes/slurm_task_06_24/"), worker_db=true)
        return "Result for $(task_name)"
    end
end

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

light_results = pmap(run_task, LIGHT_TASKS)

const HEAVY_WORKER_COUNT = 1
heavy_pool = WorkerPool(workers()[1:min(HEAVY_WORKER_COUNT, nworkers())])
heavy_results = pmap(run_task, heavy_pool, HEAVY_TASKS)

results = vcat(light_results, heavy_results)
