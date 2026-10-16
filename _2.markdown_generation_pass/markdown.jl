module CodeMarkdown

using ..Helpers: instancenameof, typenameof
using Mustache

function circuit_plot_exists(codetypename, instance_name, suffix)
    path = joinpath(@__DIR__, "../codes", string(codetypename), "$(instance_name)_$(suffix).png")
    return isfile(path)
end

function make_markdown_page(codetype, codetypename, metadata)
    family_entries = map(metadata[:family]) do instance_args
        code = codetype(instance_args...)
        instance_name = instancenameof(code)
        family_str = "($(join(string.(instance_args), ", ")))" # Avoid a trailing comma for one-argument constructors.

        return (;
            family_str,
            instance_name,
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
