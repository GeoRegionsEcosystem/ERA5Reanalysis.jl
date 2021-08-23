using ERA5Reanalysis
using Documenter

DocMeta.setdocmeta!(ERA5Reanalysis, :DocTestSetup, :(using ERA5Reanalysis); recursive=true)

makedocs(;
    modules  = [ERA5Reanalysis],
    doctest  = false,
    format   = Documenter.HTML(;
        prettyurls=get(ENV,"CI","false") == "true",
        canonical="https://natgeo-wong.github.io/ERA5Reanalysis.jl",
        assets=String[],
    ),
    authors  = "Nathanael Wong <natgeo.wong@outlook.com>",
    sitename = "ERA5Reanalysis.jl",
    pages    = [
        "Home"                        => "index.md",
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/ERA5Reanalysis.jl.git",
    devbranch = "main"
)
