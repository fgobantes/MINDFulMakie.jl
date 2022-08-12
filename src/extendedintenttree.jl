struct ExtendedIntentTree{T<:Intent}
    idx::Int
    ibn::IBN
    intent::T
    parent::Union{Nothing, ExtendedIntentTree}
    children::Vector{ExtendedIntentTree}
end
AbstractTrees.printnode(io::IO, node::ExtendedIntentTree) = print(io, "IBN:$(getid(node.ibn)), IntentIdx:$(node.idx)\n$(normaltext(node.intent))")
AbstractTrees.children(node::ExtendedIntentTree) = node.children
AbstractTrees.parent(node::ExtendedIntentTree) = node.parent
AbstractTrees.isroot(node::ExtendedIntentTree) = parent(node) === nothing
has_children(node::ExtendedIntentTree) = length(node.children) > 0

function ExtendedIntentTree(ibn::IBN, intentidx::Int)
    intentr = ibn.intents[intentidx]
    eit = ExtendedIntentTree(intentidx, ibn, intentr.data, nothing, Vector{ExtendedIntentTree}())
    populatechildren!(eit, intentr)
    return eit
end

function ExtendedIntentTree(ibn::IBN, intentr::IntentDAG, parent::ExtendedIntentTree)
    eit = ExtendedIntentTree(intentr.idx, ibn, intentr.data, parent, Vector{ExtendedIntentTree}())
    populatechildren!(eit, intentr)
    return eit
end

function populatechildren!(eit::ExtendedIntentTree, intentr::IntentDAG)
    ibnchintentrs = extendedchildren(eit.ibn, intentr)
    if ibnchintentrs !== nothing
        for (chibn, chintentr) in ibnchintentrs
            push!(eit.children, ExtendedIntentTree(chibn, chintentr, eit))
        end
    end
end