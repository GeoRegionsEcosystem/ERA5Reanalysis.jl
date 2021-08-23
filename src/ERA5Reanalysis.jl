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
        ERA5Dataset

## Abstract types
"""
    ERA5Dataset

Abstract supertype for ERA5 datasets.
"""
abstract type ERA5Dataset end

"""
    RectRegion{ST<:AbstractString, FT<:Real} <: GeoRegion

Structure containing information on a rectilinear (i.e. rectangular shape on a lon-lat grid) region `regID`, with parent ID `parID`, name `name`, and bounds `N`, `S`, `E`, `W`.

If `W` < 0º, then `is180` is true, and if `E` > 180, then `is360` is true.  Both `is180` and `is360` can simultaneously true, but they cannot both be false.
"""
# struct MonthlySinglelevel{ST<:AbstractString, FT<:Real} <: ERA5Dataset
#     emod  :: ERA5Module{ST,FT}
#     evar  :: ERA5Single{ST,FT}
#     egeo  :: GeoRegion{ST,FT}
#     egrid :: RegionGrid{FT}
#     etime :: ERA5Time{DT}
# end

## Including other files in the module
# include("cdsapi.jl")
# include("module.jl")
# include("variable.jl")
# include("region.jl")
# include("time.jl")

end
