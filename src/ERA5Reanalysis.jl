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
@reexport using NCDatasets: nomissing

import Base: show, read, download, split
import GeoRegions: getLandSea

## Exporting the following functions:
export
        ERA5Dataset, ERA5Hourly, ERA5Daily, ERA5Monthly,

        ERA5Variable,
        SingleLevel,   SingleVariable,   SingleCustom,
        PressureLevel, PressureVariable, PressureCustom,
        listSingles,   isSingle,   rmSingle,   resetSingles,   tableSingles,
        listPressures, isPressure, rmPressure, resetPressures, tablePressures,
        resetERA5Variables, addERA5Variables, rmERA5Variable,  tableERA5Variables,

        ERA5Region,
        isinERA5Region, coordERA5Region, ERA5RegionGrid,

        LandSea,
        getLandSea, downloadLandSea,

        download, read, save, extract, analysis, timeseries, smooth,
        
        hourly2daily, hourly2monthly, hourly2monthlyhour,

        era5Pressures



## Abstract SuperTypes
"""
    ERA5Dataset

Abstract supertype for ERA5 reanalysis datasets.

All `ERA5Dataset` Types contain the following fields:
- `e5dID` : The module ID, that also acts as a prefix to filenames
- `eroot` : The specified directory in which to save the data
- `start` : The date for which downloads/analysis begins
- `stop`  : The date for which downloads/analysis finishes
- `dtext` : Is it the preliminary back extension from 1950-1978?

!!! note
    The `ERA5MonthlyHour` subType also has the field `hours` that specifies the hour(s) of day for which monthly data is downloaded
"""
abstract type ERA5Dataset end

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

function __init__()
    jfol = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis"); mkpath(jfol);
    fvar = ["singlevariable.txt","singlecustom.txt","pressurevariable.txt","pressurecustom.txt"]
    for fname in fvar
        if !isfile(joinpath(jfol,fname))
            copyera5variables(fname)
            @info "$(modulelog()) - $(fname) does not exist in $(jfol), copying ..."
        end
    end
end

## Including other files in the module

include("dataset/dataset.jl")
include("dataset/show.jl")

include("variable/common.jl")
include("variable/single.jl")
include("variable/pressure.jl")
include("variable/show.jl")

include("region/region.jl")
include("region/functions.jl")

include("landsea/landsea.jl")

include("downloads/cdsapi.jl")
include("downloads/downloads.jl")
include("downloads/cdsretrieve.jl")
include("downloads/pythonprint.jl")
include("downloads/split.jl")

include("hour2time/hour2day.jl")

include("analysis/hourly.jl")
include("analysis/monthly.jl")

include("compile/hourly.jl")
include("compile/monthly.jl")

include("timeseries/hourly.jl")
include("timeseries/daily.jl")

include("spatialsmoothing/daily.jl")

include("subregion/extract.jl")

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
include("save/extract.jl")

end
