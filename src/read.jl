"""
    read(
        npd :: NASAPrecipitationDataset,
        geo :: GeoRegion,
        dt  :: TimeType;
        lonlat :: Bool = false
    ) -> NCDataset           (if lonlat = false)
      -> lon, lat, NCDataset (if lonlat = true)

Reads a NASA Precipitation dataset specified by `npd` for a GeoRegion specified by `geo` at a date specified by `dt`.

Arguments
=========
- `e5ds` : a `NASAPrecipitationDataset` specifying the dataset details and date download range
- `egeo` : a `GeoRegion` (see [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl)) that sets the geographic bounds of the data array in lon-lat
- `dt`   : A specified date. The NCDataset retrieved may will contain data for the date, although it may also contain data for other dates depending on the `NASAPrecipitationDataset` specified by `npd`

Keyword Arguments
=================
- `lonlat` : if `true`, then return the longitude and latitude vectors for the dataset. Otherwise only the NCDataset type will be returned.
"""
function read(
	e5ds :: ERA5Dataset,
	evar :: SingleVariable,
	egeo :: ERA5Region,
    dt   :: TimeType;
    lonlat :: Bool = false
)

    enc = e5dfnc(e5ds,evar,egeo,dt)
    if !isfile(enc)
        error("$(modulelog()) - The $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt does not exist at $(enc).  Check if files exist at $(e5ds.eroot) or download the files here")
    end
    @info "$(modulelog()) - Opening the $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt"
    eds = NCDataset(enc)
    
    if !lonlat
          return eds
    else; return eds, eds["longitude"][:], eds["latitude"][:]
    end

end

function read(
	e5ds :: ERA5Dataset,
	evar :: PressureVariable,
	egeo :: ERA5Region,
    dt   :: TimeType;
    lonlat :: Bool = false
)

    enc = e5dfnc(e5ds,evar,egeo,dt)
    if !isfile(enc)
        error("$(modulelog()) - The $(e5ds.lname) Dataset for $(evar.vname) at the $(evar.hPa)hPa Pressure Level in the $(egeo.geoID) GeoRegion during Date $dt does not exist at $(enc).  Check if files exist at $(e5ds.eroot) or download the files here")
    end
    @info "$(modulelog()) - Opening the $(e5ds.lname) NCDataset for $(evar.vname) at the $(evar.hPa)hPa Pressure Level in the $(egeo.geoID) GeoRegion during Date $dt"
    eds = NCDataset(enc)
    
    if !lonlat
          return eds
    else; return eds, eds["longitude"][:], eds["latitude"][:]
    end

end