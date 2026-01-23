# Land-Sea Mask Datasets

ERA5Reanalysis.jl provides land-sea mask functionality that allows distinguishing between data points over land and ocean. This is built upon the [LandSea.jl](https://github.com/GeoRegionsEcosystem/LandSea.jl) package.

The land-sea mask is saved into a `LandSea` data type, which is defined as a subType of `LandSeaFlat` in LandSea.jl.

!!! info "Units for the Land-Sea Mask"
    For standardization purposes, ERA5Reanalysis.jl uses the following convention:

    0 represents fully ocean, while 1 represents fully land.

### Setup
```@example landsea
using ERA5Reanalysis
using DelimitedFiles
using CairoMakie

download("https://raw.githubusercontent.com/natgeo-wong/GeoPlottingData/main/coastline_resl.txt","coast.cst")
coast = readdlm("coast.cst",comments=true)
clon  = coast[:,1]
clat  = coast[:,2]
nothing
```

## Retrieving the Land-Sea Mask

First, we define an ERA5 dataset and the GeoRegion of interest.

```@example landsea
e5ds = ERA5Dummy()
geo  = RectRegion("JAV","GLB","Java",[-5.5,-9,115,105],savegeo=false)
ereg = ERA5Region(geo)
```

Then, we retrieve the ERA5 Reanalysis LandSea Dataset using `getLandSea()`:

```@example landsea
lsd = getLandSea(e5ds,ereg)
```

## Visualizing the Land-Sea Mask

```@example landsea
fig = Figure()
aspect = (maximum(lsd.lon)-minimum(lsd.lon))/(maximum(lsd.lat)-minimum(lsd.lat))

ax = Axis(
    fig[1,1],width=400,height=400/aspect,
    title="ERA5 Land-Sea Mask over Java",
    xlabel="Longitude / º",ylabel="Latitude / º",
    limits=(minimum(lsd.lon)-1,maximum(lsd.lon)+1,minimum(lsd.lat)-1,maximum(lsd.lat)+1)
)

contourf!(
    ax,lsd.lon,lsd.lat,lsd.lsm,colormap=:delta,
    levels=range(0,1,length=11)
)
lines!(ax,clon,clat,color=:black)

resize_to_layout!(fig)
fig
```

## LandSea Type

```@docs
ERA5Reanalysis.LandSea
```

## API

```@docs
ERA5Reanalysis.getLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region;
    save :: Bool = true,
    returnlsd :: Bool = true,
    smooth    :: Bool = false,
    σlon :: Int = 0,
    σlat :: Int = 0,
    iterations :: Int = 100,
    FT = Float64
)
```
