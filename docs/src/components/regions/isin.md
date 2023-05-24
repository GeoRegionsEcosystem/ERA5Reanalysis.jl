# Are Points / GeoRegions in an `ERA5Region`?

When dealing with geographic data, we often wish to check if a point or region is inside another region.  In ERA5Reanalysis, we build upon the functionality of GeoRegions.jl with the wrapper `isinERA5Region()`, so you can perform this check easily without needing to perform and extra step and extract the `GeoRegion` from the `ERA5Region`.

!!! note "Point Type"
    We use the `Point2` Type from the package GeometryBasics.jl, which is reexported by ERA5Reanalysis.jl, as an easy way to denote points.  This also allows us to use the package PolygonOps.jl to determine if a point is inside a region.

```@docs
isinERA5Region
```

