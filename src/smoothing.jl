function smoothing(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    spatial :: Real = 0,
    hours :: Int,
    spatiallon :: Real = 0,
    spatiallat :: Real = 0,
    verbose :: Bool = false
)

    if iszero(spatial) && (iszero(spatiallon) && iszero(spatiallat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if hours > 720
        error("$(modulelog()) - Setting a hard cap to the maximum number of days that can be included in the timeaveraging to 30 days (720 hours). This may expand in the future.")
    end

    if iszero(spatiallon); spatiallon = spatial end
    if iszero(spatiallat); spatiallat = spatial end

    gres = ereg.gres
    shiftlon = Int(floor(spatiallon/(2*gres)))
    shiftlat = Int(floor(spatiallat/(2*gres)))

    buffer = Int(ceil((hours-1)/2))
    weights = ones(buffer*2+1)
    if buffer >= (hours/2)
        weights[1] = 0.5
        weights[end] = 0.5
    end
    weights /= hours

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload  = zeros(Int16,nlon,nlat,31*24)
    tmpdata  = zeros(nlon,nlat,31*24+buffer*2)
    shfttmp  = zeros(nlon,nlat,(2*shiftlon+1)*(2*shiftlat+1))
    smthdata = zeros(nlon,nlat,31*24)
    shftnan  = zeros(Bool,(2*shiftlon+1)*(2*shiftlat+1))
    smthii = zeros(1+buffer*2)

    for dt in e5ds.start : Month(1) : e5ds.stop

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        nhr = daysinmonth(dt) * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nhr),:,:,:)
        int2real!(
            view(tmpdata,:,:,1:nhr), view(tmpload,:,:,1:nhr),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt-Month(1))) ..."
        nhb = daysinmonth(dt-Month(1)) * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt-Month(1)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nhb),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:buffer)), view(tmpload,:,:,(nhb+1-buffer):nhb),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt+Month(1))) ..."
        nhe = daysinmonth(dt+Month(1)) * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt+Month(1)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nhe),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:buffer).+(nhr+buffer)),
            view(tmpload,:,:,1:buffer),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Performing $hours-hour temporal smoothing on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        for ihr = 1 : nhr, ilat = 1 : nlat, ilon = 1 : nlon
            for ii = 0 : (buffer*2)
                smthii[ii+1] = tmpdata[ilon,ilat,ihr+ii] * weights[ii+1]
            end
            smthdata[ilon,ilat,ihr] = mean(smthii)
        end

        @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",spatiallon))x$(@sprintf("%.2f",spatiallat))) on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        for ihr = 1 : nhr
            ishift = 0
            for ishiftlat = -shiftlat : shiftlat, ishiftlon = -shiftlon : shiftlon
                ishift += 1
                circshift!(
                    view(shfttmp,:,:,ishift),view(smthdata,:,:,ihr),
                    (ishiftlon,ishiftlat)
                )
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                if !isnan(tmpdata[ilon,ilat,ihr])
                      smthdata[ilon,ilat,ihr] = nanmean(view(shfttmp,ilon,ilat,:),shftnan)
                else; smthdata[ilon,ilat,ihr] = NaN
                end
            end
        end

        if verbose
            @info "$(modulelog()) - Setting edges to NaN because we used cyclical circshift to do spatial smoothing, which doesn't make sense if boundaries are not periodic ..."
        end
        if !iszero(shiftlon) && !ereg.is360
            for ihr = 1 : nhr, ilat = 1 : nlat, ilon = 1 : shiftlon
                smthdata[ilon,ilat,ihr] = NaN
            end
            for ihr = 1 : nhr, ilat = 1 : nlat, ilon = (nlon-shiftlon+1) : nlon
                smthdata[ilon,ilat,ihr] = NaN
            end
        end
        if !iszero(shiftlat)
            for ihr = 1 : nhr, ilat = 1 : shiftlat, ilon = 1 : nlon
                smthdata[ilon,ilat,ihr] = NaN
            end
            for ihr = 1 : nhr, ilat = (nlat-shiftlat+1) : nlat, ilon = 1 : nlon
                smthdata[ilon,ilat,ihr] = NaN
            end
        end

        save(
            view(spatialdata,:,:,1:nhr), dt, e5ds, evar, ereg, lsd,
            smooth=true, smoothlon=spatiallon, smoothlat=spatiallat, smoothtime=hours
        )

        flush(stderr)

    end

end

function smoothing(
    e5ds :: ERA5Daily,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    spatial :: Real = 0,
    days :: Int,
    spatiallon :: Real = 0,
    spatiallat :: Real = 0,
    verbose :: Bool = false
)

    if iszero(spatial) && (iszero(spatiallon) && iszero(spatiallat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if days > 30
        error("$(modulelog()) - Setting a hard cap to the maximum number of days that can be included in the timeaveraging to 30 days (720 hours). This may expand in the future.")
    end

    if iszero(spatiallon); spatiallon = spatial end
    if iszero(spatiallat); spatiallat = spatial end

    gres = ereg.gres
    shiftlon = Int(floor(spatiallon/(2*gres)))
    shiftlat = Int(floor(spatiallat/(2*gres)))

    buffer = Int(ceil((days-1)/2))
    weights = ones(buffer*2+1)
    if buffer >= (days/2)
        weights[1] = 0.5
        weights[end] = 0.5
    end
    weights /= days

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload  = zeros(Int16,nlon,nlat,31)
    tmpdata  = zeros(nlon,nlat,31+buffer*2)
    shfttmp  = zeros(nlon,nlat,(2*shiftlon+1)*(2*shiftlat+1))
    smthdata = zeros(nlon,nlat,31)
    shftnan  = zeros(Bool,(2*shiftlon+1)*(2*shiftlat+1))
    smthii = zeros(1+buffer*2)

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
            view(tmpdata,:,:,(1:ndy).+buffer), view(tmpload,:,:,1:ndy),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt-Month(1))) ..."
        ndb = daysinmonth(dt-Month(1))
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt-Month(1)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:ndb),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:buffer)), view(tmpload,:,:,(ndb+1-buffer):ndb),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt+Month(1))) ..."
        nde = daysinmonth(dt+Month(1))
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt+Month(1)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nde),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:buffer).+(ndy+buffer)),
            view(tmpload,:,:,1:buffer),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        @info "$(modulelog()) - Performing $hours-hour temporal smoothing on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        for ihr = 1 : nhr, ilat = 1 : nlat, ilon = 1 : nlon
            for ii = 0 : (buffer*2)
                smthii[ii+1] = tmpdata[ilon,ilat,ihr+ii] * weights[ii+1]
            end
            smthdata[ilon,ilat,ihr] = mean(smthii)
        end

        @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",spatiallon))x$(@sprintf("%.2f",spatiallat))) on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        for idy = 1 : ndy
            ishift = 0
            for ishiftlat = -shiftlat : shiftlat, ishiftlon = -shiftlon : shiftlon
                ishift += 1
                circshift!(
                    view(shfttmp,:,:,ishift),view(smthdata,:,:,idy),
                    (ishiftlon,ishiftlat)
                )
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
            smooth=true, smoothlon=spatiallon, smoothlat=spatiallat, smoothtime=days
        )

        flush(stderr)

    end

end