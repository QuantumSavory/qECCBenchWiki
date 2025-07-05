using Dates
using Glob
using Mustache
using Markdown

include("_0.helpers_and_metadata/helpers.jl")
include("_0.helpers_and_metadata/code_metadata.jl")

using .Helpers: typenameof, skipredundantfix

function hfun_allcodes()
    io = IOBuffer()
    for (codetype, metadata) in pairs(CodeMetadata.code_metadata)
        codetypename = typenameof(codetype)
        decoders = unique(skipredundantfix.(typenameof.(metadata[:decoders])))
        setups = skipredundantfix.(typenameof.(metadata[:setups]))
        description = Markdown.html(Markdown.parse(get(metadata, :description, "")))
        write(io, render(mt"""
        <div class="card">
          <h5 class="card-header"><a href="../codes/{{{:codetypename}}}">{{:codetypename}}</a></h5>
          <div class="card-body">
            <p class="card-text">{{{:description}}}</p>
          </div>
          <div class="card-footer text-muted">
          {{#:decoders}} <span class="badge badge-dark">{{.}}</span> {{/:decoders}}
          <br>
          {{#:setups}} <span class="badge badge-light">{{.}}</span> {{/:setups}}
          </div>
        </div>
        <br>
        """, (;codetypename, decoders, setups, description)))
        write(io, "\n")
    end
    return String(take!(io))
end
