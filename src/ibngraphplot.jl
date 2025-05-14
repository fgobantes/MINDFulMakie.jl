"""
Base function to plot an `AttributeGraph` made for `IBNFramework`
  - `showmap = false`
  - `shownodelocallabels = false`
"""
@recipe(IBNGraphPlot, ibnattributegraph) do scene
    Theme(
        showmap = false,
        shownodelocallabels = false
    )
end

function Makie.plot!(ibngraphplot::IBNGraphPlot)
    ibnag = ibngraphplot.ibnattributegraph

    nodelabs =  lift(ibnag, ibngraphplot.shownodelocallabels) do ibnag, shownodelocallabels
        nodelabs = String[]
        for (i, nodeviews) in enumerate(MINDF.getnodeviews(ibnag))
            labelbuilder = IOBuffer()
            if shownodelocallabels
                print(labelbuilder, i)
            end
            push!(nodelabs, String(take!(labelbuilder)))
        end
        return nodelabs
    end

    coords = coordlayout(ibnag[])
    GraphMakie.graphplot!(ibngraphplot, ibnag; layout = x -> coords, arrow_show=false, edge_plottype=:linesegments, nlabels=nodelabs, ibngraphplot.attributes...)
    return ibngraphplot
end
