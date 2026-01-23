using Documenter
using DocumenterVitepress
using ERA5Reanalysis

using CairoMakie
CairoMakie.activate!(type = "svg")

makedocs(;
    modules  = [ERA5Reanalysis, GeoRegions],
    authors  = "Nathanael Wong <natgeo.wong@outlook.com>",
    sitename = "ERA5Reanalysis.jl",
    doctest  = false,
    warnonly = true,
    format   = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/GeoRegionsEcosystem/ERA5Reanalysis.jl",
    ),
    pages    = [
        "Home"       => "index.md",
        "The Basics" => "basics.md",
        "Setup"      => "setup.md",
        "Datasets"   => [
            "Available Datasets"  => "datasets/intro.md",
            "Defining Datasets"   => "datasets/define.md",
            "CDS Datasets"        => "datasets/cds.md",
            "Custom Datasets"     => "datasets/custom.md",
            "Dummy Datasets"      => "datasets/dummy.md",
        ],
        "Variables"  => [
            "What is an ERA5Variable"   => "variables/index.md",
            "Loading Variables"         => "variables/read.md",
            "Custom Variables"          => "variables/custom.md",
            "Resetting Variables"       => "variables/reset.md",
            "Variable List"             => "variables/list.md",
        ],
        "Regions"    => [
            "What is an ERA5Region"     => "regions/index.md",
            "Region Checks"             => "regions/isin.md",
            "Extracting Grid Data"      => "regions/gridded.md",
        ],
        "Tutorials"  => [
            "Downloading Datasets"      => "using/download.md",
            "LandSea Datasets"          => "using/landsea.md",
        ],
    ],
)

DocumenterVitepress.deploydocs(
    repo      = "github.com/GeoRegionsEcosystem/ERA5Reanalysis.jl.git",
    target    = "build",
    devbranch = "main",
    branch    = "gh-pages",
)

recursive_find(directory, pattern) =
    mapreduce(vcat, walkdir(directory)) do (root, dirs, files)
        joinpath.(root, filter(contains(pattern), files))
    end

files = []
for pattern in [r"\.txt", r"\.nc"]
    global files = vcat(files, recursive_find(@__DIR__, pattern))
end

for file in files
    rm(file)
end