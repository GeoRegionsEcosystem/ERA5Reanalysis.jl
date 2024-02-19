# An Overview of the Download Functionality

The download functionality of ERA5Reanalysis.jl is built upon a Julia version of the CDSAPI (see [here](https://cds.climate.copernicus.eu/api-how-to) and [here](https://github.com/JuliaClimate/CDSAPI.jl)).  In ERA5Reanalysis.jl, downloading a dataset can be as easy as

```
download(
    <ERA5Dataset>,
    <ERA5Variable>,
    <ERA5Region>,
    kwargs...
)
```

See below for the different examples and methods.  Note that downloading a `PressureVariable` is a bit more complicated and involved than downloading a `SingleVariable` because we need to also specify the range of pressures to download the data from the CDS when a `PressureVariable` is chosen.

## Setting up the CDSAPI Key

In order for your downloads to work with ERA5Reanalysis, you first need to set up your CDSAPI key.  To do this, you must first register with the [Climate Data Store](https://cds.climate.copernicus.eu/) in order to obtain your key [here](https://cds.climate.copernicus.eu/api-how-to).

Then, you can either follow the instructions above in the API-how-to, or you can simply use the function `addCDSAPIkey()` to do it for you if you don't want to fiddle around with hidden files and the like.

So, example

```@repl
using ERA5Reanalysis
ckeys = ERA5Reanalysis.cdskey()
addCDSAPIkey("<your-key-here>")
```

See the API below for more details.

## Examples

The following is the most basic download example

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015))
evar = SingleVariable("t2m")
egeo = ERA5Region("AR6_SEA")
download(e5ds,evar,egeo)
```

The following downloads pressure-level data between 500 hPa and 600 hPa (note, we must specify that the keyword argument `pall` is `true`.)

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015))
evar = PressureVariable("cc")
egeo = ERA5Region("AR6_SEA")
download(e5ds,evar,egeo,pall=true,ptop=500,pbot=600)
```

## TL;DR

The backend download functionality of ERA5Reanalysis.jl are based upon the build of [CDSAPI.jl](https://github.com/JuliaClimate/CDSAPI.jl), but with the following extensions:
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