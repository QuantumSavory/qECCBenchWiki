#!/usr/bin/env julia

# Minimal Slurm manifest-check entrypoint.
#
# This script keeps the same light/heavy task split as the working prototype,
# but only writes a run manifest. It does not start Slurm workers or run
# benchmarks yet.

include(joinpath(@__DIR__, "slurm_manifest_generator.jl"))

using .SlurmManifestGenerator: ManifestConfig, build_manifest, write_manifest_file

const RUN_ROOT = "runs/slurm"
const RUN_ID = "" # Empty means use a timestamp-based run id.
const ERROR_CHUNK_SIZE = 5
const ALLOW_OVERWRITE = false

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

function main()
    repo_root = abspath(joinpath(@__DIR__, ".."))
    project = SlurmManifestGenerator.load_project_metadata(repo_root)

    config = ManifestConfig(
        run_root=RUN_ROOT,
        run_id=isempty(RUN_ID) ? nothing : RUN_ID,
        include_families=vcat(LIGHT_TASKS, HEAVY_TASKS),
        heavy_families=copy(HEAVY_TASKS),
        error_chunk_size=ERROR_CHUNK_SIZE,
        allow_overwrite=ALLOW_OVERWRITE,
    )

    manifest = build_manifest(
        project.code_metadata,
        config;
        repo_root,
        family_name_fn=project.family_name_fn,
        object_name_fn=project.object_name_fn,
    )
    manifest_path = write_manifest_file(manifest; allow_overwrite=config.allow_overwrite)

    println("Wrote Slurm run manifest: $manifest_path")
    println("Planned tasks: $(length(manifest["tasks"]))")
    return manifest_path
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
