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
    include(joinpath(pwd(), "wiki_database_passes.jl"))

    const SLURM_DB_DIR = $MANIFEST_DB_DIR

    function run_task(task_manifest)
        task_name = Symbol(task_manifest["family"])
        task = getproperty(CodeMetadata, task_name)
        @info "Running task: $task_name on $(myid())"
        run_evaluations(
            CodeMetadata.code_metadata;
            include=[task],
            db_path=SLURM_DB_DIR,
            db_filename=task_manifest["db_filename"],
        )
        return "Result for $(task_name)"
    end
end

light_results = pmap(run_task, LIGHT_MANIFEST_TASKS)

const HEAVY_WORKER_COUNT = 1
heavy_pool = WorkerPool(workers()[1:min(HEAVY_WORKER_COUNT, nworkers())])
heavy_results = pmap(run_task, heavy_pool, HEAVY_MANIFEST_TASKS)

results = vcat(light_results, heavy_results)
