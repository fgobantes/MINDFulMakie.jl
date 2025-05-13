module MINDFulMakie

using MINDFul, Graphs
using Makie, GraphMakie, NetworkLayout, Colors
using LayeredLayouts
using DocStringExtensions
using UUIDs
using Printf

import MathOptInterface
import AbstractTrees

# TODO: delete
import MetaGraphsNext as MGN

import AttributeGraphs as AG
import MINDFul: IBNAttributeGraph, getlatitude, getlongitude, IntentDAG, getibnfid, getidag, requestidag_init, getintent, RemoteIntent, getidagnodeid, getidagnodes, getidagnode

export ibnplot, ibnplot!, intentplot, intentplot!, ibngraphplot, ibngraphplot!

const MINDF = MINDFul

include("utils.jl")
include("ibngraphplot.jl")
include("ibnplot.jl")
include("intentplot.jl")

end
