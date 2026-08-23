module CodeMarkdown

using ..Helpers: instancenameof, typenameof
using Mustache

const ARTIFACT_DOWNLOAD_SPECS = (
    (filename="parity_matrix.mtx", label="Full parity matrix (.mtx)", description="Matrix Market sparse matrix with (X|Z) columns."),
    (filename="parity_matrix_x.mtx", label="X parity matrix (.mtx)", description="CSS X-check matrix."),
    (filename="parity_matrix_z.mtx", label="Z parity matrix (.mtx)", description="CSS Z-check matrix."),
    (filename="matrices.mat", label="MAT bundle (.mat)", description="MATLAB and Julia sparse bundle."),
    (filename="parity_checks.txt", label="Stabilizer generators (.txt)", description="Human-readable parity checks."),
    (filename="manifest.toml", label="Artifact manifest (.toml)", description="File metadata and matrix dimensions."),
)

function circuit_plot_exists(codetypename, instance_name, suffix)
    path = joinpath(@__DIR__, "../codes", string(codetypename), "$(instance_name)_$(suffix).png")
    return isfile(path)
end

function url_path_segment(segment)
    encoded = IOBuffer()

    for byte in codeunits(string(segment))
        if (0x30 <= byte <= 0x39) ||
           (0x41 <= byte <= 0x5a) ||
           (0x61 <= byte <= 0x7a) ||
           byte in UInt8.(['-', '.', '_', '~'])
            write(encoded, byte)
        else
            print(encoded, "%", uppercase(string(byte; base=16, pad=2)))
        end
    end

    return String(take!(encoded))
end

function artifact_downloads(codetypename, instance_name)
    dir = joinpath(@__DIR__, "../codes", string(codetypename), "artifacts", instance_name)
    base_href = "./artifacts/$(url_path_segment(instance_name))"
    downloads = []

    for spec in ARTIFACT_DOWNLOAD_SPECS
        isfile(joinpath(dir, spec.filename)) || continue
        push!(downloads, (; spec..., href="$(base_href)/$(spec.filename)"))
    end

    return downloads
end

function make_markdown_page(codetype, codetypename, metadata)
    family_entries = map(metadata[:family]) do instance_args
        code = codetype(instance_args...)
        instance_name = instancenameof(code)
        family_str = "($(join(string.(instance_args), ", ")))" # Avoid a trailing comma for one-argument constructors.
        downloads = artifact_downloads(codetypename, instance_name)

        return (;
            family_str,
            instance_name,
            artifact_downloads=downloads,
            has_artifacts=!isempty(downloads),
            has_encoding=circuit_plot_exists(codetypename, instance_name, "encoding"),
            has_naive_syndrome=circuit_plot_exists(codetypename, instance_name, "naive_syndrome"),
            has_shor_syndrome=circuit_plot_exists(codetypename, instance_name, "shor_syndrome"),
        )
    end

    @debug family_entries
    rendered = render_from_file(joinpath((@__DIR__), "code_template.md"), (;codetypename, metadata..., family_entries))
    write(joinpath((@__DIR__), "../codes/$codetypename/index.md"), rendered)
end

function prep_markdown(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        @info "Generating markdown for $(codetypename) ..."
        make_markdown_page(codetype, codetypename, metadata)
    end
end

end
