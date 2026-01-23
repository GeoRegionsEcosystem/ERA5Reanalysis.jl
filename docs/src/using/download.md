# Downloading and Reading ERA5 Datasets

In this page we show how you can download and read data for a given ERA5 dataset.

### Setup
```@example download
using ERA5Reanalysis
using CairoMakie
using DelimitedFiles

download("https://raw.githubusercontent.com/natgeo-wong/GeoPlottingData/main/coastline_resl.txt","coast.cst")
coast = readdlm("coast.cst",comments=true)
clon  = coast[:,1]
clat  = coast[:,2]
nothing
```

## Required Dependencies

Since we are downloading from the Copernicus Climate Data Store (CDS), you are required to:
1. Register an account at the [Climate Data Store](https://cds.climate.copernicus.eu/)
2. Obtain your API key from the [CDS API How-To](https://cds.climate.copernicus.eu/api-how-to) page
3. Set up your API key using `addCDSAPIkey()`

If this sounds complicated, fear not! You need only perform the first two steps yourself. Once you have your API key, you can use the function `addCDSAPIkey()` to set it up:

```julia
addCDSAPIkey("<your-api-key-here>")
```

See the [Setup](../setup.md) page for more details.

## Downloading `ERA5Dataset`s

Downloading ERA5 data is as simple as:
```julia
e5ds = ERA5Dataset(args...)
evar = ERA5Variable(args...)
ereg = ERA5Region(args...)
download(e5ds, evar, ereg)
```

Let us download the `ERA5Monthly` Dataset for 2020 over Southeast Asia, for example:

```@example download
e5ds = ERA5Monthly(start=Date(2020),stop=Date(2020),path=pwd())
evar = SingleVariable("t2m")
geo  = GeoRegion("AR6_SEA")
ereg = ERA5Region(geo)
# download(e5ds, evar, ereg)  # Uncomment to actually download
nothing
```

## Reading Downloaded Data

After downloading, you can use the function `read()` to access the downloaded data as an `NCDataset`:

```@example download
# ds = read(e5ds, evar, ereg, Date(2020))
nothing
```

## Downloading Single-Level Variables

The following is the most basic download example for a single-level variable:

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015))
evar = SingleVariable("t2m")
ereg = ERA5Region(GeoRegion("AR6_SEA"))
download(e5ds, evar, ereg)
```

## Downloading Pressure-Level Variables

The following downloads pressure-level data between 500 hPa and 600 hPa. Note that we must specify the pressure range:

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015))
evar = PressureVariable("cc")
ereg = ERA5Region(GeoRegion("AR6_SEA"))
download(e5ds, evar, ereg, pall=true, ptop=500, pbot=600)
```

## Where is the Data Saved?

You can check where the data is saved for a given dataset, variable, region and datetime. The data is organized in a systematic directory structure based on:
* Dataset type (hourly, monthly, etc.)
* Variable ID
* Region ID
* Year and month

## TL;DR

The backend download functionality of ERA5Reanalysis.jl is based upon [CDSAPI.jl](https://github.com/JuliaClimate/CDSAPI.jl), but with the following extensions:
* Eliminates the need to know the CDSAPI syntax for the frontend - all you need is to specify the Dataset, Variable and Region of interest
* Extracts and places the downloaded data in a patterned, organized and systematic manner for easy retrieval
* More detailed and organized logging information during the downloading process similar to the python version of CDSAPI
* Allowing for repeated (up to 20) attempts at downloading a specific set of data

However, the download functionality of ERA5Reanalysis.jl is also limited in several ways:
* It currently only is able to download the `reanalysis` data, not ensemble members
* It currently is unable to retrieve any dataset outside the ERA5 Reanalysis datasets, including ERA5-Land data
* It is not possible to specify multiple Pressure-Level variables for download in the same manner as Single-Level variables

## API

```@docs
addCDSAPIkey
ERA5Reanalysis.download(
    e5ds :: Union{ERA5Hourly,ERA5Monthly},
    evar :: SingleVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    overwrite :: Bool = false
)
ERA5Reanalysis.download(
    e5ds :: Union{ERA5Hourly,ERA5Monthly},
    evar :: Vector{SingleVariable},
    ereg :: ERA5Region;
    overwrite :: Bool = false
)
ERA5Reanalysis.download(
    e5ds :: Union{ERA5Hourly,ERA5Monthly},
    evar :: PressureVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    pall :: Bool = false,
    ptop :: Int = 0,
    pbot :: Int = 0,
    pvec :: Vector{Int} = [0],
    overwrite :: Bool = false
)
```
