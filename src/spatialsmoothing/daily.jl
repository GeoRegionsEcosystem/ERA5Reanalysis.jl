function smooth(
    e5ds :: ERA5Daily,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    smooth :: Real = 0,
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    verbose :: Bool = false
)

    if iszero(smooth) && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if iszero(smoothlon); smoothlon = smooth end
    if iszero(smoothlat); smoothlat = smooth end

    gres = ereg.gres
    shiftlon = Int(floor(smoothlon/(2*gres)))
    shiftlat = Int(floor(smoothlat/(2*gres)))

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload  = zeros(Int16,nlon,nlat,31)
    tmpdata  = zeros(nlon,nlat,31)
    shfttmp  = zeros(nlon,nlat,(2*shiftlon+1)*(2*shiftlat+1))
    smthdata = zeros(nlon,nlat,31)
    shftnan  = zeros(Bool,(2*shiftlon+1)*(2*shiftlat+1))

    for dt in e5ds.start : Month(1) : e5ds.stop

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        ndy = daysinmonth(dt)
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:ndy),:,:,:)
        int2real!(
            view(tmpdata,:,:,1:ndy), view(tmpload,:,:,1:ndy),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        for idy = 1 : ndy
            ishift = 0
            for ishiftlat = -shiftlat : shiftlat, ishiftlon = -shiftlon : shiftlon
                ishift += 1
                circshift!(view(shfttmp,:,:,ishift),view(tmpdata,:,:,idy),(ishiftlon,ishiftlat))
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                if !isnan(tmpdata[ilon,ilat,idy])
                      smthdata[ilon,ilat,idy] = nanmean(view(shfttmp,ilon,ilat,:),shftnan)
                else; smthdata[ilon,ilat,idy] = NaN
                end
            end
        end

        if verbose
            @info "$(modulelog()) - Setting edges to NaN because we used cyclical circshift to do spatial smoothing, which doesn't make sense if boundaries are not periodic ..."
        end
        if !iszero(shiftlon) && !ereg.is360
            for idy = 1 : ndy, ilat = 1 : nlat, ilon = 1 : shiftlon
                smthdata[ilon,ilat,idy] = NaN
            end
            for idy = 1 : ndy, ilat = 1 : nlat, ilon = (nlon-shiftlon+1) : nlon
                smthdata[ilon,ilat,idy] = NaN
            end
        end
        if !iszero(shiftlat)
            for idy = 1 : ndy, ilat = 1 : shiftlat, ilon = 1 : nlon
                smthdata[ilon,ilat,idy] = NaN
            end
            for idy = 1 : ndy, ilat = (nlat-shiftlat+1) : nlat, ilon = 1 : nlon
                smthdata[ilon,ilat,idy] = NaN
            end
        end

        save(
            view(smthdata,:,:,1:ndy), dt, e5ds, evar, ereg, lsd,
            smooth=true,smoothlon=smoothlon,smoothlat=smoothlat
        )

    end

end

function save_smooth(
    dayts :: AbstractArray{<:Real,3},
    e5ds  :: ERA5Daily,
    evar  :: ERA5Variable,
    ereg  :: ERA5Region,
    lsd   :: LandSea,
    date  :: TimeType,
    smoothlon :: Real,
    smoothlat :: Real
)

    @info "$(modulelog()) - Saving spatially smoothed ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) daily $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) ..."

    fnc = e5dsmth(e5ds,evar,ereg,date,smoothlon,smoothlat)
    fol = dirname(fnc); if !isdir(fol); mkpath(fol) end
    if isfile(fnc)
        @info "$(modulelog()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end
    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(Dates.now()) with ERA5Reanalysis.jl",
        "comments"    => "ERA5Reanalysis.jl creates NetCDF files in the same format that data is saved on the Climate Data Store"
    ))

    if typeof(evar) <: SingleVariable
        ds.attrib["doi"] = e5ds.sldoi
    elseif typeof(evar) <: PressureVariable
        ds.attrib["doi"] = e5ds.pldoi
    end

    ndy = size(dayts,3)
    ds.dim["time"] = ndy
    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "days since $(date) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncday = defVar(ds,"$(evar.varID)",Float64,("longitude","latitude","time",),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
    ))
    
    nclon[:] = lsd.lon
    nclat[:] = lsd.lat
    nctime[:] = collect(1:ndy) .- 1
    ncday[:] = dayts

    close(ds)

    @info "$(modulelog()) - Spatially smoothed ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) daily $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) has been saved into $(fnc)."

end