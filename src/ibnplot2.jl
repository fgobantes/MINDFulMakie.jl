
"""
Plot the IBN framework.
The following options:
   - `shownodelabels = nothing` 
Possible values are `[:nothing, :local, :global]`
   - `multidomain = true`
   - `intentuuid = nothing`
Plot the path for the connectivity intent
   - `showuninstalledintents = false`
"""
@recipe(IBNPlot, ibnf) do scene
    Theme(
        multidomain = true,
        shownodelabels = nothing,
        intentuuid = nothing,
        showonlyinstalledintents = false
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

    gmp = ibnplot.plots[1].plots[1]

    extralines = lift(ibnf, ibnplot.intentuuid, ibnplot.showonlyinstalledintents, ibnag, gmp.node_pos) do ibnf, intentuuid, showonlyinstalledintents, ibnag, node_pos
        extralines = if !isnothing(intentuuid)
            localnodepath = MINDF.logicalordergetpath(MINDF.getlogicallliorder(ibnf, intentuuid; onlyinstalled=showonlyinstalledintents))
            globalnodepath = map(ln -> MINDF.getglobalnode(MINDF.getibnag(ibnf), ln), localnodepath)
            ibnaglocalnodepath = map(gn -> MINDF.getnodeindex(ibnag, gn), globalnodepath)
            pathtolines(ibnaglocalnodepath, node_pos)
        else
            ibnaglocalnodepath = MINDF.LocalNode[]
            pathtolines(ibnaglocalnodepath, node_pos)
        end
        # get globalnodepath from all the RemoteIntent nodes that are also initiators
        remoteintents = filter(MINDF.getintent.(MINDF.getidagnodedescendants(MINDF.getidag(ibnf), intentuuid))) do intentdescendant
            intentdescendant isa MINDF.RemoteIntent && MINDF.getisinitiator(intentdescendant)
        end
        for remoteintent in remoteintents
            remoteibnfid = MINDF.getibnfid(remoteintent)
            remoteintentuuid = MINDF.getidagnodeid(remoteintent)
            globalnodepath = MINDF.requestintentglobalpath_init(ibnf, MINDF.getibnfhandler(ibnf, remoteibnfid), remoteintentuuid; onlyinstalled=false)
            ibnaglocalnodepath = map(gn -> MINDF.getnodeindex(ibnag, gn), globalnodepath)
            push!(extralines, pathtolines(ibnaglocalnodepath, node_pos)...)
        end
        extralines
    end

    edgeplot!(ibnplot, extralines; color=(:blue, 0.5), linewidth=10)

   
    return ibnplot
end
