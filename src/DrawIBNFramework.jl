module DrawIBNFramework

using IBNFramework, Graphs, MetaGraphs, CompositeGraphs
import MetaGraphsNext as MGN
import MetaGraphsNext: MetaGraph as MG
import MetaGraphsNext: MetaDiGraph as MDG
using Makie, GraphMakie, NetworkLayout
using IBNFramework: getleafs, LowLevelIntent, NodeRouterIntent, NodeSpectrumIntent, dividefamily, dagtext, logicalorderedintents, getroot, localedge, localnode, getid
import Colors

export ibnplot, ibnplot!, intentplot, intentplot!
#export showgtk, showgtk!

include("makierecipies.jl")

end
