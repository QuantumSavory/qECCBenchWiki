function make_markdown_page(codetype, metadata)
    codetypename = typenameof(codetype)
    family_strs = ["($(join(string.(s),", ")))" for s in metadata[:family]] # otherwise there is an annoying trailing comma
    rendered = render_from_file("code_template.md", (;codetypename, metadata..., family_strs))
    write("codes/$codetype/index.md", rendered)
end
