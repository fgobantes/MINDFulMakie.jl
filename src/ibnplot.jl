"Check if `x` is a vector of vectors of `Integer`"
isvvi(x::Vector{Vector{T}}) where T = all(i -> i isa Integer, Iterators.flatten(x))
isvvi(j) = false
"Check if `x` is a vector of vectors of `AbstractSimpleEdge`"
isvve(x::Vector{Vector{T}}) where T<:Graphs.SimpleGraphs.AbstractSimpleEdge = length(x) > 0
isvve(j) = false

"Get type by stripping outer vector"
deduceOuterVector(x::Vector{T}) where T = T

"""
$(TYPEDSIGNATURES)
Return a network layout for coordinates if each node in `gr` has coordinate data `xcoord` and `ycoord`.
If no return a `NetworkLayout.spring` layout
"""
function coordlayout(gr::AbstractGraph, xcoord::Symbol=:xcoord, ycoord::Symbol=:ycoord)
    try 
        xs = [[get_prop(gr, v, xcoord), get_prop(gr,v, ycoord)] for v in vertices(gr)]
        return [Point(x...) for x in xs ]
    catch e
        return NetworkLayout.spring(gr)
    end
end

"""
    intentplot(ibn::IBN)
    intentplot!(ax, ibn::IBN)

Creates a graph plot of the `ibn`.

## Attributes
- `show_routers = false`: show labels for nodes
- `show_links = false`: show labels for links.
- `subnetwork_view = false`: show node labels with the controller view indexing.
- `color_paths = nothing`: color given paths. 
You must pass in `Vector{Vector{Integer}}` where each nested `Vector` is a path.
Each path is being colored with a distinct color.
- `color_edges = nothing`: color given edges. 
Pass in `Vector{Vector{Edge}}`. 
Each nested Vector{Edge} gets a distinct color.
- `pure_colors = nothing`: enter a `Vector` of colors to use for edges/paths.
- `circle_nodes = nothing`: choose which nodes to circle. 
Pass in Vector{Vector{Int}}.
Each nested Vector{Int} gets the same color.
- `intentidx = nothing`: highligh the passed in intent.
"""
@recipe(IBNPlot, ibn) do scene
    Attributes(
        show_routers = false,
        show_links = false,
        subnetwork_view = false,
        color_paths = nothing,
        color_edges = nothing,
        pure_colors = nothing,
        circle_nodes = nothing,
        intentidx = nothing
    )
end

function nodelabel(ngr::NestedGraph, v::Integer, show_router=false, subnetwork_view=false) 
    nodelabs = subnetwork_view ? string(ngr.vmap[v]) : string(v)
    noderouter = string()
    if show_router
        if has_prop(ngr, v, :router)
            noderouter = string(sum(get_prop(ngr, v, :router).portavailability), "/",length(get_prop(ngr, v, :router).portavailability))
        else
            noderouter = "?"
        end
    end
    isempty(noderouter) ? nodelabs : nodelabs * "," * noderouter
end

function edgelabel(ngr::NestedGraph, e::Edge, show_links=false)
    edgelabs = show_links ? let
        fv = get_prop(ngr, e, :link)
        @assert fv.spectrum_src == fv.spectrum_dst
        availslots = fv.spectrum_src
        string(sum(availslots),"/",length(availslots))
    end : string()
end

function Makie.plot!(ibnp::IBNPlot)
    ibn = ibnp[:ibn]
    nodelabels = @lift [nodelabel(ibn[].ngr, v, $(ibnp.show_routers), $(ibnp.subnetwork_view)) for v in vertices(ibn[].ngr)]
    edgelabels = @lift [edgelabel(ibn[].ngr, e, $(ibnp.show_links)) for e in edges(ibn[].ngr)]
        
    NestedGraphMakie.ngraphplot!(ibnp, ibnp[:ibn][].ngr; ibnp.attributes..., nlabels=nodelabels, elabels=edgelabels, layout=coordlayout)


    # first plots[1] is NestedGraphMakie and second plots[1] is GraphMakie
    gmp = ibnp.plots[1].plots[1]
    edps = gmp.edge_paths
    # scatter plot
    scp = ibnp.plots[1].plots[1].plots[2]
    
    colorp_scattern = @lift begin
        clps = Vector{Vector{GraphMakie.AbstractPath{Point{2, Float32}}}}()
        scnds = Vector{Vector{Int}}()

        if $(ibnp.color_paths) !== nothing
            push!(clps, fillcolorpaths($(ibnp.color_paths), ibn[].ngr, $(edps))...)
        end
        if $(ibnp.color_edges) !== nothing
            push!(clps, fillcolorpaths($(ibnp.color_edges), ibn[].ngr, $(edps))...)
        end
        if $(ibnp.intentidx) !== nothing && length($(ibnp.intentidx)) > 0
            cps,snds = fillcolorpaths($(ibnp.intentidx), ibn[], $(edps))
            push!(clps, cps...)
            push!(scnds, snds...)
        end
        if $(ibnp.circle_nodes) !== nothing
            push!(scnds, $(ibnp.circle_nodes)...)
        end
        return clps, scnds
    end
    colorpaths = @lift $(colorp_scattern)[1]
    scatternodes = @lift $(colorp_scattern)[2]

    ibnp[:flat_paths] = @lift begin
        reduce(vcat, $(colorpaths); init=deduceOuterVector($(colorpaths))())
    end
    flat_paths = ibnp[:flat_paths]

    ibnp[:flat_colors] = @lift begin
        if $(ibnp.pure_colors) === nothing
            dcs = distinguishable_colors(length($colorpaths) + 3, [RGB(1,1,1), RGB(0,0,0)])[3:end]
            vvcol = [fill((dcs[i], 0.5), length(colorpath)) for (i,colorpath) in enumerate($colorpaths)]
        else
            vvcol = [fill(pc, length(cp)) for (pc,cp) in zip($(ibnp.pure_colors),($colorpaths))]
        end
        temp = reduce(vcat, vvcol; init=deduceOuterVector(vvcol)())
    end
    flat_colors = ibnp[:flat_colors]
    
    lwd2 = @lift $(gmp.edge_width)*5

    if length(flat_paths[]) > 0
        GraphMakie.edgeplot!(ibnp, flat_paths; color=flat_colors, linewidth=lwd2)
    end

    ibnp[:flat_scatternodes] = @lift begin
        flat_nodes = reduce(vcat, $(scatternodes); init=deduceOuterVector($(scatternodes))())
        $(gmp.node_pos)[flat_nodes]
    end
    flat_scatternodes = ibnp[:flat_scatternodes]
    
    flat_markersize = @lift begin
        circleradius = Vector{Int}()
        startcircleradius = maximum(values($(scp.markersize))) * 2
        for sn in $(scatternodes)
            push!(circleradius, fill(startcircleradius, length(sn))...)
            startcircleradius += 8
        end
        return circleradius
    end
    
    # TODO code repeat
    flat_scattercolor = @lift begin
        if $(ibnp.pure_colors) === nothing
            dcs = distinguishable_colors(length($scatternodes) + 3, [RGB(1,1,1), RGB(0,0,0)])[3:end]
            vvcol = [fill(dcs[i], length(scnds)) for (i,scnds) in enumerate($scatternodes)]
        else
            vvcol = [fill(pc, length(sn)) for (pc,sn) in zip($(ibnp.pure_colors),($scatternodes))]
        end
        reduce(vcat, vvcol; init=deduceOuterVector(vvcol)())
    end
    
    scatter!(ibnp, flat_scatternodes, markersize=flat_markersize, 
        strokecolor=flat_scattercolor, strokewidth=2, color=(:black, 0.0))

    return ibnp
