## To set up dependencies

```
julia> ] instantiate
```

## To evaluate codes and decoders and store raw data

Add the codes and decoders of interest to `_0.helpers_and_metadata/code_metadata.jl` then

```
julia> include("wiki_database_passes.jl")
julia> run_evaluations(CodeMetadata.code_metadata)
```

If you want to run only some codes, e.g. the code family `CodeType`, you can use `run_evaluations(code_metadata; include=[CodeType])`.

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
- `_1.code_benchmark_pass` - for running benchmarks and story the performance data to the database
- `_2.markdown_generation_pass` - for reading the database and creating figures and raw markdown pages
- `wiki_database_passes.jl` - all of the functionality necessary for running the aforementioned capabilities
- `codes` - where the generated static website sources are kept
- `database` - where the database of benchmarks is stored (in `sqlite` as master format, and a few other formats for convenient downloading)