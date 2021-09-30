# What is an `ERA5Region` and why do we need it?

By default, ERA5Reanalysis.jl will conduct downloads, or analyse data over, the entire globe.  However, most of the time we would rather perform these tasks over specified regions of interest.  In ERA5Reanalysis, we do this by specifying an `ERA5Region`, which is built on top of the `GeoRegion` functionality in [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl).

```@docs
ERA5Region
```