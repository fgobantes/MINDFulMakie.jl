
"""
   shownodelabels = [:nothing, :local, :global]
"""
@recipe(IBNPlot, ibnf) do scene
    Theme(
        multidomain = true,
        shownodelabels = nothing
    )
end

function Makie.plot!(ibnplot::IBNPlot)
    ibnf = ibnplot.ibnf

    ibnag = lift(ibnplot.multidomain, ibnf) do multidomain, ibnf
        if multidomain
            return createmultidomainIBNAttributeGraph(ibnf)
        else
            return MINDF.getibnag(ibnf)
        end
    end

    # how many different global ibnfs id exist ?
    nodecolors = lift(ibnag) do ibnag 
        ibnfids = unique(MINDF.getibnfid.(MINDF.getglobalnode.(MINDF.getproperties.(MINDF.getnodeviews(ibnag)))))
        ibnfidxdict = Dict(ibnfid => i for (i,ibnfid) in enumerate(ibnfids))
        colors = Colors.distinguishable_colors(length(ibnfids), [Colors.@colorant_str("white")]; dropseed=true)
        nodecolors = [
            colors[ibnfidxdict[ibnfid]]
            for ibnfid in MINDF.getibnfid.(MINDF.getglobalnode.(MINDF.getproperties.(MINDF.getnodeviews(ibnag))))
        ]
        return nodecolors
    end

    nodelabs =  lift(ibnag, ibnplot.shownodelabels) do ibnag, shownodelabels
        nodelabs = String[]
        # for localnode in MINDF.getlocalnode.(MINDF.getglobalnode.(MINDF.getnodeproperties.(MINDF.getnodeviews(ibnag))))
        for globalnode in MINDF.getglobalnode.(MINDF.getnodeproperties.(MINDF.getnodeviews(ibnag)))
            labelbuilder = IOBuffer()
            if shownodelabels == :global
                print(labelbuilder, globalnode)
            elseif shownodelabels == :local
                print(labelbuilder, MINDF.getlocalnode(globalnode))
            end
            push!(nodelabs, String(take!(labelbuilder)))
        end
        return nodelabs
    end

    ibngraphplot!(ibnplot, ibnag; node_color=nodecolors, nlabels=nodelabs, ibnplot.attributes...)

    return ibnplot
end
