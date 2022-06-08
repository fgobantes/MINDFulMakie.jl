isvvi(x::Vector{Vector{T}}) where T = all(i -> i isa Integer, Iterators.flatten(x))
isvve(x::Vector{Vector{T}}) where T<:Graphs.SimpleGraphs.AbstractSimpleEdge = length(x) > 0
isvvi(j) = false
isvve(j) = false

struct DummyPlotIBN{R,T}
    cgr::CompositeGraph{R,T}
end

function coordlayout(gr::AbstractGraph, xcoord::Symbol=:xcoord, ycoord::Symbol=:ycoord)
    try 
        xs = [[get_prop(gr, v, xcoord), get_prop(gr,v, ycoord)] for v in vertices(gr)]
        return [Point(x...) for x in xs ]
    catch e
        return NetworkLayout.spring(gr)
    end
end

@recipe(IBNPlot, ibn) do scene
    Attributes(
        show_routers = false,
        show_links = false,
        subnetwork_view = false,
        color_paths_obs = nothing,
        color_paths = nothing,
        color_edges = nothing,
        circle_nodes = nothing,
        intentidx = nothing
    )
end

function nodelabel(cgr::CompositeGraph, v::Integer, show_router=false, subnetwork_view=false) 
    nodelabs = subnetwork_view ? string(cgr.vmap[v]) : string(v)
    noderouter = string()
    if show_router
        if has_prop(cgr, v, :router)
            noderouter = string(get_prop(cgr, v, :router).rezports, "/",get_prop(cgr, v, :router).nports)
        else
            noderouter = "?"
        end
    end
    isempty(noderouter) ? nodelabs : nodelabs * "," * noderouter
end

function edgelabel(cgr::CompositeGraph, e::Edge, show_links=false)
    edgelabs = show_links ? string(get_prop(cgr, e, :link).rezcapacity,"/",get_prop(cgr, e, :link).capacity) : string()
end

function Makie.plot!(ibnp::IBNPlot)
    ibn = ibnp[:ibn]
    nodelabels = @lift [nodelabel($(ibn).cgr, v, $(ibnp.show_routers), $(ibnp.subnetwork_view)) for v in vertices($(ibn).cgr)]
    edgelabels = @lift [edgelabel($(ibn).cgr, e, $(ibnp.show_links)) for e in edges($(ibn).cgr)]

    edgecolors = @lift begin
        if isvvi($(ibnp.color_paths_obs))
            distcolors = Colors.distinguishable_colors(length($(ibnp.color_paths_obs)) + 3, [Colors.RGB(1,1,1), Colors.RGB(0,0,0)])[2:end]
            edgcs = fill(distcolors[1], ne($(ibn).cgr))
            for (ie,e) in enumerate(edges($(ibn).cgr))
                for (ip,path) in enumerate($(ibnp.color_paths_obs))
                    if e in edgeify(path)
                        edgcs[ie] = distcolors[ip+1]
                    end
                end
            end
            return edgcs
        end
        return :black
    end
    CompositeGraphs.cgraphplot!(ibnp, ibnp[:ibn][].cgr; 
                                merge((nlabels=nodelabels, elabels=edgelabels, edge_color=edgecolors, layout=coordlayout),
                                      NamedTuple(Makie.attributes_from(CompositeGraphs.CGraphPlot, ibnp)), 
                                      NamedTuple(Makie.attributes_from(GraphMakie.GraphPlot, ibnp)))...)

    #TODO with observable
    gmp = ibnp.plots[1].plots[1]
    edps = gmp.edge_paths[]
    lwd = gmp.edge_width[]
    ns = gmp.node_size[]

    
    colorpaths = Vector{Vector}()
    scatternodes = Vector{Vector}()
    if isvvi(ibnp.color_paths[])
        for path in ibnp.color_paths[]
            idxs = find_edge_index.([ibn[].cgr], edgeify(path))
            push!(colorpaths, edps[broadcast(in, 1:end, [idxs])])
        end
    end
    if isvve(ibnp.color_edges[])
        for cedges in ibnp.color_edges[]
            idxs = find_edge_index.([ibn[].cgr],cedges)
            push!(colorpaths, edps[broadcast(in, 1:end, [idxs])])
        end
    end
    if isvvi(ibnp.circle_nodes[])
        for cinods in ibnp.circle_nodes[]
            push!(scatternodes, cinods)
        end
    end
    if ibnp.intentidx[] != nothing
        glbns, _ = logicalorderedintents(ibn[], ibn[].intents[ibnp.intentidx[]], ibn[].intents[ibnp.intentidx[]] |> getroot)
        llis = [glbn.lli for glbn in glbns if glbn.ibn.id == ibn[].id]

        noderouterintents = filter(x -> x isa NodeRouterIntent, llis)
        noderouternodes = getfield.(noderouterintents, :node)
        localnoderouterintents = [localnode(ibn[], nri; subnetwork_view=false) for nri in noderouternodes]
        push!(scatternodes, localnoderouterintents)
        nodespectrumintents = filter(x -> x isa NodeSpectrumIntent, llis)
        cedges = getfield.(nodespectrumintents, :edge)
        edgs = [localedge(ibn[], cedg; subnetwork_view=false) for cedg in cedges]
        idxs = find_edge_index.([ibn[].cgr],edgs)
        push!(colorpaths, edps[broadcast(in, 1:end, [idxs])])
    end

    for (i,colorpath) in enumerate(colorpaths)
        distcolors = Colors.distinguishable_colors(length(colorpaths) + 3, [Colors.RGB(1,1,1), Colors.RGB(0,0,0)])[3:end]
        GraphMakie.edgeplot!(ibnp, colorpath, linewidth=lwd[]*5 ,color=(distcolors[i],0.3))
    end
    startcircleradius = gmp.node_size[] * 2
    for (i,scattnod) in enumerate(scatternodes)
        distcolors = Colors.distinguishable_colors(length(scatternodes) + 3, [Colors.RGB(1,1,1), Colors.RGB(0,0,0)])[3:end]
        lencinods = length(scattnod)
        ran = range(startcircleradius; step=8, length=lencinods)
        scatter!(ibnp, gmp.node_pos[][scattnod], markersize=ran,
                 strokecolor=distcolors[i], strokewidth=2, color=(:black, 0.0))
        startcircleradius = last(ran) + 8
    end


    return ibnp
