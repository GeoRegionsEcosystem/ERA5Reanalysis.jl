module ERA5Reanalysis

## Base Modules Used
using Base64
using Dates
using DelimitedFiles
using Logging
using Printf

## Modules Used
using GeoRegions
using HTTP
using JSON
using NCDatasets
using Statistics

import Base: show, read

## Exporting the following functions:
export
        ERA5Dataset, ERA5Variable,
        SingleVariable,   SingleCustom,   listSingle,   isSingle,
        PressureVariable, PressureCustom, listPressure, isPressure,
        resetERA5Variables, addERA5Variables



## Abstract types
"""
    ERA5Dataset

Abstract supertype for ERA5 datasets.
"""
abstract type ERA5Dataset end

""""
ERA5Dataset

Abstract supertype for ERA5 datasets.
"""
abstract type ERA5Variable end

## Including other files in the module
include("cdsapi.jl")

include("variable/common.jl")
include("variable/single.jl")
include("variable/pressure.jl")

# include("region.jl")

# include("time.jl")

end
