module MINDFulMakie

using MINDFul, Graphs, MetaGraphs, NestedGraphs, NestedGraphMakie
using Makie, GraphMakie, NetworkLayout, Colors
using DocStringExtensions

import AbstractTrees
import MetaGraphsNext as MGN
import MetaGraphsNext: MetaGraph as MG
import MetaGraphsNext: MetaDiGraph as MDG
import MINDFul: getleafs, LowLevelIntent, NodeRouterIntent, NodeSpectrumIntent, dividefamily, dagtext, logicalorderedintents, getroot, localedge, localnode, getid

export ibnplot, ibnplot!, intentplot, intentplot!
#export showgtk, showgtk!

include("extendedintenttree.jl")
include("ibnplot.jl")
include("intentplot.jl")

end
