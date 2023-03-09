"""
    intentplot(ibn::IBN, idx::Integer)
    intentplot!(ax, ibn::IBN, idx::Integer)

Creates a tree plot of the intent Directed Acyclic Graph (DAG) `idx`.

## Attributes
- `interdomain=false`: reach out to all domains (might malfunction)
- `show_state=true`: shows the state of each intent DAG node
"""
@recipe(IntentPlot, ibn, idx) do scene
    Attributes(
               interdomain = false,
               show_state = true,
               show_all = false,
               multi_domain = false,
    )
end

function Makie.plot!(intplot::IntentPlot)
    ibn = intplot[:ibn][]
    idx = intplot[:idx][]

    # dag = ibn[].intents[idx[]]

    if intplot.show_all[] 
        dag = getintentdag(ibn)
    else
        dag = plotablesubdag(getintentdag(ibn), idx)
    end
    if intplot.show_state[] == false
        labs = [dagtext(dag[MGN.label_for(dag,v)].intent) for v in  vertices(dag)]
    else 
        labs = [let dagnode=dag[MGN.label_for(dag,v)]; dagtext(getintent(dagnode))*"\nstate=$(dagnode.state)\nuuid=$(getid(dagnode))"; end for v in  vertices(dag)]
    end
    labsalign = [length(outneighbors(dag, v)) == 0 ? (:center, :top) : (:center, :bottom)  for v in vertices(dag)]
    GraphMakie.graphplot!(intplot, dag, layout=daglayout(dag), nlabels=labs, nlabels_align=labsalign)

    return intplot
end

function daglayout(dag::AbstractGraph; angle=-π/2)
    xs, ys, paths = solve_positions(Zarate(), dag)
    rotatecoords!(xs, ys, paths, -π/2)
    (args...) -> Point2.(zip(xs,ys))
end


function plotablesubdag(dag::IntentDAG, uuid::UUID)
    nds = unique(plotablesubdagnodes(dag.graph, MGN.code_for(dag, uuid)))
    induced_subgraph(dag, nds)[1]
end

"""
    plotablesubdagnodes(dag::AbstractGraph, nd::Integer)

Return the nodes out of which a subdag of `dag` such that all direct descendants and direct ancestors are shown.
I.e. do not show other children of parents (siblings or cousins). 
However show married nodes (common child) and all their direct ancestors (not other children).
The algorithm actually creates a DAG such that all paths have at most one stream of incoming edges (i.e. after follow an in-edge you cannot go out again)
"""
function plotablesubdagnodes(dag::T, node::U) where {T<:AbstractGraph, U<:Integer}
    # nodes to collect
    vs = [node]
    _plotablesubdagnodes!(vs, dag, node, nothing, true)
    return vs
end

function _plotablesubdagnodes!(vs, dag, node, parnode, goingout)
    if goingout
        for d in outneighbors(dag, node)
            push!(vs, d)
            _plotablesubdagnodes!(vs, dag, d, node, true)
        end
        for d in inneighbors(dag, node)
            !isnothing(parnode) && parnode == d && continue
            push!(vs, d)
            _plotablesubdagnodes!(vs, dag, d, node, false)
        end
    else
        for d in inneighbors(dag, node)
            !isnothing(parnode) && parnode == d && continue
            push!(vs, d)
            _plotablesubdagnodes!(vs, dag, d, node, false)
        end
    end
end


"""
    rotatecoords(xs::AbstractVector, ys::AbstractVector, paths::AbstractDict, θ)

Rotate coordinates `xs`, `ys` and paths `paths` by `angle`
"""
function rotatecoords(xs::AbstractVector, ys::AbstractVector, paths::AbstractDict, θ)
    # rotation matrix
    r = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    points = vcat.(xs, ys)
    newpoints = [r * pointvec for pointvec in points]
    newpaths = Dict(k => let newpath = [r * pointvec for pointvec in vcat.(v...)]
             (getindex.(newpath, 1), getindex.(newpath, 2))
         end
         for (k,v) in paths)
    return getindex.(newpoints, 1), getindex.(newpoints, 2), newpaths
end

"""
    rotatecoords!(xs::AbstractVector, ys::AbstractVector, paths::AbstractDict, θ)

Rotate coordinates `xs`, `ys` and paths `paths` by `angle`
"""
function rotatecoords!(xs::AbstractVector, ys::AbstractVector, paths::AbstractDict, θ)
    # rotation matrix
    r = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    points = vcat.(xs, ys)
    newpoints = [r * pointvec for pointvec in points]
    xs .= getindex.(newpoints, 1)
    ys .= getindex.(newpoints, 2)
    for (k,v) in paths
        newpath = [r * pointvec for pointvec in vcat.(v...)]
        paths[k] = (getindex.(newpath, 1), getindex.(newpath, 2))
    end
end
