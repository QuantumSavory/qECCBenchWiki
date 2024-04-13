using Dates
using Glob
using Mustache
using Markdown
using QuantumClifford
using QuantumClifford.ECC

include("code_metadata.jl")

function hfun_allcodes()
    io = IOBuffer()
    for (codetype, metadata) in pairs(code_metadata)
        codetypename = typenameof(codetype)
        decoders = unique(skipredundantsuffix.(typenameof.(metadata[:decoders])))
        setups = skipredundantsuffix.(typenameof.(metadata[:setups]))
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
