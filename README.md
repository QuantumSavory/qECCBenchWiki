## To set up dependencies

```
julia> ] instantiate
```

## To evaluate codes and decoders and store raw data

If you want to make previously executed runs available in the local database run `git restore --source evaluation_results_branch codes/results.sqlite`. If you want to start from scratch, just disregard this command.

Add the codes and decoders of interest to `_0.helpers_and_metadata/code_metadata.jl` then

```
julia> include("wiki_database_passes.jl")
julia> run_evaluations(CodeMetadata.code_metadata)
```

If you want to run only some codes, e.g. the code family `CodeType`, you can use `run_evaluations(code_metadata; include=[CodeType])`.

If you want to run only some decoders or setups, use `decoders` or `setups` filters. Filters can use the exact metadata entries or their display names:

```julia
run_evaluations(code_metadata; include=[CodeType], decoders=[TableDecoder])
run_evaluations(code_metadata; include=[CodeType], decoders=["Table"], setups=["CommutationCheck"])
```

Optionally, if you want to specify a location (directory) for the generated database, you can use `run_evaluations(code_metadata; db_path="path/to/database")`.


## To merge evaluation results from multiple runs

If you have multiple evaluation runs that have generated separate databases, you can merge them into a single database using the `_0.helpers_and_metadata/db_join_helper.jl` script. 

```julia
include("_0.helpers_and_metadata/db_join_helper.jl")
using .DBJoinHelper: join_results
join_results("path/to/results"; output_path="path/to/merged_results.sqlite")
```
## To generate plots and markdown entries

```
julia> include("wiki_database_passes.jl")
julia> prep_everything(CodeMetadata.code_metadata)
```

## To generate the website for local viewing

Run the Franklin static website generator

```
julia> using Franklin
julia> Franklin.serve()
```

## Folder structure

This is a Franklin.jl static website, together with the following extra passes for generating the source of the static pages:

- `_0.helpers_and_metadata` - the base metadata about codes and decoders as well as some low-level helper functions for working with that metadata and the sqlite database of results
- `_1.code_benchmark_pass` - for running benchmarks and storing the performance data to the database
- `_2.markdown_generation_pass` - for reading the database and creating figures and raw markdown pages
- `wiki_database_passes.jl` - all of the functionality necessary for running the aforementioned capabilities
- `codes` - where the generated static website sources are kept
- `database` - where the database of benchmarks is stored (in `sqlite` as master format, and a few other formats for convenient downloading)

## ENV variables

- if `ENV["ECCBENCHWIKI_QUICKCHECK"]!=""` we will run very few samples per code, useful to check for overall correctness

## Slurm Clusters Guide
Running the benchmarks on a Slurm cluster can be more efficient if you want to parallelize the execution across multiple nodes. Here are some tips for setting up and running the benchmarks on a Slurm cluster:

### Setup
1. Set up Julia environment to evoid repeatedly setting up dependencies. You can do this by setting the `JULIA_DEPOT_PATH` environment variable to a directory on your HPC cluster where you want to store Julia packages. Optionally, set `JULIA_NUM_PRECOMPILE_TASKS` and `JULIA_PKG_PRECOMPILE_AUTO` to avoid precompilation overhead. Optionally, set `JULIA_CPU_TARGET` to a value that covers your target architecture. For example, you can add the following lines to your startup script:

    ```bash
    export JULIA_DEPOT_PATH="/path/to/your/julia/depot"
    export JULIA_NUM_PRECOMPILE_TASKS=1
    export JULIA_PKG_PRECOMPILE_AUTO=0
    export JULIA_CPU_TARGET="generic;skylake-avx512,clone_all;znver2,clone_all"
    ```

2. You might use `SlurmClusterManager.jl` to manage the execution of your benchmarks across the cluster. It's already included in the project dependencies.

3. You can set up project environment, instantiate, and precompile before running the benchmarks at a large scale. This avoids the overhead of setting up the environment and precompilation for each job submission. For example, you can submit the following script as a Slurm job:

    ```bash
    #!/bin/bash
    #SBATCH -J julia_warmup
    #SBATCH -N 1
    #SBATCH -n 1

    #SBATCH -t 01:30:00

    source /path/to/your/startup_script.sh
    cd /path/to/qECCBenchWiki

    julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
    ```

### Running Benchmarks
1. Run the Slurm entrypoint from the repository root. It writes a run manifest under `runs/slurm/<run_id>/`, assigns one manifest-owned database filename per task, and passes those filenames into `run_evaluations`.

    ```bash
    sbatch -N 4 -n 12 -t 01:00:00 --mem-per-cpu=8g script/slurm/slurm.jl
    ```

    After all task phases finish, inspect `runs/slurm/<run_id>/summary.toml` for the run-level succeeded, failed, incomplete, and missing-status task lists.

    For custom scripts, pass an explicit database directory and filename when you want a run to write to a specific SQLite file:

    ```julia
    run_evaluations(CodeMetadata.code_metadata; db_path="path/to/results", db_filename="db_task.sqlite")
    ```
2. To merge one Slurm run's per-task databases into a single run-level database, pass the run directory to the Slurm results script:

    ```bash
    julia --project=. script/slurm/get_results.jl runs/slurm/<run_id>
    ```

    This reads `runs/slurm/<run_id>/db/*.sqlite` and writes `runs/slurm/<run_id>/results.sqlite`.
