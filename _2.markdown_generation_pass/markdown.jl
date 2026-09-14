module CodeMarkdown

using ..Helpers: typenameof
using ..CodeMetadata: code_tag_labels
using Mustache

function make_markdown_page(codetypename, metadata)
    family_strs = ["($(join(string.(s),", ")))" for s in metadata[:family]] # otherwise there is an annoying trailing comma
    tag_names = join((code_tag_labels[tag] for tag in metadata[:tags]), ", ")
    @debug family_strs
    rendered = render_from_file(joinpath((@__DIR__), "code_template.md"), (;codetypename, metadata..., family_strs, tag_names))
    write(joinpath((@__DIR__), "../codes/$codetypename/index.md"), rendered)
end

function prep_markdown(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        @info "Generating markdown for $(codetypename) ..."
        make_markdown_page(codetypename, metadata)
    end
end

end
