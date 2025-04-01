function coordlayout(ibnag::IBNAttributeGraph)
    xs = [[getlongitude(nodeprop), getlatitude(nodeprop)] for nodeprop in MINDF.getnodeproperties.(AG.vertex_attr(ibnag))]
    return [Point(x...) for x in xs ]
end

"""
$(TYPEDSIGNATURES) 

Construct a `IBNAttributeGraph` representation for all mutli-domain network from the IBNFramework neighboring `interIBNF`
"""
function createmultidomainIBNAttributeGraph(ibnf::MINDF.IBNFramework)
    ibnfuuids = UUID[]

    ag1 = MINDF.getibnag(ibnf)
    mdag = MINDF.emptyaggraphwithnewuuid(ag1, UUID(0))

    _recursive_createmultidomainIBNAttributeGraph!(mdag, ibnfuuids, ibnf, ibnf)

    return mdag
end

function _recursive_createmultidomainIBNAttributeGraph!(mdag::MINDF.IBNAttributeGraph, ibnfuuids::Vector{UUID}, myibnf::MINDF.IBNFramework, remoteibnf::MINDF.IBNFramework)
    ibnfid = MINDF.getibnfid(remoteibnf)
    ibnfid ∈ ibnfuuids && return
    remoteibnag = MINDF.requestibnattributegraph(myibnf, remoteibnf)

    for v in vertices(remoteibnag)
        nodeview = MINDF.getnodeview(remoteibnag, v)
        globalnode = MINDF.getglobalnode(MINDF.getproperties(nodeview))
        
        foundindex = MINDF.findindexglobalnode(mdag, globalnode)
        if isnothing(foundindex)
            add_vertex!(mdag)
            push!(AG.vertex_attr(mdag), nodeview)
        else
            AG.vertex_attr(mdag)[foundindex] = nodeview
        end
    end

    for e in edges(remoteibnag)
        globalnode_src = MINDF.getglobalnode(MINDF.getproperties(MINDF.getnodeview(remoteibnag, src(e))))
        globalnode_dst = MINDF.getglobalnode(MINDF.getproperties(MINDF.getnodeview(remoteibnag, dst(e))))
        # TODO find the globalnode index
        src_idx = MINDF.findindexglobalnode(mdag, globalnode_src)
        dst_idx = MINDF.findindexglobalnode(mdag, globalnode_dst)
        (isnothing(src_idx) || isnothing(src_idx)) && error("global node not found in multi-domain attribute graph")
        
        offset_e = Edge(src_idx, dst_idx)
        add_edge!(mdag, offset_e)
        edgeview = MINDF.getedgeview(remoteibnag, e)
        AG.edge_attr(mdag)[offset_e] = edgeview
    end

    push!(ibnfuuids, ibnfid)

    for interibnf in MINDF.getibnfhandlers(remoteibnf)
        _recursive_createmultidomainIBNAttributeGraph!(mdag, ibnfuuids, myibnf, interibnf)
    end
end

