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
        ERA5Dataset, ERA5Variable, ERA5Region,
        ERA5Hourly, ERA5Monthly, ERA5MonthlyHour,
        SingleVariable,   SingleCustom,   listSingles,   isSingle,
        PressureVariable, PressureCustom, listPressures, isPressure,
        resetERA5Variables, addERA5Variables



## Abstract SuperTypes
"""
    ERA5Dataset

Abstract supertype for ERA5 datasets.
"""
abstract type ERA5Dataset end

"""
    ERA5Variable

Abstract supertype for ERA5 variables.
"""
abstract type ERA5Variable end

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

end
