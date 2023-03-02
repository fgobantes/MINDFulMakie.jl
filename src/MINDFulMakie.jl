module MINDFulMakie

using MINDFul, Graphs, MetaGraphs, NestedGraphs, NestedGraphMakie
using Makie, GraphMakie, NetworkLayout, Colors
using LayeredLayouts
using DocStringExtensions
using UUIDs

import AbstractTrees
import MetaGraphsNext as MGN
import MINDFul: getleafs, LowLevelIntent, NodeSpectrumIntent, dividefamily, dagtext, logicalorderedintents, localedge, localnode, getid

export ibnplot, ibnplot!, intentplot, intentplot!, netgraphplot, netgraphplot!
#export showgtk, showgtk!

include("extendedintenttree.jl")
include("netgraphplot.jl")
include("ibnplot.jl")
include("intentplot.jl")

end
