module CodeFigures

using Makie, CairoMakie
using Quantikz
using QuantumClifford: stab_to_gf2, stabilizerplot_axis
using QuantumClifford.ECC: TableDecoder, parity_checks, iscss, parity_matrix_z, parity_matrix_x, code_n, naive_encoding_circuit, naive_syndrome_circuit, shor_syndrome_circuit

using ..Helpers: logrange, instancenameof, skipredundantfix, typenameof, CircBuffer
using ..DBHelpers: dbrow, dbnarray, dbrow!

const CIRCUIT_QUBIT_LIMIT = 10
const SHOR_MAX_TABLE_CELLS = 2500

ispositivefinite(x) = x > 0 && isfinite(x)
skipzeronan(xs) = (x for x in xs if ispositivefinite(x))
plottable_log_rate(x) = ispositivefinite(x) ? x : NaN

function save_circuit_plot(make_circuit, path, code, circuit_name; max_table_cells=nothing)
    rm(path; force=true)

    try
        circuit = make_circuit()
        if !isnothing(max_table_cells)
            table_cells = length(circuit2table(circuit).table)
            if table_cells > max_table_cells
                @info "$(code) skipped $(circuit_name): diagram has $(table_cells) table cells (limit: $(max_table_cells))"
                return false
            end
        end

        savecircuit(circuit, path)
        return true
    catch err
        @warn "$(code) failed to plot $(circuit_name)" exception=(err, catch_backtrace())
        return false
    end
end

function prep_code_circuits(code, codetypename)
    instance_name = instancenameof(code)
    encoding_path = "codes/$(codetypename)/$(instance_name)_encoding.png"
    naive_syndrome_path = "codes/$(codetypename)/$(instance_name)_naive_syndrome.png"
    shor_syndrome_path = "codes/$(codetypename)/$(instance_name)_shor_syndrome.png"

    for path in (encoding_path, naive_syndrome_path, shor_syndrome_path)
        rm(path; force=true)
    end

    code_n(code) <= CIRCUIT_QUBIT_LIMIT || return (encoding=false, naive_syndrome=false, shor_syndrome=false)

    encoding = save_circuit_plot(
        () -> naive_encoding_circuit(code),
        encoding_path,
        code,
        "`naive_encoding_circuit`",
    )
    naive_syndrome = save_circuit_plot(
        () -> naive_syndrome_circuit(code)[1],
        naive_syndrome_path,
        code,
        "`naive_syndrome_circuit`",
    )
    shor_syndrome = save_circuit_plot(
        () -> begin
            shor_parts = shor_syndrome_circuit(code)
            vcat(shor_parts[1:2]...)
        end,
        shor_syndrome_path,
        code,
        "`shor_syndrome_circuit`";
        max_table_cells=SHOR_MAX_TABLE_CELLS,
    )

    return (; encoding, naive_syndrome, shor_syndrome)
end

function plottable_logical_max(x, z)
    xok = ispositivefinite(x)
    zok = ispositivefinite(z)
    xok && zok && return max(x, z)
    xok && return x
    zok && return z
    return NaN
end

function padded_loglimits(values; default=(1e-5, 1.0), lower=nothing, upper=nothing, pad_decades_fraction=0.08)
    vals = collect(skipzeronan(values))
    isempty(vals) && return default

    lo = Float64(minimum(vals))
    hi = Float64(maximum(vals))
    loglo = log10(lo)
    loghi = log10(hi)
    pad = loglo == loghi ? 0.5 : max((loghi - loglo) * pad_decades_fraction, 0.04)

    lo = 10.0^(loglo - pad)
    hi = 10.0^(loghi + pad)
    !isnothing(lower) && (lo = max(lo, lower))
    !isnothing(upper) && (hi = min(hi, upper))

    if lo >= hi
        center = (log10(lo) + log10(hi)) / 2
        lo = 10.0^(center - 0.5)
        hi = 10.0^(center + 0.5)
        !isnothing(lower) && (lo = max(lo, lower))
        !isnothing(upper) && (hi = min(hi, upper))
    end

    return lo, hi
end

function plotted_limit_values(phys_errors, results, single_error)
    physical_values = Float64[]
    logical_values = Float64[]

    if single_error
        for iᵉ in eachindex(phys_errors)
            ispositivefinite(phys_errors[iᵉ]) || continue
            for iᶜ in axes(results, 3), iᵈ in axes(results, 4), iˢ in axes(results, 5)
                logical_error = plottable_logical_max(results[iᵉ, 1, iᶜ, iᵈ, iˢ], results[iᵉ, 2, iᶜ, iᵈ, iˢ])
                ispositivefinite(logical_error) || continue
                push!(physical_values, phys_errors[iᵉ])
                push!(logical_values, logical_error)
            end
        end
    else
        for iᵉ in eachindex(phys_errors)
            ispositivefinite(phys_errors[iᵉ]) || continue
            for iˡ in axes(results, 2), iᶜ in axes(results, 3), iᵈ in axes(results, 4), iˢ in axes(results, 5)
                logical_error = results[iᵉ, iˡ, iᶜ, iᵈ, iˢ]
                ispositivefinite(logical_error) || continue
                push!(physical_values, phys_errors[iᵉ])
                push!(logical_values, logical_error)
            end
        end
    end

    return physical_values, logical_values
