"""
    e5danc(
        e5ds :: ERA5Hourly,
        evar :: ERA5Variable,
        egeo :: ERA5Region,
        dt   :: TimeType
    ) -> String

Returns of the path of the file for the NASA Precipitation dataset specified by `npd` for a GeoRegion specified by `geo` at a date specified by `dt`.

Arguments
=========
- `npd` : a `NASAPrecipitationDataset` specifying the dataset details and date download range
- `geo` : a `GeoRegion` (see [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl)) that sets the geographic bounds of the data array in lon-lat
- `dt`  : A specified date. The NCDataset retrieved may will contain data for the date, although it may also contain data for other dates depending on the `NASAPrecipitationDataset` specified by `npd`
"""
function e5dsmth(
    e5ds :: ERA5Dataset,
	evar :: SingleLevel,
	egeo :: ERA5Region,
    dt   :: TimeType,
    smoothlon  :: Real,
    smoothlat  :: Real,
    smoothtime :: Int
)

    dts = yr2str(dt)
    fol = joinpath(e5ds.path,egeo.gstr,evar.varID,dts)
    fnc = e5ds.e5dID * "-" * egeo.gstr * "-" * "smooth" * "_" *
          @sprintf("%.2f",smoothlon) * "x" * @sprintf("%.2f",smoothlat) *
          "_" * @sprintf("%02d",smoothtime) * "steps" *
          "-" * evar.varID * "-" * yrmo2str(dt) * ".nc"
    return joinpath(fol,fnc)

end

function e5dsmth(
    e5ds :: ERA5Dataset,
	evar :: PressureLevel,
	egeo :: ERA5Region,
    dt   :: TimeType,
    smoothlon :: Real,
    smoothlat :: Real,
    smoothtime :: Int
)

    evp = evar.varID * "-$(evar.hPa)hPa"
    dts = yr2str(dt)
    fol = joinpath(e5ds.path,egeo.gstr,evar.varID,dts)
    fnc = e5ds.e5dID * "-" * egeo.gstr * "-" * "smooth" * "_" *
          @sprintf("%.2f",smoothlon) * "x" * @sprintf("%.2f",smoothlat) *
          "_" * @sprintf("%02d",smoothtime) * "steps" *
          "-" * evp * "-" * yrmo2str(dt) * ".nc"
    return joinpath(fol,fnc)

end