"""
    netgraphplot(ng::NetsedGraph)
    netgraphplot!(ax, ng::NetsedGraph)

Creates a graph plot of the ng represented as a `NestedGraph`.

## Attributes
- `show_routers = false`: show labels for nodes
- `show_links = false`: show labels for links.
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
"""
@recipe(NetGraphPlot, ng) do scene
    Attributes(
        show_routers = false,
        show_links = false,
        color_paths = nothing,
        color_edges = nothing,
        pure_colors = nothing,
        circle_nodes = nothing,
    )
end

function Makie.plot!(nngp::NetGraphPlot)
        ng = nngp[:ng]
            
        NestedGraphMakie.ngraphplot!(nngp, nngp[:ng][]; nngp.attributes...)

        # first plots[1] is NestedGraphMakie and second plots[1] is GraphMakie
        gmp = nngp.plots[1].plots[1]
        edps = gmp.edge_paths
        # scatter plot
        scp = nngp.plots[1].plots[1].plots[2]
        
        colorp_scattern = @lift begin
            clps = Vector{Vector{GraphMakie.AbstractPath{Point{2, Float32}}}}()
            scnds = Vector{Vector{Int}}()

            if $(nngp.color_paths) !== nothing
                push!(clps, fillcolorpaths($(nngp.color_paths), ng[], $(edps))...)
            end
            if $(nngp.color_edges) !== nothing
                push!(clps, fillcolorpaths($(nngp.color_edges), ng[], $(edps))...)
            end
            if $(nngp.circle_nodes) !== nothing
                push!(scnds, $(nngp.circle_nodes)...)
            end
            return clps, scnds
        end
        colorpaths = @lift $(colorp_scattern)[1]
        scatternodes = @lift $(colorp_scattern)[2]

        nngp[:flat_paths] = @lift begin
            reduce(vcat, $(colorpaths); init=deduceOuterVector($(colorpaths))())
        end
        flat_paths = nngp[:flat_paths]

        nngp[:flat_colors] = @lift begin
            if $(nngp.pure_colors) === nothing
                dcs = distinguishable_colors(length($colorpaths) + 3, [RGB(1,1,1), RGB(0,0,0)])[3:end]
                vvcol = [fill((dcs[i], 0.5), length(colorpath)) for (i,colorpath) in enumerate($colorpaths)]
            else
                vvcol = [fill(pc, length(cp)) for (pc,cp) in zip($(nngp.pure_colors),($colorpaths))]
            end
            temp = reduce(vcat, vvcol; init=deduceOuterVector(vvcol)())
        end
        flat_colors = nngp[:flat_colors]
        
        lwd2 = @lift $(gmp.edge_width)*5

        if length(flat_paths[]) > 0
            GraphMakie.edgeplot!(nngp, flat_paths; color=flat_colors, linewidth=lwd2)
        end

        nngp[:flat_scatternodes] = @lift begin
            flat_nodes = reduce(vcat, $(scatternodes); init=deduceOuterVector($(scatternodes))())
            $(gmp.node_pos)[flat_nodes]
        end
        flat_scatternodes = nngp[:flat_scatternodes]
        
        flat_markersize = @lift begin
            circleradius = Vector{Float32}()
            #startcircleradius = maximum(values($(scp.markersize)))
            startcircleradius = 2
            for sn in $(scatternodes)

                #push!(circleradius, fill(startcircleradius, length(sn))...)
                csize = circlesizeiteration(sn, startcircleradius; step=1)
                push!(circleradius, csize...)
                startcircleradius = maximum(csize; init=startcircleradius) + 1.5
            end
            return circleradius
        end
        
        # TODO code repeat
        flat_scattercolor = @lift begin
            if $(nngp.pure_colors) === nothing
                dcs = distinguishable_colors(length($scatternodes) + 3, [RGB(1,1,1), RGB(0,0,0)])[3:end]
                vvcol = [fill(dcs[i], length(scnds)) for (i,scnds) in enumerate($scatternodes)]
            else
                vvcol = [fill(pc, length(sn)) for (pc,sn) in zip($(nngp.pure_colors),($scatternodes))]
            end
            reduce(vcat, vvcol; init=deduceOuterVector(vvcol)())
        end
        
        #scatter!(nngp, flat_scatternodes, markersize=flat_markersize, 
        #   strokecolor=flat_scattercolor, strokewidth=2, color=(:black, 0.0))
        
        #p_big = decompose(Point2f, Circle(Point2f(0), 1))
        #p_small = decompose(Point2f, Circle(Point2f(0), 0.8))
        #scatter!(nngp, flat_scatternodes, markersize=flat_markersize, color=flat_scattercolor, marker=Makie.Polygon(p_big, [p_small]))
        
        genmarker = @lift begin
            if isempty($flat_markersize) 
                return :xcross
            else
                return generatemarker.($flat_markersize)
            end
        end
        scatter!(nngp, flat_scatternodes, color=flat_scattercolor, marker=genmarker)

        return nngp
end

function generatemarker(size; width=0.5)
    p_big = decompose(Point2f, Circle(Point2f(0), size))
    p_small = decompose(Point2f, Circle(Point2f(0), size-width))
    Makie.Polygon(p_big, [p_small])
end

function circlesizeiteration(sn::Vector{U}, startcircleradius::R; step=1) where {U<:Integer, R<:Real}
    d = Dict{U, R}();
    res = fill(startcircleradius, length(sn))
    for (i,s) in enumerate(sn)
        if haskey(d, s)
            d[s] += step
        else
            d[s] = startcircleradius
        end
        res[i] = d[s]
    end
    return res
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
find_edge_index(gr::AbstractGraph, e::AbstractEdge) = findfirst(==(e), collect(edges(gr)))

"""
Create legend with (e.g.)
```
Legend(f[1,1], MINDFul.getlegendplots(p), ["Intent5","Intent3"], tellheight=false, tellwidth=false, halign=:right)
```
"""
getlegendplots(ibnp::NetGraphPlot) = return ibnp.plots[2:end]

"Check if `x` is a vector of vectors of `Integer`"
isvvi(x::Vector{Vector{T}}) where T = all(i -> i isa Integer, Iterators.flatten(x))
isvvi(j) = false

"Check if `x` is a vector of vectors of `AbstractSimpleEdge`"
isvve(x::Vector{Vector{T}}) where T<:Graphs.SimpleGraphs.AbstractSimpleEdge = length(x) > 0
isvve(j) = false

"Get type by stripping outer vector"
deduceOuterVector(x::Vector{T}) where T = T