end

function dense_summary_layout(codelabels)
    isempty(codelabels) && return false

    label_lengths = length.(string.(codelabels))
    return length(codelabels) > 8 ||
        (length(codelabels) > 5 && maximum(label_lengths) > 30) ||
        sum(label_lengths) > 260
end

function summary_palette(ncolors)
    wong = Makie.wong_colors()
    ncolors <= length(wong) && return wong
    return Makie.categorical_colors(:tab20, ncolors)
end

legend_banks(nitems, max_banks) = max(1, min(max_banks, nitems))
dense_code_legend_banks(nitems) = legend_banks(ceil(Int, nitems / 3), 4)

function make_decoder_figure(phys_errors, results;
    title="",
    colors=nothing,
    linestyles=CircBuffer([:solid, :dash, :dot, :dashdot, :dashdotdot, Linestyle([0.5, 1.0, 1.5, 2.5])]),
    markers=CircBuffer(['●', '■', '▲', '▼', '◆', '★']),
    single_error=false,
    codelabels=[], decoderlabels=[], setuplabels=[],
)
    physical_values, logical_values = plotted_limit_values(phys_errors, results, single_error)
    positive_phys_errors = collect(skipzeronan(phys_errors))
    physical_default = isempty(positive_phys_errors) ? (1e-5, 1.0) : (minimum(positive_phys_errors), min(1.0, maximum(positive_phys_errors)))
    xlimits = padded_loglimits(physical_values; default=physical_default, lower=physical_default[1], upper=1.0)
    ylimits = padded_loglimits(logical_values; upper=1.0)

    fresults = plottable_log_rate.(results)
    combined_results = map(plottable_logical_max, results[:,1,:,:,:], results[:,2,:,:,:])

    dense_layout = dense_summary_layout(codelabels)
    f = Figure(size=dense_layout ? (1500,900) : (1000,600))
    a = Axis(dense_layout ? f[1,1:4] : f[1:7,1:6],
        xscale=log10, yscale=log10,
        limits=(xlimits[1], xlimits[2], ylimits[1], ylimits[2]),
        xlabel="physical error rate",
        ylabel="logical error rate",
        title=title,
        titlesize=26,
        xlabelsize=18,
        ylabelsize=18,
        xticklabelsize=13,
        yticklabelsize=13,
        xgridcolor=(:gray, 0.18),
        ygridcolor=(:gray, 0.18),
        xminorgridvisible=true,
        yminorgridvisible=true,
        xminorgridcolor=(:gray, 0.08),
        yminorgridcolor=(:gray, 0.08),
        topspinevisible=false,
        rightspinevisible=false,
        )

    singlecode = size(results,3) == 1
    ncolorseries = singlecode ? max(size(results,4), length(decoderlabels)) : max(size(results,3), length(codelabels))
    colors = isnothing(colors) ? CircBuffer(summary_palette(ncolorseries)) : colors
    plotcolor(iᶜ,iᵈ) = singlecode ? colors[iᵈ] : colors[iᶜ]
    decoderlegendcolor(iᵈ) = singlecode ? colors[iᵈ] : :gray
    markersize = dense_layout ? 7 : 9
    linewidth = dense_layout ? 2.1 : 2.6

    reflim = (max(xlimits[1], ylimits[1]), min(xlimits[2], ylimits[2]))
    reflim[1] < reflim[2] && lines!(a, collect(reflim), collect(reflim), color=(:black, 0.75), linewidth=1.5)
    for (iᶜ,iᵈ,iˢ) in Iterators.product(axes.((fresults,), (3,4,5))...)
        if single_error
            logical_error = combined_results[:,iᶜ,iᵈ,iˢ]
            scatter!(a, phys_errors, logical_error, marker=markers[iˢ], color=plotcolor(iᶜ,iᵈ), markersize=markersize)
            lines!(  a, phys_errors, logical_error, color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ], linewidth=linewidth)
        else
            scatter!(a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], marker=:+, color=plotcolor(iᶜ,iᵈ), markersize=markersize)
            scatter!(a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], marker=:x, color=plotcolor(iᶜ,iᵈ), markersize=markersize)
            lines!(  a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ], linewidth=linewidth)
            lines!(  a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ], linewidth=linewidth)
        end
    end
    ca = []
    for (iᶜ,label) in enumerate(codelabels)
        push!(ca, lines!(a, [NaN], [NaN], color=plotcolor(iᶜ,1), linewidth=linewidth, label=label))
    end
    la = []
    for (iᵈ,label) in enumerate(decoderlabels)
        push!(la, lines!(a, [NaN], [NaN], linestyle=linestyles[iᵈ], color=decoderlegendcolor(iᵈ), linewidth=linewidth, label=label))
    end
    ma = []
    markerlegendlabels = String[]
    markerlegendtitle = ""
    if single_error
        for (iˢ,label) in enumerate(setuplabels)
            push!(ma, scatter!(a, [NaN], [NaN], marker=markers[iˢ], color=:gray, label=label))
        end
        markerlegendlabels = string.(setuplabels)
        markerlegendtitle = "Circuit Type"
    else
        push!(ma, scatter!(a, [NaN], [NaN], marker=:+, color=:gray, label="X"))
        push!(ma, scatter!(a, [NaN], [NaN], marker=:x, color=:gray, label="Z"))
        markerlegendlabels = ["X", "Z"]
        markerlegendtitle = "Logical Error"
    end

    if dense_layout
        Legend(f[2,1:4], ca, codelabels, "Code", framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=dense_code_legend_banks(length(codelabels)), titlesize=24, labelsize=16)
        Legend(f[3,1:2], la, decoderlabels, "Decoder", framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=legend_banks(length(decoderlabels), 3), titlesize=24, labelsize=16)
        Legend(f[3,3:4], ma, markerlegendlabels, markerlegendtitle, framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=legend_banks(length(markerlegendlabels), 3), titlesize=24, labelsize=16)
        rowsize!(f.layout, 1, Relative(0.62))
        rowsize!(f.layout, 2, Auto())
        rowsize!(f.layout, 3, Auto())
        rowgap!(f.layout, 1, 16)
        rowgap!(f.layout, 2, 10)
        colgap!(f.layout, 24)
    else
        Legend(f[1:2,7], ca, codelabels, "Code", framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=2, titlesize=24, labelsize=18)
        Legend(f[3:6,7], la, decoderlabels, "Decoder", framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=1, titlesize=24, labelsize=18)
        Legend(f[7,7], ma, markerlegendlabels, markerlegendtitle, framevisible=false, halign=:left, titlehalign=:left, valign=:top, nbanks=2, titlesize=24, labelsize=18)
    end
    f
