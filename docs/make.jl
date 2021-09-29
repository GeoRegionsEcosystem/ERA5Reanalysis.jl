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
        "ERA5 Modules"   => [
            "CDS Datasets"   => "modules/index.md",
            "Usage Examples" => "modules/examples.md",
        ],
        "ERA5Reanalysis Basics" => [
            #"Components"     => "basics/index.md",
            "ERA5 Variables" => "basics/variables.md",
            "ERA5 Regions"   => "basics/regions.md"
        ],
        "Downloading ERA5 Data" => [
            "The CDSAPI"              => "downloads/cdsapi.md"
            "Downloading with Julia"  => "downloads/julia.md"
            "Downloading with Python" => "downloads/python.md"
        ]
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/ERA5Reanalysis.jl.git",
    devbranch = "main"
)
