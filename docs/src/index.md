```@raw html
---
layout: home

hero:
  name: "ERA5Reanalysis.jl"
  text: "Managing ERA5 Reanalysis Datasets"
  tagline: Download, extract and manipulate ERA5 Reanalysis datasets from the Climate Data Store in Julia.
  image:
    src: /logo.png
    alt: ERA5Reanalysis
  actions:
    - theme: brand
      text: Getting Started
      link: /basics
    - theme: alt
      text: Datasets
      link: /datasets/intro
    - theme: alt
      text: Tutorials
      link: /using/download
    - theme: alt
      text: View on Github
      link: https://github.com/GeoRegionsEcosystem/ERA5Reanalysis.jl

features:
  - title: Simple and Intuitive
    details: ERA5Reanalysis aims to be simple and intuitive to the user, with basic functions like `download()` and `read()`.
  - title: Region of Interest
    details: You don't have to download the global dataset, only for your (Geo)Region of interest, saving you time and disk space for small domains.
  - title: Comprehensive
    details: ERA5Reanalysis.jl supports hourly, daily, and monthly ERA5 products for both single-level and pressure-level variables.
---
```

## Introduction

ERA5Reanalysis.jl builds upon the [GeoRegions Ecosystem](https://github.com/GeoRegionsEcosystem) to streamline the following processes:
* downloads of ERA5 Reanalysis datasets from the Climate Data Store (CDS)
* basic analysis of said datasets
* perform all the above operations innately over a given geographical region using the [GeoRegions.jl](https://github.com/GeoRegionsEcosystem/GeoRegions.jl) package

## Installation Instructions

The latest version of ERA5Reanalysis.jl can be installed using the Julia package manager (accessed by pressing `]` in the Julia command prompt)
```julia-repl
julia> ]
(@v1.10) pkg> add ERA5Reanalysis
```

You can update `ERA5Reanalysis.jl` to the latest version using
```julia-repl
(@v1.10) pkg> update ERA5Reanalysis
```

And if you want to get the latest release without waiting for me to update the Julia Registry (although this generally isn't necessary since I make a point to release patch versions as soon as I find bugs or add new working features), you may fix the version to the `main` branch of the GitHub repository:
```julia-repl
(@v1.10) pkg> add ERA5Reanalysis#main
```

## Getting help
If you are interested in using `ERA5Reanalysis.jl` or are trying to figure out how to use it, please feel free to ask me questions and get in touch!  Please feel free to [open an issue](https://github.com/GeoRegionsEcosystem/ERA5Reanalysis.jl/issues/new) if you have any questions, comments, suggestions, etc!