end

function prep_figures(code_metadata)
    #Threads.@threads :greedy for (codetype, metadata) in code_metadata
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        @info "Plotting figures for $(codetypename) ..."
        codes = [codetype(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        e = logrange(errrange...)
        r = dbnarray(codes, decoders, setups, e)

        single_error = length(decoders)>1 || decoders==[TableDecoder]

        # Plotting benchmarking summary fig
        f = make_decoder_figure(e, r;
            title="$(codetypename)",
            codelabels=instancenameof.(codes),
            decoderlabels=skipredundantfix.(decoders),
            setuplabels=skipredundantfix.(setups),
            single_error
        )
        save("codes/$(codetypename)/totalsummary.png", f)

        # Plotting code instances
        for c in codes
            # Plotting stabilizer
            f = Figure(size=(600,300))
            sf = f[1:2,1]
            _,ax,p = stabilizerplot_axis(sf, parity_checks(c))
            ax.title = "Parity Check Tableau\n(a.k.a. Stabilizer Generators)"
            cm = Makie.cgrad([:lightgray,:black], 2, categorical = true)
            hz, hx, tz, tx = if iscss(c) === true # now 'nothing' type will be recognized as non-css
                parity_matrix_z(c)[end:-1:1,:]', parity_matrix_x(c)[end:-1:1,:]', "Z parity checks", "X parity checks"
            else
                h = stab_to_gf2(parity_checks(c))
                h[:,end÷2+1:end][end:-1:1,:]', h[:,1:end÷2][end:-1:1,:]', "Z components", "X components"
            end
            axz = Axis(f[1,2], title=tz)
            hmz = Makie.heatmap!(
                axz,
                collect(hz);
                colorrange = (0, 1),
                colormap=cm
            )
            axx = Axis(f[2,2], title=tx)
            hmx = Makie.heatmap!(
                axx,
                collect(hx);
                colorrange = (0, 1),
                colormap=cm
            )
            linkxaxes!(axx, axz)
            for ax in (axx, axz)
                Makie.hidedecorations!(ax)
                Makie.hidespines!(ax)
                ax.aspect = Makie.DataAspect()
            end
            colsize!(f.layout, 1, Relative(0.6))
            colsize!(f.layout, 2, Aspect(1, 1))
            colgap!(f.layout, 1, Relative(0.15))
            save("codes/$(codetypename)/$(instancenameof(c)).png", f)
            # Plotting circuits
            prep_code_circuits(c, codetypename)
        end
    end
end

end
