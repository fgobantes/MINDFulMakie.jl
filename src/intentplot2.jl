"""
    Plot the intent dag with the following options
    - `showstate = false`
    - `showintent = false`
"""
@recipe(IntentPlot, ibnf, intentid) do scene
    Theme(
        showstate = false,
        showintent = false
    )
end

#TODO plot only descendants of the idagnode
function Makie.plot!(intplot::IntentPlot)
    idag = MINDF.getidag(intplot.ibnf[])
    idagnode = MINDF.getidagnode(idag, intplot.intentid[])

    subgraph_subgraphvmap = lift(intplot.ibnf, intplot.intentid) do ibnf, intentid
        idag = MINDF.getidag(ibnf)
        involvedgraphnodes = MINDF.getidagnodeidxsdescendants(idag, intentid; includeroot=true)
        Graphs.induced_subgraph(AG.getgraph(idag), involvedgraphnodes)
    end
    subgraphob = @lift $(subgraph_subgraphvmap)[1]
    subgraphvmapob = @lift $(subgraph_subgraphvmap)[2]

    labsob = lift(intplot.ibnf, intplot.showintent, intplot.showstate, subgraphvmapob) do ibnf, showintent, showstate, subgraphvmap
        idag = MINDF.getidag(ibnf)
        labs = String[]
        for idagnode in MINDF.getidagnodes(idag)[subgraphvmap]
            labelbuilder = IOBuffer()

            uuid = @sprintf("%x", getfield(MINDF.getidagnodeid(idagnode), :value))
            println(labelbuilder, uuid)

            if showintent
                println(labelbuilder, MINDF.getintent(idagnode))
            end
            if showstate
                state = string(MINDF.getidagnodestate(idagnode))            
                println(labelbuilder, state)
            end

            push!(labs, String(take!(labelbuilder)))
        end
        labs
    end

    try 
        subgraphlayoutob = @lift daglayout($(subgraphob))
        GraphMakie.graphplot!(intplot, subgraphob; layout=subgraphlayoutob, nlabels=labsob)
    catch e
        if e isa MathOptInterface.ResultIndexBoundsError{MathOptInterface.ObjectiveValue}
            # without special layout
            GraphMakie.graphplot!(intplot, idag; nlabels=labs)
        else 
            rethrow(e)
        end
    end

    return intplot
end


function daglayout(dag::AbstractGraph; angle=-π/2)
    xs, ys, paths = solve_positions(Zarate(), dag)
    rotatecoords!(xs, ys, paths, -π/2)
    (args...) -> Point2.(zip(xs,ys))
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
