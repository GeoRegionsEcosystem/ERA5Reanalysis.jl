"""
    e5danc(
        e5ds :: ERA5Hourly,
        evar :: ERA5Variable,
        ereg :: ERA5Region,
        dt   :: TimeType
    ) -> String

Returns of the path of the file for the NASA Precipitation dataset specified by `npd` for a GeoRegion specified by `geo` at a date specified by `dt`.

Arguments
=========
- `npd` : a `NASAPrecipitationDataset` specifying the dataset details and date download range
- `geo` : a `GeoRegion` (see [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl)) that sets the geographic bounds of the data array in lon-lat
- `dt`  : A specified date. The NCDataset retrieved may will contain data for the date, although it may also contain data for other dates depending on the `NASAPrecipitationDataset` specified by `npd`
"""
function e5danc(
    e5ds :: ERA5Hourly,
	evar :: SingleLevel,
	ereg :: ERA5Region,
    dt   :: TimeType
)

    fol = joinpath(e5ds.path,ereg.string,evar.varID)
    fnc = e5ds.e5dID * "-" * ereg.string * "-" * evar.varID * "-" * yr2str(dt) * ".nc"
    return joinpath(fol,fnc)

end

function e5danc(
    e5ds :: ERA5Hourly,
	evar :: PressureLevel,
	ereg :: ERA5Region,
    dt   :: TimeType
)

    evp = evar.varID * "-$(evar.hPa)hPa"
    fol = joinpath(e5ds.path,ereg.string,evar.varID,evp)
    fnc = e5ds.e5dID * "-" * ereg.string * "-" * evp * "-" * yr2str(dt) * ".nc"
    return joinpath(fol,fnc)

end

function e5danc(
    e5ds :: ERA5Hourly,
	evar :: SingleLevel,
	ereg :: ERA5Region
)

    fol = joinpath(e5ds.path,ereg.string,evar.varID)
    fnc = e5ds.e5dID * "-" * ereg.string * "-" * evar.varID
    return fol, fnc

end

function e5danc(
    e5ds :: ERA5Hourly,
	evar :: PressureLevel,
	ereg :: ERA5Region
)

    evp = evar.varID * "-$(evar.hPa)hPa"
    fol = joinpath(e5ds.path,ereg.string,evar.varID,evp)
    fnc = e5ds.e5dID * "-" * ereg.string * "-" * evp
    return fol, fnc

end