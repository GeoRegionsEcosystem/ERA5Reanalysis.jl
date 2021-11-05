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
        "`ERA5Module`s" => [
            "CDS Datasets"   => "modules/index.md",
            "Usage Examples" => "modules/examples.md",
        ],
        "`ERA5Variable`s" => [
            "Variable Types"                      => "variables/index.md",
            "Retrieving Existing `ERA5Variable`s" => "variables/read.md",
            "List of Existing `ERA5Variable`s"    => "variables/list.md",
            "Creating Custom `ERA5Variable`s"     => [
                "Custom Pressure-Level Variables" => "variables/pressures.md",
                "Custom Single-Level Variables"   => "variables/singles.md",
                "Resetting `ERA5Variable`s"       => "variables/reset.md",
            ],
        ],
        "`ERA5Region`s" => [
            "The Basics of an `ERA5Region`" => "regions/index.md",
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
