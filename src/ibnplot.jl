
"""
Plot the IBN framework.
The following options:
   - `shownodelabels = nothing` 
Possible values are `[:nothing, :local, :global]`
   - `multidomain = true`
   - `intentids = UUID[]`
Plot the path for the connectivity intents provided as vector
   - `showonlyinstalledintents = false`
Plot the spectrum slots with following properties
   - `showspectrumslots = false`,
   - `spectrumdistancefromedge = 0.0`,
   - `spectrumdistancefromvertex = 0.0`,
   - `spectrumverticalheight = 0.1`
"""
@recipe(IBNPlot, ibnf) do scene
    Theme(
        multidomain = false,
        shownodelabels = nothing,
        intentids = UUID[],
        showonlyinstalledintents = false,
        showspectrumslots = false,
        spectrumdistancefromedge = 0.0,
        spectrumdistancefromvertex = 0.0,
        spectrumverticalheight = 0.1
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

    dictneiag = lift(ibnplot.multidomain, ibnf) do multidomain, ibnf
        if multidomain
            return getattributegraphneighbors(ibnf)
        else
            return Dict(MINDF.getibnfid(ibnf) => MINDF.getibnag(ibnf))
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

    extralines_color_width_scatter_color_size = lift(ibnf, ibnplot.intentids, ibnplot.showonlyinstalledintents, ibnag, gmp.node_pos, nodecolors) do ibnf, intentids, showonlyinstalledintents, ibnag, node_pos, nodecolors
        manyextralines = Vector{Vector{GM.Line{Point2f}}}()
        manyextrascattercoordinates = Vector{Vector{Point2f}}()
        
        for intentuuid in intentids
            extrascatternodes = Set{Int}()
            lollis = MINDF.getlogicallliorder(ibnf, intentuuid; onlyinstalled=showonlyinstalledintents)
            localnodepath = MINDF.logicalordergetpath(lollis)
            globalnodepath = map(ln -> MINDF.getglobalnode(MINDF.getibnag(ibnf), ln), localnodepath)
            ibnaglocalnodepath = map(gn -> MINDF.getnodeindex(ibnag, gn), globalnodepath)
            push!(extrascatternodes,  MINDF.logicalordergetelectricalpresence(lollis)...)
            extralines = pathtolines(ibnaglocalnodepath, node_pos)

            # get globalnodepath from all the RemoteIntent nodes that are also initiators
            remoteintents = filter(MINDF.getintent.(MINDF.getidagnodedescendants(MINDF.getidag(ibnf), intentuuid))) do intentdescendant
                intentdescendant isa MINDF.RemoteIntent && MINDF.getisinitiator(intentdescendant)
            end

            for remoteintent in remoteintents
                remoteibnfid = MINDF.getibnfid(remoteintent)
                remoteintentuuid = MINDF.getidagnodeid(remoteintent)
                globalnodepath = MINDF.requestintentglobalpath_init(ibnf, MINDF.getibnfhandler(ibnf, remoteibnfid), remoteintentuuid; onlyinstalled=showonlyinstalledintents)
                ibnaglocalnodepath = map(gn -> MINDF.getnodeindex(ibnag, gn), globalnodepath)
                push!(extralines, pathtolines(ibnaglocalnodepath, node_pos)...)
                globalnodeelectricalpresence = MINDF.requestglobalnodeelectricalpresence_init(ibnf, MINDF.getibnfhandler(ibnf, remoteibnfid), remoteintentuuid, onlyinstalled=showonlyinstalledintents)
                localnodeelectricalpresence = map(gn -> MINDF.getnodeindex(ibnag, gn), globalnodeelectricalpresence)
                !any(isnothing, localnodeelectricalpresence) && push!(extrascatternodes, localnodeelectricalpresence...)
            end
            scattercoordinates = [node_pos[esn] for esn in extrascatternodes]
            push!(manyextralines, extralines)
            push!(manyextrascattercoordinates, scattercoordinates)
        end

        if isempty(manyextralines)
            ibnaglocalnodepath = MINDF.LocalNode[]
            push!(manyextralines, pathtolines(ibnaglocalnodepath, node_pos))
        end
        if isempty(manyextrascattercoordinates)
            push!(manyextrascattercoordinates, Point2f[])
        end

        @assert length(manyextralines) == length(manyextrascattercoordinates)
        seedcolors = vcat(unique(nodecolors), Colors.@colorant_str("white"))
        colorsextra = Colors.distinguishable_colors(length(manyextralines), seedcolors; dropseed=true)
        manyextralineslengths = length.(manyextralines)
        extralinescolors = let
            manyextralineslengths = length.(manyextralines)
            reduce(vcat, [fill(c, len) for (c,len) in zip(colorsextra, manyextralineslengths)])
        end
        extralineswidth = let
            manyextralineswidth = countfrom(10, 10)
            reduce(vcat, [fill(c, len) for (c,len) in zip(manyextralineswidth, manyextralineslengths)])
        end

        manyextrascatterlengths = length.(manyextrascattercoordinates)
        extrascattercolors = let
            reduce(vcat, [fill(c, len) for (c,len) in zip(colorsextra, manyextrascatterlengths)])
        end
        extrascattersize = let
            manyextralineswidth = countfrom(25, 10)
            reduce(vcat, [fill(c, len) for (c,len) in zip(manyextralineswidth, manyextrascatterlengths)])
        end
        extralines = reduce(vcat, manyextralines)
        extrascatter = reduce(vcat, manyextrascattercoordinates)

        return extralines, extralinescolors, extralineswidth, extrascatter, extrascattercolors, extrascattersize
    end

    extralines = @lift $(extralines_color_width_scatter_color_size)[1]
    extralinescolors = @lift alphacolor.($(extralines_color_width_scatter_color_size)[2], 0.5)
    extralineswidth = @lift $(extralines_color_width_scatter_color_size)[3]
    extrascatter = @lift $(extralines_color_width_scatter_color_size)[4]
    extrascattercolors = @lift alphacolor.($(extralines_color_width_scatter_color_size)[5], 0.5)
    extrascattersize = @lift $(extralines_color_width_scatter_color_size)[6]

    myedgeplot = edgeplot!(ibnplot, extralines; color=extralinescolors, linewidth=extralineswidth)
    translate!(myedgeplot, 0, 0, -2)
    myscatterplot = scatter!(ibnplot, extrascatter; marker = :xcross, color=extrascattercolors, markersize=extrascattersize)
    translate!(myscatterplot, 0, 0, -1)

    # edge status
    linkfailedscatter_rotation = lift(ibnag, dictneiag, gmp.node_pos) do ibnag, dictneiag, node_pos
        drawbrokenlinkstatus(ibnag, dictneiag, node_pos)
    end
    linkfailedscatter = @lift $(linkfailedscatter_rotation)[1]
    linkfailedroration = @lift $(linkfailedscatter_rotation)[2]
    scatter!(ibnplot, linkfailedscatter; marker='/', rotation = linkfailedroration ,color=:red, markersize=15)

    spectrumpolyscolors = lift(ibnag, dictneiag, gmp.node_pos, ibnplot.spectrumdistancefromvertex, ibnplot.spectrumverticalheight, ibnplot.spectrumdistancefromedge, ibnplot.showspectrumslots) do ibnag, dictneiag, node_pos, spectrumdistancefromvertex, spectrumverticalheight, spectrumdistancefromedge, showspectrumslots
        if showspectrumslots
            drawspectrumboxes(ibnag, dictneiag, node_pos, spectrumdistancefromvertex, spectrumverticalheight, spectrumdistancefromedge)
        else
            drawdummypoly(ibnag, node_pos)
        end
    end
    spectrumpolys = @lift $(spectrumpolyscolors)[1]
    spectrumcolors = @lift $(spectrumpolyscolors)[2]

    polyplots = poly!(ibnplot, spectrumpolys; color=spectrumcolors)
    translate!(polyplots, 0, 0, -3)

    return ibnplot
end

function drawdummypoly(ibnag::IBNAttributeGraph, node_pos::Vector{Point2f})
    return collect(first(node_pos, 3)), RGBA(1,1,1,0)
end

function drawbrokenlinkstatus(ibnag::IBNAttributeGraph, dictneiag::Dict{UUID, <: MINDF.IBNAttributeGraph}, node_pos::Vector{Point2f})
    scatterbrokencoords = Vector{Point2f}()
    # markers = Vector{Char}()
    rotations = Vector{Float64}()
    for ed in edges(ibnag)
        p1 = node_pos[src(ed)]
        p2 = node_pos[dst(ed)]
        distance = euklideandistance(p1, p2)
        unitvector = (p2 .- p1) ./ distance
        verticalunitvector = [-unitvector[2], +unitvector[1]]

        remibnag, remed = getcorrespondingibnagedge(ibnag, ed, dictneiag)
        spectrumavailabilities = MINDF.getfiberspectrumavailabilities(remibnag, remed) 
        linkstate = MINDF.getcurrentlinkstate(remibnag, remed; checkfirst=false) 

        if !linkstate
            push!(scatterbrokencoords, p1 + unitvector * distance/2 )
            ang = angle(Complex((p1 .- p2)...))
            if src(ed) > dst(ed)
                push!(rotations, ang)
            else
                push!(rotations, ang + pi/4)
            end
        end
    end
    return scatterbrokencoords, rotations
end

function drawspectrumboxes(ibnag::IBNAttributeGraph, dictneiag::Dict{UUID, <: MINDF.IBNAttributeGraph}, node_pos::Vector{Point2f}, spectrumdistancefromvertex::Real, spectrumverticalheight::Real, spectrumdistancefromedge::Real)
    polys = Vector{Vector{Point2f}}()
    colors = Vector{Colors.RGB}()
    for ed in edges(ibnag)
        p1 = node_pos[src(ed)]
        p2 = node_pos[dst(ed)]
        distance = euklideandistance(p1, p2)
        unitvector = (p2 .- p1) ./ distance
        verticalunitvector = [-unitvector[2], +unitvector[1]]

        remibnag, remed = getcorrespondingibnagedge(ibnag, ed, dictneiag)
        spectrumavailabilities = MINDF.getfiberspectrumavailabilities(remibnag, remed) 
        spectrumdistancefromvertex_abs = spectrumdistancefromvertex*distance
        horizontalmult = (distance - 2spectrumdistancefromvertex_abs) / length(spectrumavailabilities)
        p1p = p1 + unitvector * spectrumdistancefromvertex_abs + verticalunitvector * spectrumdistancefromedge
        incrementhorizontally = unitvector*horizontalmult
        incrementvertically = verticalunitvector*spectrumverticalheight
        for spectrumslotavailability in spectrumavailabilities
            specpoly = Point2f[p1p, p1p+incrementvertically, p1p+incrementvertically+incrementhorizontally, p1p+incrementhorizontally]
            push!(polys, specpoly)
            push!(colors, spectrumslotavailability ? Colors.alphacolor(Colors.@colorant_str("white"), 0.0) : Colors.alphacolor(Colors.@colorant_str("gray"), 0.0))
            p1p += unitvector*horizontalmult
        end
    end
    return polys, colors
end
