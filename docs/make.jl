using Documenter, MagneticReadHead

makedocs(;
    modules=[MagneticReadHead],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/oxinabox/MagneticReadHead.jl/blob/{commit}{path}#L{line}",
    sitename="MagneticReadHead.jl",
    authors="Lyndon White",
    assets=[],
)

deploydocs(;
    repo="github.com/oxinabox/MagneticReadHead.jl",
)
