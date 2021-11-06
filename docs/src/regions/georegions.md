# Basic Manipulation of `ERA5Region`s

Here, we discuss some of the functions used in ERA5Reanalysis.jl to wrap around GeoRegions.jl functionality, such that `ERA5Region`s can be directly manipulated.

## Are Points / GeoRegions in an `ERA5Region`?

To test if a point, or a `GeoRegion`, is in a given `ERA5Region`, we use the `isinERA5Region()` function.

```@docs
isinERA5Region
```

## Extract Gridded Information for an `ERA5Region`

```@docs
RegionGrid
```