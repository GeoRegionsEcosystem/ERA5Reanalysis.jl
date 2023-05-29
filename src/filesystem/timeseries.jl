"""
    e5danc(
        e5ds :: ERA5Hourly,
        evar :: ERA5Variable,
        ereg :: ERA5Region,
    ) -> String

Returns of the path of the file for the NASA Precipitation dataset specified by `npd` for a GeoRegion specified by `geo` at a date specified by `dt`.

Arguments
=========
- `npd` : a `NASAPrecipitationDataset` specifying the dataset details and date download range
- `geo` : a `GeoRegion` (see [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl)) that sets the geographic bounds of the data array in lon-lat
- `dt`  : A specified date. The NCDataset retrieved may will contain data for the date, although it may also contain data for other dates depending on the `NASAPrecipitationDataset` specified by `npd`
"""
function e5dtnc(
    e5ds :: Union{ERA5Hourly,ERA5Daily},
	evar :: SingleLevel,
	ereg :: ERA5Region,
)

    fol = joinpath(e5ds.path,ereg.string,evar.ID)
    fnc = e5ds.ID * "-" * "timeseries" * "-" * ereg.string * "-" * evar.ID * "-" * 
          yrmo2str(e5ds.start) * "_" * yrmo2str(e5ds.stop) * ".nc"
    return joinpath(fol,fnc)

end

function e5dtnc(
    e5ds :: Union{ERA5Hourly,ERA5Daily},
	evar :: PressureLevel,
	ereg :: ERA5Region,
)

    evp = evar.ID * "-$(evar.hPa)hPa"
    fol = joinpath(e5ds.path,ereg.string,evar.ID,evp)
    fnc = e5ds.ID * "-" * "timeseries" * "-" * ereg.string * "-" * evp * "-" * 
          yrmo2str(e5ds.start) * "_" * yrmo2str(e5ds.stop) * ".nc"
    return joinpath(fol,fnc)

end