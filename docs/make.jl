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
        "Home" => "index.md",
        "ERA5Reanalysis Basics" => [
            "Components"     => "index.md",
            "ERA5 Modules"   => "modules.md",
            "ERA5 Variables" => "variables.md",
            "ERA5 Regions"   => "regions.md"
        ],
        "Downloading ERA5 Data" => [
            "The CDSAPI"              => "cdsapi.md"
            "Downloading with Julia"  => "downloadjulia.md"
            "Downloading with Python" => "downloadpython.md"
        ]
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/ERA5Reanalysis.jl.git",
    devbranch = "main"
)
