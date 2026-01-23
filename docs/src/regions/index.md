# An Introduction to `ERA5Region`s

## What is an `ERA5Region` and why do we need it?

By default, ERA5Reanalysis.jl will conduct downloads, or analyse data over, the entire globe. However, most of the time we would rather perform these tasks over specified regions of interest. In ERA5Reanalysis, we do this by specifying an `ERA5Region`, which is built on top of the `GeoRegion` functionality in [GeoRegions.jl](https://github.com/GeoRegionsEcosystem/GeoRegions.jl).

!!! note "Why not just use `GeoRegion`s directly?"
    The functionality of `ERA5Region`s and the basic manipulations are very similar to those of `GeoRegion`s. However, in ERA5Reanalysis.jl, we must additionally specify the resolution of the data that needs to be downloaded and/or analyzed, and therefore we build an `ERA5Region` as a container of a `GeoRegion`.

### Setup
```@example regions
using ERA5Reanalysis
```

## The `ERA5Region` Type

```@docs
ERA5Region{ST<:AbstractString, FT<:Real}
```

The package GeoRegions.jl is automatically reexported by ERA5Reanalysis.jl, so one can define or retrieve a `GeoRegion` and its information directly without needing to explicitly call GeoRegions.jl in the REPL. Once a `GeoRegion` has been retrieved, we can use it to define an `ERA5Region`, which will also contain information on the horizontal resolution at which the dataset will be downloaded/analyzed.

```@docs
ERA5Region(
    geo  :: GeoRegion;
    resolution :: Real,
    ST = String,
    FT = Float64
)
```

## Basic Examples

Here, we define `ERA5Region`s that cover the same domain based on the same `GeoRegion`, but using different spatial resolution.

```@example regions
geo = GeoRegion("AR6_SEA")
```

Default resolution (0.25°):
```@example regions
ereg1 = ERA5Region(geo)
```

Custom resolution (1.0°):
```@example regions
ereg2 = ERA5Region(geo, resolution=1.0)
```

!!! warning "Valid Resolutions"
    The resolution must be a value such that 360 is a multiple of `resolution`. For example, `resolution = 1.3` is not valid because 360 is not divisible by 1.3.

```@example regions
ereg3 = ERA5Region(geo, resolution=1.3)
```
