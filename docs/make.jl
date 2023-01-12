using Documenter, MINDFulMakie

makedocs(sitename="MINDFulMakie.jl",
    pages = [
        "Introduction" => "index.md",
        "Usage and Examples" => "usage.md",
        "API" => "API.md"
    ])

deploydocs(
    repo = "github.com/UniStuttgart-IKR/MINDFulMakie.jl.git",
)
