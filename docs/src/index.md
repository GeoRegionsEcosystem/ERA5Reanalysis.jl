# [ERA5Reanalysis.jl](https://github.com/natgeo-wong/ERA5Reanalysis.jl)
*Managing ERA5 Reanalysis Datasets*

`ERA5Reanalysis.jl` is a Julia package that aims to streamline the following processes:
* downloads of ERA5 Datasets from the Climate Data Store (does not include MARS requests)
* basic analysis of said datasets
* perform all the above operations innately over a given geographical region using the [`GeoRegion`](https://github.com/JuliaClimate/GeoRegions.jl) functionality of GeoRegions.jl (v2 and above)

## Installation Instructions

ERA5Reanalysis.jl has not been officially registered as a Julia package yet.  To install it, add it directly using the GitHub link as follows:
```
julia> ]
(@v1.6) pkg> add https://github.com/natgeo-wong/ERA5Reanalysis.jl.git
```

## The Basic Components of ERA5Reanalysis.jl

There are three essential components to specifying an ERA5 reanalysis dataset:
1. The ERA5 dataset (hourly, monthly, month-by-hour, etc.), held in an [`ERA5Dataset`](components/datasets/index.md) supertype
2. The ERA5 variable (single-level, or pressure-level), held in the [`ERA5Variable`](components/variables/index.md) supertype
3. The ERA5 region to be downloaded/analyzed, held in an `ERA5Region` supertype, built over a `GeoRegion`

## Documentation Overview

The documentation for `ERA5Reanalysis.jl` is divided into three components:
1. Tutorials - meant to introduce the three key components of ERA5Reanalysis.jl:
    (a) `ERA5Dataset` Types that specify the ERA5 Dataset of interest
    (b) `ERA5Variable` Types that specifiy the Single- and Pressure-level Variables of interest
    (c) `ERA5Region` Type that specifies the Geographic Regions of interest
2. How-to Examples - geared towards those looking for specific examples of what can be done
3. API Reference - comprehensive summary of all exported functionalities

!!! tip "Obtaining Example Datasets"
    All the output for the coding examples were produced using my computer with key security information (such as login info) omitted.  The examples cannot be run online because the file size requirements are too big.  Copying and pasting the code examples (with relevant directory and login information changes) should produce the same results.

## Getting help
If you are interested in using `ERA5Reanalysis.jl` or are trying to figure out how to use it, please feel free to ask me questions and get in touch!  Please feel free to [open an issue](https://github.com/natgeo-wong/ERA5Reanalysis.jl/issues/new) if you have any questions, comments, suggestions, etc!