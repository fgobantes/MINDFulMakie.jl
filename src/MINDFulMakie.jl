module MINDFulMakie

using MINDFul, Graphs
using Makie, GraphMakie, NetworkLayout, Colors
using LayeredLayouts
using DocStringExtensions
using UUIDs
using Printf

import AbstractTrees

# TODO: delete
import MetaGraphsNext as MGN

import AttributeGraphs as AG
import MINDFul: IBNAttributeGraph, getlatitude, getlongitude

export ibnfplot, ibnfplot!, intentplot, intentplot!, netgraphplot, netgraphplot!
#export showgtk, showgtk!

const MINDF = MINDFul

include("utils.jl")
# include("netgraphplot.jl")
include("netgraphplot2.jl")
# include("ibnplot.jl")
include("ibnplot2.jl")
# include("intentplot.jl")
include("intentplot2.jl")

end
