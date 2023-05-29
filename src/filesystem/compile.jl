"""
    e5dcnc(
        e5ds :: ERA5Dataset,
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
function e5dcnc(
    e5ds :: ERA5Dataset,
	evar :: SingleLevel,
	ereg :: ERA5Region,
)
    yrs = yr2str(e5ds.start) * "_" * yr2str(e5ds.stop)
    fol = joinpath(e5ds.path,ereg.string,evar.ID)
    fnc = e5ds.ID * "-" * ereg.string * "-" * evar.ID * "-" * yrs * ".nc"
    return joinpath(fol,fnc)

end

function e5dcnc(
    e5ds :: ERA5Dataset,
	evar :: PressureLevel,
	ereg :: ERA5Region,
)

    yrs = yr2str(e5ds.start) * "_" * yr2str(e5ds.stop)
    evp = evar.ID * "-$(evar.hPa)hPa"
    fol = joinpath(e5ds.path,ereg.string,evar.ID,evp)
    fnc = e5ds.ID * "-" * ereg.string * "-" * evp * "-" * yrs * ".nc"
    return joinpath(fol,fnc)

end