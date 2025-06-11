include("initialize_ma1069.jl")
include("testsuite_ma1069/ibngraphplot_1069.jl")
include("testsuite_ma1069/ibnplot_1069.jl")
include("testsuite_ma1069/intentplot_1069.jl")

@testset "MINDFulMakie.jl" begin
    include("testsuite_ma1069/reftests_1069.jl")
end
