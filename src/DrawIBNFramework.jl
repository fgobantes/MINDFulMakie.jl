module DrawIBNFramework

import AbstractTrees
using IBNFramework, Graphs, MetaGraphs, NestedGraphs, NestedGraphMakie
import MetaGraphsNext as MGN
import MetaGraphsNext: MetaGraph as MG
import MetaGraphsNext: MetaDiGraph as MDG
using Makie, GraphMakie, NetworkLayout
import IBNFramework: getleafs, LowLevelIntent, NodeRouterIntent, NodeSpectrumIntent, dividefamily, dagtext, logicalorderedintents, getroot, localedge, localnode, getid
import Colors

export ibnplot, ibnplot!, intentplot, intentplot!
#export showgtk, showgtk!

include("makierecipies.jl")

end