end

function Makie.plot!(ibnp::IBNPlot{<:Tuple{Vector{IBN{R}}}}) where {R}
    distcolors = Colors.distinguishable_colors(length(ibnp[1][]))

    numintent = ibnp.intentidx[]

    if ibnp.intentidx[] != nothing
        glbns, _ = IBNFramework.logicalorderedintents(ibnp[1][][1], ibnp[1][][1].intents[numintent]
                                                     , getroot(ibnp[1][][1].intents[numintent])) 
    end

    for (i,ibn) in enumerate(ibnp[1][])
        if ibnp.intentidx[] != nothing
            ibnglbn = [glbn for glbn in glbns if glbn.ibn.id == ibn.id]

            llis = getfield.(ibnglbn, :lli)
            noderouterintents = filter(x -> x isa NodeRouterIntent, llis)
            noderouternodes = getfield.(noderouterintents, :node)
            localnoderouterintents = [localnode(ibn, nri; subnetwork_view=false) for nri in noderouternodes]
            #localnoderouterintents
            nodespectrumintents = filter(x -> x isa NodeSpectrumIntent, llis)
            cedges = getfield.(nodespectrumintents, :edge)
            edgs = [localedge(ibn, cedg; subnetwork_view=false) for cedg in cedges]
            unique!(edgs)
            ibnplot!(ibnp, ibn; ibnp.attributes..., 
                     color_edges=[edgs],
                     circle_nodes = [localnoderouterintents],
                     node_color=distcolors[i], 
                     node_invis=transnodes(ibn, subnetwork_view=false), 
                     intentidx=nothing)
        else
            ibnplot!(ibnp, ibn; ibnp.attributes..., node_color=distcolors[i], node_invis=transnodes(ibn, subnetwork_view=false))
        end
    end
    return ibnp
end

getlegendplots(ibnp::IBNPlot) = return ibnp.plots[2:end]

"Plots the `idx`st intent of `ibn`"
@recipe(IntentPlot, ibn, idx) do scene
    Attributes(
               interdomain = false,
               show_state = true,
    )
end

function Makie.plot!(intplot::IntentPlot)
    ibn = intplot[:ibn]
    idx = intplot[:idx]

    dag = ibn[].intents[idx[]]
    if intplot.show_state[] == false
        labs = [dagtext(dag[MGN.label_for(dag,v)].intent) for v in  vertices(dag)]
    else 
        labs = [let dagnode=dag[MGN.label_for(dag,v)]; dagtext(dagnode.intent)*"\nstate=$(dagnode.state)"; end for v in  vertices(dag)]
    end
    labsalign = [length(outneighbors(dag, v)) == 0 ? (:center, :top) : (:center, :bottom)  for v in vertices(dag)]
    GraphMakie.graphplot!(intplot, dag, layout=NetworkLayout.Buchheim(), nlabels=labs, nlabels_align=labsalign)

    return intplot
end
"""
Create legend with (e.g.)
```
Legend(f[1,1], IBNFramework.getlegendplots(p), ["Intent5","Intent3"], tellheight=false, tellwidth=false, halign=:right)
```
"""
find_edge_index(gr::AbstractGraph, e::Edge) = findfirst(==(e), collect(edges(gr)))

struct ExtendedIntentTree{T<:Intent}
    idx::Int
    ibn::IBN
    intent::T
    parent::Union{Nothing, ExtendedIntentTree}
    children::Vector{ExtendedIntentTree}
end
AbstractTrees.printnode(io::IO, node::ExtendedIntentTree) = print(io, "IBN:$(getid(node.ibn)), IntentIdx:$(node.idx)\n$(normaltext(node.intent))")
AbstractTrees.children(node::ExtendedIntentTree) = node.children
AbstractTrees.has_children(node::ExtendedIntentTree) = length(node.children) > 0
AbstractTrees.parent(node::ExtendedIntentTree) = node.parent
AbstractTrees.isroot(node::ExtendedIntentTree) = parent(node) === nothing

function ExtendedIntentTree(ibn::IBN, intentidx::Int)
    intentr = ibn.intents[intentidx]
    eit = ExtendedIntentTree(intentidx, ibn, intentr.data, nothing, Vector{ExtendedIntentTree}())
    populatechildren!(eit, intentr)
    return eit
end

function ExtendedIntentTree(ibn::IBN, intentr::IntentDAG, parent::ExtendedIntentTree)
    eit = ExtendedIntentTree(intentr.idx, ibn, intentr.data, parent, Vector{ExtendedIntentTree}())
    populatechildren!(eit, intentr)
    return eit
end

function populatechildren!(eit::ExtendedIntentTree, intentr::IntentDAG)
    ibnchintentrs = extendedchildren(eit.ibn, intentr)
    if ibnchintentrs !== nothing
        for (chibn, chintentr) in ibnchintentrs
            push!(eit.children, ExtendedIntentTree(chibn, chintentr, eit))
        end
    end
end
