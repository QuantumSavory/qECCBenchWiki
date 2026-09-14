using Dates
using Glob
using Mustache
using Markdown

include("_0.helpers_and_metadata/helpers.jl")
include("_0.helpers_and_metadata/code_metadata.jl")

using .Helpers: typenameof, skipredundantfix

tag_label(tag) = CodeMetadata.code_tag_labels[tag]

function hfun_allcodes()
    io = IOBuffer()
    code_items = sort(collect(pairs(CodeMetadata.code_metadata)); by=item -> string(typenameof(item[1])))
    used_tags = unique(vcat([metadata[:tags] for (_, metadata) in code_items]...))
    tag_filters = [
        (; tag=String(tag), label=tag_label(tag))
        for tag in sort(used_tags; by=tag -> lowercase(tag_label(tag)))
    ]

    write(io, render(mt"""
    <div class="code-filter-panel">
      <label class="code-search-label" for="code-search">Search code families</label>
      <input id="code-search" class="form-control code-search-input" type="search" placeholder="Search by name, tag, decoder, or description">
      <div class="code-filter-tags" aria-label="Code category filters">
      {{#:tag_filters}}
        <label class="code-filter-option">
          <input type="checkbox" value="{{:tag}}">
          <span>{{:label}}</span>
        </label>
      {{/:tag_filters}}
      </div>
      <div id="code-filter-count" class="code-filter-summary" aria-live="polite"></div>
    </div>
    """, (; tag_filters)))

    for (codetype, metadata) in code_items
        codetypename = typenameof(codetype)
        decoders = unique(skipredundantfix.(typenameof.(metadata[:decoders])))
        setups = skipredundantfix.(typenameof.(metadata[:setups]))
        tags = [(; tag=String(tag), label=tag_label(tag)) for tag in metadata[:tags]]
        tag_data = join(String.(metadata[:tags]), " ")
        description = Markdown.html(Markdown.parse(get(metadata, :description, "")))
        search_text = lowercase(join([
            string(codetypename),
            join(tag_label.(metadata[:tags]), " "),
            join(decoders, " "),
            join(setups, " "),
            get(metadata, :description, ""),
        ], " "))
        write(io, render(mt"""
        <div class="card code-card" data-tags="{{:tag_data}}" data-search="{{:search_text}}">
          <h5 class="card-header"><a href="../codes/{{{:codetypename}}}">{{:codetypename}}</a></h5>
          <div class="card-body">
            <div class="code-card-tags">
            {{#:tags}} <span class="badge badge-primary">{{:label}}</span> {{/:tags}}
            </div>
            <p class="card-text">{{{:description}}}</p>
          </div>
          <div class="card-footer text-muted">
          {{#:decoders}} <span class="badge badge-dark">{{.}}</span> {{/:decoders}}
          <br>
          {{#:setups}} <span class="badge badge-light">{{.}}</span> {{/:setups}}
          </div>
        </div>
        """, (;codetypename, decoders, setups, tags, tag_data, search_text, description)))
        write(io, "\n")
    end
    write(io, """
    <script>
    (function () {
      var search = document.getElementById("code-search");
      var checkboxes = Array.prototype.slice.call(document.querySelectorAll(".code-filter-option input"));
      var cards = Array.prototype.slice.call(document.querySelectorAll(".code-card"));
      var count = document.getElementById("code-filter-count");

      function applyFilters() {
        var query = (search.value || "").trim().toLowerCase();
        var selectedTags = checkboxes.filter(function (input) {
          return input.checked;
        }).map(function (input) {
          return input.value;
        });
        var visible = 0;

        cards.forEach(function (card) {
          var text = card.getAttribute("data-search") || "";
          var tags = (card.getAttribute("data-tags") || "").split(/\\s+/);
          var matchesText = query === "" || text.indexOf(query) !== -1;
          // Selecting more than one category narrows the list to codes with every tag.
          var matchesTags = selectedTags.every(function (tag) {
            return tags.indexOf(tag) !== -1;
          });
          var matches = matchesText && matchesTags;
          card.style.display = matches ? "" : "none";
          if (matches) visible += 1;
        });

        count.textContent = visible + " of " + cards.length + " code families shown";
      }

      search.addEventListener("input", applyFilters);
      checkboxes.forEach(function (input) {
        input.addEventListener("change", applyFilters);
      });
      applyFilters();
    }());
    </script>
    """)
    return String(take!(io))
end
