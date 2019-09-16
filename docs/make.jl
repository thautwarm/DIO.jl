using Documenter, RestrainJIT

makedocs(;
    modules=[RestrainJIT],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/thautwarm/RestrainJIT.jl/blob/{commit}{path}#L{line}",
    sitename="RestrainJIT.jl",
    authors="thautwarm",
    assets=String[],
)

deploydocs(;
    repo="github.com/thautwarm/RestrainJIT.jl",
)
