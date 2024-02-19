using ERA5Reanalysis
using Documenter

addCDSAPIkey("199699:c52da207-6f7d-4ae8-bd33-085246faee6e")

DocMeta.setdocmeta!(ERA5Reanalysis, :DocTestSetup, :(using ERA5Reanalysis); recursive=true)

makedocs(;
    modules  = [ERA5Reanalysis,GeoRegions],
    doctest  = false,
    warnonly = true,
    format   = Documenter.HTML(;
        collapselevel = 1,
        prettyurls    = false
    ),
    authors  = "Nathanael Wong <natgeo.wong@outlook.com>",
    sitename = "ERA5Reanalysis.jl",
    pages    = [
        "Home" => "index.md",
        "Components" => [
            "Overview" => "components/overview.md",
            "ERA5Datasets" => [
                "An Overview of ERA5 Datasets" => "components/datasets/overview.md",
                "Defining ERA5 Datasets"       => "components/datasets/define.md",
                "Climate Data Store Datasets"  => "components/datasets/cds.md",
                "Custom ERA5 Datasets"         => "components/datasets/custom.md",
                "Dummy ERA5 Datasets"          => "components/datasets/dummy.md",
            ],
            "ERA5Variables" => [
                "What is an ERA5 Variable"           => "components/variables/index.md",
                "Retrieving Existing ERA5 Variables" => "components/variables/read.md",
                "Creating Custom ERA5 Variables"     => "components/variables/custom.md",
                "Resetting ERA5 Variables"           => "components/variables/reset.md",
                "Predefined ERA5 Variables"          => "components/variables/list.md",
            ],
            "ERA5Regions" => [
                "What is an ERA5Region"             => "components/regions/index.md",
                "Is it in an ERA5Region"            => "components/regions/isin.md",
                "Extracting Data for an ERA5Region" => "components/regions/gridded.md",
            ]
        ],
        "Using ERA5Reanalysis.jl" => [
            "LandSea Datasets in ERA5"      => [
                "What is a LandSea Dataset"    => "using/landsea/intro.md",
                "Downloading LandSea Datasets" => "using/landsea/create.md",
            ],
            "Downloading and Reading Data"  => "using/download.md",
        #     "Extraction of subGeoRegions"   => "using/extract.md",
        #     "Analysis and Basic Statistics" => "using/analysis.md",
        #     "Spatialtemporal Smoothing"     => "using/smoothing.md",
        ]
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/ERA5Reanalysis.jl.git",
    devbranch = "main"
)
