@recipe(IntentPlot, ibn, idx) do scene
    Theme(
        showstate = false
    )
end

function Makie.plot!(intplot::IntentPlot)
    idag = MINDF.getidag(intplot.ibn[])
    idagnode = MINDF.getidagnode(idag, intplot.idx[])

    labs = String[]
    for idagnode in MINDF.getidagnodes(idag)
        labelbuilder = IOBuffer()

        uuid = @sprintf("%x", getfield(MINDF.getidagnodeid(idagnode), :value))
        print(labelbuilder, uuid)

        if intplot.showstate[]
            state = string(MINDF.getidagnodestate(idagnode))            
            print(labelbuilder, "-", state)
        end

        push!(labs, String(take!(labelbuilder)))
    end

    # labs = [@sprintf("%x", d) for d in  getfield.(MINDF.getidagnodeid.(MINDF.getidagnodes(idag)), :value)]
    # stateslabs = [string.(MINDF.getidagnodeid.(MINDF.getidagnodes(idag)))]

    # if intplot.showstate == true
    #     finallabs = join.(labs, stateslabs
    # else
    #     finallabs = labs
    # end

    GraphMakie.graphplot!(intplot, idag; layout=daglayout(idag), nlabels=labs)
    # GraphMakie.graphplot!(intplot, idag; layout=daglayout(idag), nlabels=labs)

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