end

function Makie.plot!(ibnp::IBNPlot{<:Tuple{Vector{IBN{R}}}}) where {R}
    distcolors = distinguishable_colors(length(ibnp[1][]))
    typetupl = (first(distcolors), 0.5) |> typeof
    firstibn = ibnp[1][][1]

    # should be a vector of indices
    if ibnp.intentidx[] === nothing
        numintent = Int[]
    else
        numintent = ibnp.intentidx[]
    end

    intcols = distinguishable_colors(length(numintent) + 3, [RGB(1,1,1), RGB(0,0,0)])[3:end]
    remintentidxs = [getremoteintentsid(firstibn, numint) for numint in numintent]
    [push!(rii, (1, numint)) for (rii, numint) in zip(remintentidxs, numintent)]

    for (i,ibn) in enumerate(ibnp[1][])
        intentidxs = [getindex.(filter(x -> x[1] == i, rii), 2) for rii in remintentidxs]
        purecols = reduce(vcat, [fill((col, 0.5), length(inidxs)) for (col,inidxs) in zip(intcols, intentidxs)], 
            init=Vector{typetupl}())
        flatints = reduce(vcat, intentidxs, init=Int[])

        ibnplot!(ibnp, ibn; ibnp.attributes..., 
                 node_color=distcolors[i], 
                 nlabels_textsize=Dict(v => 0 for v in bordernodes(ibn, subnetwork_view=false)),
                 node_size=Dict(v => 0 for v in bordernodes(ibn, subnetwork_view=false)),
                 intentidx=flatints,
                 pure_colors=purecols)
    end
    return ibnp
end

function fillcolorpaths(paths::Vector{Vector{T}}, ngr, edps) where T<:Integer
    fillcolorpaths(edgeify.(paths), ngr, edps)
end

function fillcolorpaths(nedges::Vector{E}, ngr, edps) where E#where E#<:AbstractEdge
    [let
        idxs = find_edge_index.([ngr], nedgs)
        edps[broadcast(in, 1:end, [idxs])]
    end for nedgs in nedges
    ]
end

function fillcolorpaths(intentidxs::Vector{T}, ibn::IBN, edps) where T<:Integer
    scatternodes = Vector{Vector{Int}}()
    nedges = [
        let 
            nodespectrumintents = getlogicspecturmintents!(scatternodes, ibn, intentidx)
            nedgs = getfield.(nodespectrumintents, :edge)
            [localedge(ibn, cedg; subnetwork_view=false) for cedg in nedgs]
        end for intentidx in intentidxs
    ]
    colorpaths = fillcolorpaths(nedges, ibn.ngr, edps)
    return colorpaths, scatternodes
end

function getlogicspecturmintents!(scatternodes, ibn::IBN, intentidx::T) where T<:Integer
    glbns, _ = logicalorderedintents(ibn, getintent(ibn, intentidx), getintent(ibn, intentidx) |> getuserintent, true)
    llis = [glbn.lli for glbn in glbns if glbn.ibn.id == ibn.id]
    noderouterintents = filter(x -> x isa NodeRouterIntent, llis)
    noderouternodes = getfield.(noderouterintents, :node)
    localnoderouterintents = [localnode(ibn, nri; subnetwork_view=false) for nri in noderouternodes]
    push!(scatternodes, localnoderouterintents)
    return filter(x -> x isa NodeSpectrumIntent, llis)
end

find_edge_index(gr::AbstractGraph, e::Edge) = findfirst(==(e), collect(edges(gr)))

"""
Create legend with (e.g.)
```
Legend(f[1,1], MINDFul.getlegendplots(p), ["Intent5","Intent3"], tellheight=false, tellwidth=false, halign=:right)
```
"""
getlegendplots(ibnp::IBNPlot) = return ibnp.plots[2:end]
