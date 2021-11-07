# Extract Gridded Information for an `ERA5Region`

Let's say that we have data on a rectilinear lon-lat grid, as ERA5 data tends to have.  How do we extract the data for the relevant region?  How do we do this for regions that are non-rectilinear in shape?  To solve these problems, we introduce the `RegionGrid` type, which contains information that:
* allows for the extraction of data for a subregion from a parent, larger region
* is able to use a mask to extract data for a region's shape, if it is not rectilinear

```@docs
RegionGrid
ERA5RegionGrid(
    e5geo :: ERA5Region,
    lon   :: Vector{<:Real},
    lat   :: Vector{<:Real}
)
```