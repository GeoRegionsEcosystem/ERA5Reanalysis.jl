module ERA5Reanalysis

## Base Modules Used
using DelimitedFiles
using Logging
using Printf

## Modules Used
using HTTP
using JSON3
using LandSea
using PrettyTables
using RegionGrids
using Statistics
using Unitful
using UnitfulParsableString

import Base: show, read, split, download, rm, ==, !==, isequal
import GeoRegions: ==, !==, isequal
import RegionGrids: RegionGrid, extract, extract!
import LandSea: getLandSea

## Reexporting exported functions within these modules
using Reexport
@reexport using Dates
@reexport using GeoRegions
@reexport using NCDatasets
@reexport using GRIBDatasets

## Exporting the following functions:
export
        ERA5Dataset,
        ERA5CDStore, ERA5Hourly, ERA5Monthly,
        ERA5Custom, ERA5Daily,
        ERA5Dummy,

        ERA5Variable,
        SingleLevel,   SingleVariable,   SingleCustom,
        PressureLevel, PressureVariable, PressureCustom,
        listSingles,   isSingleID,   rmSingleID,   resetSingles,   tableSingles,
        listPressures, isPressureID, rmPressureID, resetPressures, tablePressures,
        resetERA5Variables, addERA5Variables, rmERA5Variable,  tableERA5Variables,

        ERA5Region,
        isinERA5Region, coordERA5Region, RegionGrid,

        LandSea,
        getLandSea, downloadLandSea,

        download, read, save, rm, is, dkrz,
        addCDSAPIkey,
        
        extract, analysis, timeseries, smoothing, hourly2daily, hourly2monthly,
        hourly2monthlyhour,

        era5Pressures



## Abstract SuperTypes
"""
    ERA5Dataset

Abstract supertype for ERA5 reanalysis datasets, with the following subtypes:

    ERA5CDStore <: ERA5Dataset
    ERA5Custom  <: ERA5Dataset
    ERA5Dummy   <: ERA5Dataset

All `ERA5Dataset` Types contain the following fields:
- `path` : The specified directory in which to save the data
- `emask` : The specified directory in which to save the `LandSea` dataset

All `ERA5CDStore` and `ERA5Custom` Types also contain the following additional fields:
- `ID` : The module ID, that also acts as a prefix to filenames
- `name` : The full name of the module
- `start` : The date for which downloads/analysis begins
- `stop` : The date for which downloads/analysis finishes
- `sldoi` : Single-Level DOI (N/A for ERA5Daily)
- `pldoi` : Pressure-Level DOI (N/A for ERA5Daily)
- `ptype` : Product type (N/A for ERA5Daily), set to `reanalysis`
"""
abstract type ERA5Dataset end

abstract type ERA5Custom <: ERA5Dataset end

abstract type ERA5CDStore <: ERA5Dataset end

"""
    ERA5Variable

Abstract supertype for ERA5 variables, with the following subtypes

    SingleLevel   <: ERA5Variable
    PressureLevel <: ERA5Variable

All `ERA5Variable` Types contain the following fields:
- `ID` : The variable ID, that is also the identifier in the NetCDF files
- `name` : The full-name of the variable
- `long` : The variable long-name, which is used to specify retrievals from CDS
- `dataset` : The full-name of the variable
- `units` : The units of the variable

All `PressureLevel` Types contain the following fields:
- `hPa` : The pressure level (in hPa) of the pressure-variable of interest
"""
abstract type ERA5Variable end

## ERA5Reanalysis.jl logging preface

modulelog() = "$(now()) - ERA5Reanalysis.jl"
eradir = joinpath(@__DIR__,".files")

function __init__()

    fcdsapi = joinpath(homedir(),".cdsapirc")
    if !isfile(fcdsapi)
        @warn "$(modulelog()) - No .cdsapirc file exists, please follow the instructions on the Climate Data Store to find your key and set up the .cdsapirc file using the function addCDSAPIkey() ..."
    end

end

## Including other files in the module

include("dataset/dataset.jl")
include("dataset/show.jl")

include("variable/common.jl")
include("variable/single.jl")
include("variable/pressure.jl")
include("variable/is.jl")
include("variable/remove.jl")
include("variable/tables.jl")
include("variable/show.jl")

include("region/region.jl")
include("region/functions.jl")
include("region/extract.jl")

include("landsea/landsea.jl")

include("downloads/cdsapi.jl")
include("downloads/downloads.jl")
include("downloads/cdsretrieve.jl")
include("downloads/pythonprint.jl")
include("downloads/split.jl")

include("dkrz/dkrz.jl")

include("hour2time/hour2day.jl")
include("hour2time/hour2month.jl")
include("hour2time/hour2monthhour.jl")

include("analysis/hourly.jl")
include("analysis/monthly.jl")

include("compile/hourly.jl")
include("compile/monthly.jl")

include("timeseries/hourly.jl")
include("timeseries/daily.jl")

include("smoothing.jl")

include("filesystem/raw.jl")
include("filesystem/analysis.jl")
include("filesystem/compile.jl")
include("filesystem/timeseries.jl")
include("filesystem/smooth.jl")

include("backend.jl")
include("read.jl")

include("save/define.jl")
include("save/hourly.jl")
include("save/daily.jl")
include("save/monthly.jl")

end
