# Loading and Saving Land-Sea Mask Datasets

The Land-Sea Dataset can be obtained using the function `getLandSea()`.  See end of the page for the API

### Setup

````@example landseamask
using ERA5Reanalysis
using DelimitedFiles
using CairoMakie

download("https://raw.githubusercontent.com/natgeo-wong/GeoPlottingData/main/coastline_resl.txt","coast.cst")
coast = readdlm("coast.cst",comments=true)
clon  = coast[:,1]
clat  = coast[:,2]
nothing
````

## Retrieving IMERG and TRMM Land-Sea Mask over Java

First, we must define the ERA5 datasets, and the GeoRegion of interest.
````@example landseamask
e5ds = ERA5Dummy()
geo  = RectRegion("JAV","GLB","Java",[-5.5,-9,115,105],savegeo=false)
egeo = ERA5Region(geo)
````

Then, we retrieve the ERA5 Reanalysis LandSea Dataset
````@example landseamask
# lsd = getLandSea(e5ds,egeo)
````

And we plot them below for comparison:
## API

```@docs
ERA5Reanalysis.getLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region = ERA5Region("GLB");
    save :: Bool = true,
    returnlsd :: Bool = true,
    smooth    :: Bool = false,
    σlon :: Int = 0,
    σlat :: Int = 0,
    iterations :: Int = 100,
    FT = Float64
)
```