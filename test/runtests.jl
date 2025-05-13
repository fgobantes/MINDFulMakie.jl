include("initialize.jl")
include("testsuite/ibngraphplot.jl")
include("testsuite/ibnplot.jl")
include("testsuite/intentplot.jl")

@testset "MINDFulMakie.jl" begin
    include("testsuite/reftests.jl")
end
