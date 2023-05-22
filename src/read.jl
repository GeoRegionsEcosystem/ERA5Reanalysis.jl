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
	evar :: ERA5Variable,
	egeo :: ERA5Region,
    dt   :: TimeType;
    analysis :: Bool = false,
    smooth   :: Bool = false,
    smoothlon  :: Real = 0,
    smoothlat  :: Real = 0,
    smoothtime :: Real = 0,
    quiet :: Bool = false
)

    enc = e5dfnc(e5ds,evar,egeo,dt)

    raw = true
    if analysis
        enc = e5danc(e5ds,evar,egeo,dt)
        raw = false
    end
    if smooth
        if iszero(smoothlon) && iszero(smoothlat) && iszero(smoothtime)
            error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
        end
        enc = e5dsmth(e5ds,evar,egeo,dt,smoothlon,smoothlat,smoothtime)
        raw = false
        analysis = false
    end

    if quiet
        disable_logging(Logging.Warn)
    end

    if raw
        if !isfile(enc)
            error("$(modulelog()) - The $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt does not exist at $(enc).  Check if files exist at $(e5ds.path) or download the files here")
        end
        @info "$(modulelog()) - Opening the $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt"
    end
    if analysis
        if !isfile(enc)
            error("$(modulelog()) - The annually analyzed $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt does not exist at $(enc).  Check if files exist at $(e5ds.path) or download the files here")
        end
        @info "$(modulelog()) - Opening the annually analyzed $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt"
    end
    if smooth
        if !isfile(enc)
            error("$(modulelog()) - The spatially smoothed ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt does not exist at $(enc).  Check if files exist at $(e5ds.path) or download the files here")
        end
        @info "$(modulelog()) - Opening the spatialtemporally smoothed ($(@sprintf("%.2f",smoothlon))ºx$(@sprintf("%.2f",smoothlat))º, $(@sprintf("%02d",smoothtime)) timesteps) $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion during Date $dt"
    end

    if quiet
        disable_logging(Logging.Debug)
    end

    flush(stderr)

    return NCDataset(enc)

end

function read(
	e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	egeo :: ERA5Region;
    compiled :: Bool = false,
    timeseries :: Bool = false,
    quiet :: Bool = false
)

    if compiled
        enc = e5dcnc(e5ds,evar,egeo)
    end
    if timeseries
        enc = e5dtnc(e5ds,evar,egeo)
        compiled = false
    end

    if quiet
        disable_logging(Logging.Warn)
    end
    
    if compiled
        if !isfile(enc)
            error("$(modulelog()) - The compiled $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion from $(year(e5ds.start)) to $(year(e5ds.stop)) does not exist at $(enc).  Check if files exist at $(e5ds.path) or download the files here")
        end
        @info "$(modulelog()) - Opening the compiled $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion from $(year(e5ds.start)) to $(year(e5ds.stop))"
    end
    if timeseries
        if !isfile(enc)
            error("$(modulelog()) - The domain-averaged timeseries $(e5ds.lname) Dataset for $(evar.vname) in the $(egeo.geoID) GeoRegion from $(year(e5ds.start)) to $(year(e5ds.stop)) does not exist at $(enc).  Check if files exist at $(e5ds.path) or download the files here")
        end
        @info "$(modulelog()) - Opening the domain-averaged timeseries $(e5ds.lname) NCDataset for $(evar.vname) in the $(egeo.geoID) GeoRegion from $(year(e5ds.start)) to $(year(e5ds.stop))"
    end

    if quiet
        disable_logging(Logging.Debug)
    end

    flush(stderr)

    eds = NCDataset(enc)
    
    if !timeseries
          return eds
    else; return eds, eds["time"][:]
    end

end