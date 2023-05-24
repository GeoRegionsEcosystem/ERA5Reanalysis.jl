using ERA5Reanalysis
using Documenter

DocMeta.setdocmeta!(ERA5Reanalysis, :DocTestSetup, :(using ERA5Reanalysis); recursive=true)

makedocs(;
    modules  = [ERA5Reanalysis,GeoRegions],
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
        "Components" => [
            "Overview" => "components/overview.md",
            "ERA5Datasets" => [
                "CDS Datasets"   => "components/datasets/index.md",
                "Usage Examples" => "components/datasets/examples.md",
            ],
            "ERA5Variables" => [
                "Variable Types"                    => "components/variables/index.md",
                "Retrieving Existing ERA5Variables" => "components/variables/read.md",
                "List of Existing ERA5Variables"    => "components/variables/list.md",
                "Creating Custom ERA5Variables"     => "components/variables/custom.md",
                "Resetting ERA5Variables"           => "components/variables/reset.md",
            ],
            "ERA5Regions" => [
                "The Basics of an ERA5Region"       => "components/regions/index.md",
                "Is it in an ERA5Region"            => "components/regions/isin.md",
                "Extracting Data using ERA5Regions" => "components/regions/gridded.md",
            ]
        ],
        "Downloading ERA5 Data" => [
            "Downloading ERA5 Datasets" => "downloads/overview.md",
            "Examples"                  => "downloads/examples.md",
            "An Overview of the CDSAPI" => "downloads/cdsapi.md",
        ]
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/ERA5Reanalysis.jl.git",
    devbranch = "main"
)
