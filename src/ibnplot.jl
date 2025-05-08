"""
$(TYPEDSIGNATURES)
Return a network layout for coordinates if each node in `gr` has coordinate data `xcoord` and `ycoord`.
If no return a `NetworkLayout.spring` layout
"""
function coordlayout(gr::AttributeGraph)
    try 
        xs = MINDF.getcoords.(vertex_attr(gr))
        # xs = [[get_prop(gr, v, xcoord), get_prop(gr,v, ycoord)] for v in vertices(gr)]
        return [Point(x...) for x in xs]
    catch e
        return NetworkLayout.spring(gr)
    end
end

"""
    ibnfplot(ibn::IBNF)
    ibnfplot!(ax, ibn::IBNF)

Creates a graph plot of the `ibn`.

## Attributes
- `show_routers = false`: show labels for nodes
- `show_links = false`: show labels for links.
- `subnetwork_view = false`: show node labels with the controller view indexing.
- `intentidx = nothing`: highligh the passed in intent.
"""
@recipe(IBNFPlot, ibn) do scene
    Attributes(
        show_routers = false,
        show_links = false,
        subnetwork_view = false,
        intentidx = nothing
    )
end

function Makie.plot!(ibnp::IBNFPlot)
    ibn = ibnp[:ibn]
    # nodelabels = @lift [nodelabel(ibn[].ngr, v, $(ibnp.show_routers), $(ibnp.subnetwork_view)) for v in vertices(ibn[].ngr)]
        
    colorp_scattern = @lift begin
        if $(ibnp.intentidx) !== nothing && length($(ibnp.intentidx)) > 0
            fillcolorpaths($(ibnp.intentidx), ibn[])
        else
            (nothing, nothing)
        end
    end
    colorpaths = @lift $(colorp_scattern)[1]
    scatternodes = @lift $(colorp_scattern)[2]

    GraphMakie.graphplot!(ibnp, MINDF.getgraph(ibnp[:ibn][]); layout=coordlayout, 
                                color_paths=colorpaths, circle_nodes=scatternodes, ibnp.attributes...)

    return ibnp
end

function Makie.plot!(ibnp::IBNFPlot{<:Tuple{Vector{<:IBNF}}})
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
        # problem with type pyracy due to https://github.com/JuliaLang/julia/issues/10326
        if intentidxs == Union{}[]
            purecols = Vector{typetupl}()
            flatints = UUID[]
        else
            purecols = reduce(vcat, [fill((col, 0.5), length(inidxs)) for (col,inidxs) in zip(intcols, intentidxs)], 
                init=Vector{typetupl}())
            flatints = reduce(vcat, intentidxs, init=UUID[])
        end

        ibnfplot!(ibnp, ibn; ibnp.attributes..., 
                 node_color=distcolors[i], 
                 nlabels_fontsize=Dict(v => 0 for v in getlocalview.(getbordernodes(ibn))),
                                       node_size=Dict(v => 0 for v in getlocalview.(getbordernodes(ibn))),
                                       intentidx=flatints,
                                       pure_colors=purecols)
    end
    return ibnp
end


function fillcolorpaths(intentidxs::Vector{UUID}, ibn::IBNF)
    scatternodes = Vector{Vector{Int}}()
    nedges = [
        let 
            nodespectrumintents = getlogicspecturmintents!(scatternodes, ibn, intentidx)
            nedgs = getfield.(nodespectrumintents, :edge)
            [localedge(ibn, cedg; subnetwork_view=false) for cedg in nedgs]
        end for intentidx in intentidxs
    ]
#    colorpaths = fillcolorpaths(nedges, ibn.ngr, edps)
    return nedges, scatternodes
end

function getlogicspecturmintents!(scatternodes, ibn::IBNF, intentidx::UUID)
    glbns, _ = logicalorderedintents(ibn, getintentnode(ibn, intentidx), true)
    llis = [glbn.lli for glbn in glbns if glbn.ibn.id == ibn.id]
    noderouterintents = filter(x -> x isa MINDFul.NodeRouterPortIntent, llis)
    noderouternodes = getfield.(noderouterintents, :node)
    localnoderouterintents = [localnode(ibn, nri; subnetwork_view=false) for nri in noderouternodes]
    push!(scatternodes, localnoderouterintents)
    return filter(x -> x isa NodeSpectrumIntent, llis)
end


