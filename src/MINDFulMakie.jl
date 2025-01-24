module MINDFulMakie

using MINDFul, Graphs, AttributeGraphs
using Makie, GraphMakie, NetworkLayout, Colors
using LayeredLayouts
using DocStringExtensions
using UUIDs

import AbstractTrees
import MetaGraphsNext as MGN

export ibnfplot, ibnfplot!, intentplot, intentplot!, netgraphplot, netgraphplot!
#export showgtk, showgtk!

const MINDF = MINDFul

include("netgraphplot.jl")
include("ibnplot.jl")
include("intentplot.jl")

end
