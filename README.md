## To evaluate codes and decoders and store raw data

1. Add the codes and decoders of interest to `code_metadata.jl`
2. Activate this julia project and include `codes/generate_codes.jl`, e.g. with `julia --project=. -tauto -i ./codes/code_evaluation.jl` from this folder and then run `run_evaluations(code_metadata)`

## To generate plots and markdown entries

1. Activate this julia project and include `codes/generate_codes.jl`, e.g. with `julia --project=. -tauto -i ./codes/code_evaluation.jl` from this folder and then run `prep_everything(code_metada)`

## To generate the website for local viewing

1. Run the Franklin static website generator, e.g. `julia --project=. -tauto -i -e "using Franklin; Franklin.serve()"`