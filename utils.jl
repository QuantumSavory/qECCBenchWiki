using Dates
using Glob
using Mustache
using Markdown
using QuantumClifford
using QuantumClifford.ECC

include("code_metadata.jl")

#typename(t) = string(t.name.name)

function hfun_allcodes()
    io = IOBuffer()
    for (codetype, metadata) in pairs(code_metadata)
        codetype = nameof(codetype)
        decoders = nameof.(metadata[:decoders])
        setups = nameof.(metadata[:setups])
        description = Markdown.html(Markdown.parse(get(metadata, :description, "")))
        write(io, render(mt"""
        <div class="card">
          <h5 class="card-header"><a href="../codes/{{{:codetype}}}">{{:codetype}}</a></h5>
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
        """, (;codetype, decoders, setups, description)))
        write(io, "\n")
    end
    return String(take!(io))
end
