module ERA5Reanalysis

## Base Modules Used
using Base64
using DelimitedFiles
using Logging
using Printf

## Modules Used
using HTTP
using JSON
using NCDatasets
using PrettyTables
using Statistics

## Reexporting exported functions within these modules
using Reexport
@reexport using Dates
@reexport using GeoRegions

import Base: show, read

## Exporting the following functions:
export
        ERA5Module, ERA5Hourly, ERA5Monthly, ERA5MonthlyHour,

        ERA5Variable, SingleVariable, SingleCustom, PressureVariable, PressureCustom,
        listSingles,   isSingle,   rmSingle,   resetSingles,
        listPressures, isPressure, rmPressure, resetPressures,
        resetERA5Variables, addERA5Variables, rmERA5Variable,

        ERA5Region



## Abstract SuperTypes
"""
    ERA5Module

Abstract supertype for ERA5 dataset modules.

All `ERA5Module` Types contain the following fields:
- `modID` : The module ID, that also acts as a prefix to filenames
- `eroot` : The specified directory in which to save the data
- `dtbeg` : The date for which downloads/analysis begins
- `dtend` : The date for which downloads/analysis finishes

!!! note
    The `ERA5MonthlyHour` subType also has the field `hours` that specifies the hour(s) of day for which monthly data is downloaded
"""
abstract type ERA5Module end

"""
    ERA5Variable

Abstract supertype for ERA5 variables.

All `ERA5Variable` Types contain the following fields:
- `varID` : The variable ID, that is also the identifier in the NetCDF files
- `lname` : The variable long-name, which is used to specify retrievals from CDS
- `vname` : The full-name of the variable
- `units` : The units of the variable
"""
abstract type ERA5Variable end

## ERA5Reanalysis.jl logging preface

modulelog() = "$(now()) - ERA5Reanalysis.jl"

## Including other files in the module

include("module/module.jl")
include("module/show.jl")

include("variable/common.jl")
include("variable/single.jl")
include("variable/pressure.jl")
include("variable/show.jl")

include("region/region.jl")

include("downloads/cdsapi.jl")
include("downloads/downloads.jl")
include("downloads/cdsretrieve.jl")
include("downloads/pythonprint.jl")

end
