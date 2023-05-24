# An Overview of the Download Functionality

The download functionality of ERA5Reanalysis.jl is built upon a Julia version of the CDSAPI (see [here](https://cds.climate.copernicus.eu/api-how-to) and [here](https://github.com/JuliaClimate/CDSAPI.jl)).  In ERA5Reanalysis.jl, downloading a dataset can be as easy as `download(ERA5Dataset,ERA5Variable,ERA5Region)`.

See below for the different methods.  Note that downloading a `PressureVariable` is a bit more complicated and involved than downloading a `SingleVariable` because we need to also specify the range of pressures to download the data from the CDS when a `PressureVariable` is chosen.

```@docs
ERA5Reanalysis.download(
    e5ds :: Union{ERA5Hourly,ERA5Monthly},
    evar :: SingleVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    overwrite :: Bool = false
)
```

Text

```@docs
ERA5Reanalysis.download(
    e5ds :: Union{ERA5Hourly,ERA5Monthly},
    evar :: Vector{SingleVariable},
    ereg :: ERA5Region;
    overwrite :: Bool = false
)
```

Text

```@docs
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

## TL;DR

The backend download functionality of ERA5Reanalysis.jl are based upon the build of (https://github.com/JuliaClimate/CDSAPI.jl)[CDSAPI.jl], but with the following extensions:
* Eliminates the need to know the CDSAPI syntax for the frontend - all you need is to specify the Dataset, Variable and Region of interest
* Extracts and places the downloaded data in a patterned, organized and systematic manner for easy retrieval
* More detailed and organized logging information during the downloading process similar to the python version of CDSAPI
* Allowing for repeated (up to 20) attempts at downloading a specific set of data

However, the download functionality of ERA5Reanalysis.jl is also limited in several ways:
* It currently only is able to download the `reanalysis` data, not ensemble members
* It currently is unable to retrieve any dataset outside the ERA5 Reanalysis datasets, including ERA5-Land data
* It is not possible to specify multiple Pressure-Level variables for download in the same manner as Single-Level variables