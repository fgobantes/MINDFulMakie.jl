using GLMakie
using Graphs
using UUIDs
import JLD2

using Test

import MINDFul as MINDF
import MINDFulMakie as MINDFM
import AttributeGraphs as AG

ibnf = first(JLD2.load("data/ibnf.jld2"))[2]

ibnag = MINDF.getibnag(ibnf)

MINDFM.ibngraphplot(ibnag)

# nothing

