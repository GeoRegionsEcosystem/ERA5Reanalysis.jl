function calculatebufferweights(shiftsteps)

    buffer_time = Int(ceil((shiftsteps-1)/2))
    weights = ones(buffer_time*2+1)
    if buffer_time >= (shiftsteps/2)
        weights[1] = 0.5
        weights[end] = 0.5
    end
    weights /= shiftsteps
    return buffer_time,weights

end

function smoothing(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    spatial  :: Bool = false,
    temporal :: Bool = false,
    hours :: Int,
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    verbose :: Bool = false
)

    if !spatial && !temporal
        error("$(modulelog()) - You need to specify at least one of the `spatial` and `temporal` keyword arguments")
    end

    if spatial && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if temporal && iszero(hours)
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if hours > 720
        error("$(modulelog()) - Setting a hard cap to the maximum numbdder of days that can be included in the timeaveraging to 30 days (720 hours). This may expand in the future.")
    end

    gres = ereg.resolution
    shiftlon = smoothlon/gres; if !isinteger(shiftlon)
        error("$(modulelog()) - The variable `smoothlon` should be a integer multiple of $(ereg.resolution)")
    end
    shiftlat = smoothlat/gres; if !isinteger(shiftlat)
        error("$(modulelog()) - The variable `smoothlat` should be a integer multiple of $(ereg.resolution)")
    end

    buffer_lon, weights_lon  = calculatebufferweights(shiftlon)
    buffer_lat, weights_lat  = calculatebufferweights(shiftlat)
    buffer_time,weights_time = calculatebufferweights(hours)

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload  = zeros(Int16,nlon,nlat,31*24)
    tmpdata  = zeros(nlon,nlat,31*24+buffer_time*2)
    shfttmp  = zeros(nlon,nlat,(2*buffer_lon+1)*(2*buffer_lat+1))
    smthdata = zeros(nlon,nlat,31*24)
    shftnan  = zeros(Bool,(2*buffer_lon+1)*(2*buffer_lat+1))
    smthii = zeros(1+buffer_time*2)

    for dt in e5ds.start : Month(1) : e5ds.stop

        @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        nhr = daysinmonth(dt) * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.ID].attrib["scale_factor"]
        of  = ds[evar.ID].attrib["add_offset"]
        mv  = ds[evar.ID].attrib["missing_value"]
        fv  = ds[evar.ID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:nhr),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:nhr).+buffer_time), view(tmpload,:,:,1:nhr),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        if temporal

            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt-Month(1))) ..."
            nhb = daysinmonth(dt-Month(1)) * 24
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt-Month(1)))
            sc  = ds[evar.ID].attrib["scale_factor"]
            of  = ds[evar.ID].attrib["add_offset"]
            mv  = ds[evar.ID].attrib["missing_value"]
            fv  = ds[evar.ID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:nhb),:,:,:)
            int2real!(
                view(tmpdata,:,:,(1:buffer_time)),
                view(tmpload,:,:,(nhb+1-buffer_time):nhb),
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            close(ds)

            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt+Month(1))) ..."
            nhe = daysinmonth(dt+Month(1)) * 24
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt+Month(1)))
            sc  = ds[evar.ID].attrib["scale_factor"]
            of  = ds[evar.ID].attrib["add_offset"]
            mv  = ds[evar.ID].attrib["missing_value"]
            fv  = ds[evar.ID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:nhe),:,:,:)
            int2real!(
                view(tmpdata,:,:,(1:buffer_time).+(nhr+buffer_time)),
                view(tmpload,:,:,1:buffer_time),
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            close(ds)

            @info "$(modulelog()) - Performing $hours-hour temporal smoothing on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            for ihr = 1 : nhr, ilat = 1 : nlat, ilon = 1 : nlon
                for ii = 0 : (buffer_time*2)
                    smthii[ii+1] = tmpdata[ilon,ilat,ihr+ii] * weights_time[ii+1]
                end
                smthdata[ilon,ilat,ihr] = sum(smthii)
            end

        end

        if spatial
            @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            for ihr = 1 : nhr
                ishift = 0
                for ilat = -buffer_lat : buffer_lat, ilon = -buffer_lon : buffer_lon
                    ishift += 1
                    circshift!(
                        view(shfttmp,:,:,ishift),view(smthdata,:,:,ihr),
                        (ilon,ilat)
                    )
                end
                for ilat = 1 : (2*buffer_lat+1), ilon = 1 : (2*buffer_lat+1)
                    ishift += 1
                    shfttmp[ilon,ilat,ishift] *= weights_lon[ilon] * weights_lat[ilat]
                end
                for ilat = 1 : nlat, ilon = 1 : nlon
                    if !isnan(tmpdata[ilon,ilat,ihr])
                        smthdata[ilon,ilat,ihr] = nansum(
                            view(shfttmp,ilon,ilat,:),shftnan
                        )
                    else; smthdata[ilon,ilat,ihr] = NaN
                    end
                end
            end

            if verbose
                @info "$(modulelog()) - Setting edges to NaN because we used cyclical circshift to do spatial smoothing, which doesn't make sense if boundaries are not periodic ..."
            end
            if !iszero(buffer_lon) && !ereg.is360
                for ihr = 1 : nhr, ilat = 1 : nlat, ilon = 1 : buffer_lon
                    smthdata[ilon,ilat,ihr] = NaN
                end
                for ihr = 1 : nhr, ilat = 1 : nlat, ilon = (nlon-buffer_lon+1) : nlon
                    smthdata[ilon,ilat,ihr] = NaN
                end
            end
            if !iszero(buffer_lat)
                for ihr = 1 : nhr, ilat = 1 : buffer_lat, ilon = 1 : nlon
                    smthdata[ilon,ilat,ihr] = NaN
                end
                for ihr = 1 : nhr, ilat = (nlat-buffer_lat+1) : nlat, ilon = 1 : nlon
                    smthdata[ilon,ilat,ihr] = NaN
                end
            end

        end

        save(
            view(spatialdata,:,:,1:nhr), dt, e5ds, evar, ereg, lsd,
            smooth=true, smoothlon=smoothlon, smoothlat=smoothlat, smoothtime=hours
        )

        flush(stderr)

    end

end

function smoothing(
    e5ds :: ERA5Daily,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    spatial  :: Bool = false,
    temporal :: Bool = false,
    days :: Int,
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    verbose :: Bool = false
)

    if !spatial && !temporal
        error("$(modulelog()) - You need to specify at least one of the `spatial` and `temporal` keyword arguments")
    end

    if spatial && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if temporal && iszero(days)
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    if days > 30
        error("$(modulelog()) - Setting a hard cap to the maximum number of days that can be included in the timeaveraging to 30 days (720 hours). This may expand in the future.")
    end

    gres = ereg.resolution
    shiftlon = smoothlon/gres; if !isinteger(shiftlon)
        error("$(modulelog()) - The variable `smoothlon` should be a integer multiple of $(ereg.resolution)")
    end
    shiftlat = smoothlat/gres; if !isinteger(shiftlat)
        error("$(modulelog()) - The variable `smoothlat` should be a integer multiple of $(ereg.resolution)")
    end

    buffer_lon, weights_lon  = calculatebufferweights(shiftlon)
    buffer_lat, weights_lat  = calculatebufferweights(shiftlat)
    buffer_time,weights_time = calculatebufferweights(days)

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload  = zeros(Int16,nlon,nlat,31)
    tmpdata  = zeros(nlon,nlat,31+buffer_time*2)
    shfttmp  = zeros(nlon,nlat,(2*buffer_lon+1)*(2*buffer_lat+1))
    smthdata = zeros(nlon,nlat,31)
    shftnan  = zeros(Bool,(2*buffer_lon+1)*(2*buffer_lat+1))
    smthii = zeros(1+buffer_time*2)

    for dt in e5ds.start : Month(1) : e5ds.stop

        @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        ndy = daysinmonth(dt)
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.ID].attrib["scale_factor"]
        of  = ds[evar.ID].attrib["add_offset"]
        mv  = ds[evar.ID].attrib["missing_value"]
        fv  = ds[evar.ID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:ndy),:,:,:)
        int2real!(
            view(tmpdata,:,:,(1:ndy).+buffer_time), view(tmpload,:,:,1:ndy),
            scale=sc, offset=of, mvalue=mv, fvalue=fv
        )
        close(ds)

        if temporal
            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt-Month(1))) ..."
            ndb = daysinmonth(dt-Month(1))
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt-Month(1)))
            sc  = ds[evar.ID].attrib["scale_factor"]
            of  = ds[evar.ID].attrib["add_offset"]
            mv  = ds[evar.ID].attrib["missing_value"]
            fv  = ds[evar.ID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:ndb),:,:,:)
            int2real!(
                view(tmpdata,:,:,(1:buffer_time)), view(tmpload,:,:,(ndb+1-buffer_time):ndb),
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            close(ds)

            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt+Month(1))) ..."
            nde = daysinmonth(dt+Month(1))
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt+Month(1)))
            sc  = ds[evar.ID].attrib["scale_factor"]
            of  = ds[evar.ID].attrib["add_offset"]
            mv  = ds[evar.ID].attrib["missing_value"]
            fv  = ds[evar.ID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:nde),:,:,:)
            int2real!(
                view(tmpdata,:,:,(1:buffer_time).+(ndy+buffer_time)),
                view(tmpload,:,:,1:buffer_time),
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            close(ds)

            @info "$(modulelog()) - Performing $days-day temporal smoothing on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            for idy = 1 : ndy, ilat = 1 : nlat, ilon = 1 : nlon
                for ii = 0 : (buffer_time*2)
                    smthii[ii+1] = tmpdata[ilon,ilat,idy+ii] * weights_time[ii+1]
                end
                smthdata[ilon,ilat,idy] = sum(smthii)
            end
        end

        if spatial
            @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            for idy = 1 : ndy
                ishift = 0
                for ilat = -buffer_lat : buffer_lat, ilon = -buffer_lon : buffer_lon
                    ishift += 1
                    circshift!(
                        view(shfttmp,:,:,ishift),view(smthdata,:,:,idy),
                        (ilon,ilat)
                    )
                end
                for ilat = 1 : (2*buffer_lat+1), ilon = 1 : (2*buffer_lat+1)
                    ishift += 1
                    shfttmp[ilon,ilat,ishift] *= weights_lon[ilon] * weights_lat[ilat]
                end
                for ilat = 1 : nlat, ilon = 1 : nlon
                    if !isnan(tmpdata[ilon,ilat,idy])
                        smthdata[ilon,ilat,ihr] = nansum(
                            view(shfttmp,ilon,ilat,:),shftnan
                        )
                    else; smthdata[ilon,ilat,idy] = NaN
                    end
                end
            end

            if verbose
                @info "$(modulelog()) - Setting edges to NaN because we used cyclical circshift to do spatial smoothing, which doesn't make sense if boundaries are not periodic ..."
            end
            if !iszero(buffer_lon) && !ereg.is360
                for idy = 1 : ndy, ilat = 1 : nlat, ilon = 1 : buffer_lon
                    smthdata[ilon,ilat,idy] = NaN
                end
                for idy = 1 : ndy, ilat = 1 : nlat, ilon = (nlon-buffer_lon+1) : nlon
                    smthdata[ilon,ilat,idy] = NaN
                end
            end
            if !iszero(buffer_lat)
                for idy = 1 : ndy, ilat = 1 : buffer_lat, ilon = 1 : nlon
                    smthdata[ilon,ilat,idy] = NaN
                end
                for idy = 1 : ndy, ilat = (nlat-buffer_lat+1) : nlat, ilon = 1 : nlon
                    smthdata[ilon,ilat,idy] = NaN
                end
            end

        end

        save(
            view(smthdata,:,:,1:ndy), dt, e5ds, evar, ereg, lsd,
            smooth=true, smoothlon=smoothlon, smoothlat=smoothlat, smoothtime=days
        )

        flush(stderr)

    end

end

function smoothing(
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    verbose :: Bool = false
)

    if iszero(smoothlon) && iszero(smoothlat)
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    gres = ereg.resolution
    shiftlon = smoothlon/gres; if !isinteger(shiftlon)
        error("$(modulelog()) - The variable `smoothlon` should be a integer multiple of $(ereg.resolution)")
    end
    shiftlat = smoothlat/gres; if !isinteger(shiftlat)
        error("$(modulelog()) - The variable `smoothlat` should be a integer multiple of $(ereg.resolution)")
    end

    buffer_lon, weights_lon  = calculatebufferweights(shiftlon)
    buffer_lat, weights_lat  = calculatebufferweights(shiftlat)

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    ndt = ntimesteps(e5ds)
    tmpload  = zeros(Int16,nlon,nlat,ndt)
    tmpdata  = zeros(nlon,nlat,ndt)
    smthdata = zeros(nlon,nlat,ndt)
    shfttmp  = zeros(nlon,nlat,(2*buffer_lon+1)*(2*buffer_lat+1))
    shftnan  = zeros(Bool,(2*buffer_lon+1)*(2*buffer_lat+1))

    for dt in e5ds.start : Month(1) : e5ds.stop

        @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.ID].attrib["scale_factor"]
        of  = ds[evar.ID].attrib["add_offset"]
        mv  = ds[evar.ID].attrib["missing_value"]
        fv  = ds[evar.ID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.ID].var,tmpload,:,:,:)
        int2real!(tmpdata,tmpload,scale=sc,offset=of,mvalue=mv,fvalue=fv)
        close(ds)

        @info "$(modulelog()) - Performing spatial smoothing ($(@sprintf("%.2f",smoothlon))x$(@sprintf("%.2f",smoothlat))) on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        for idt = 1 : ndt
            ishift = 0
            for ilat = -buffer_lat : buffer_lat, ilon = -buffer_lon : buffer_lon
                ishift += 1
                circshift!(
                    view(shfttmp,:,:,ishift),view(smthdata,:,:,idy),
                    (ilon,ilat)
                )
            end
            for ilat = 1 : (2*buffer_lat+1), ilon = 1 : (2*buffer_lat+1)
                ishift += 1
                shfttmp[ilon,ilat,ishift] *= weights_lon[ilon] * weights_lat[ilat]
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                if !isnan(tmpdata[ilon,ilat,idt])
                    smthdata[ilon,ilat,idt] = nansum(
                        view(shfttmp,ilon,ilat,:),shftnan
                    )
                else; smthdata[ilon,ilat,idt] = NaN
                end
            end
        end

        if verbose
            @info "$(modulelog()) - Setting edges to NaN because we used cyclical circshift to do spatial smoothing, which doesn't make sense if boundaries are not periodic ..."
        end
        if !iszero(buffer_lon) && !ereg.is360
            for idt = 1 : ndt, ilat = 1 : nlat, ilon = 1 : buffer_lon
                smthdata[ilon,ilat,idt] = NaN
            end
            for idt = 1 : ndt, ilat = 1 : nlat, ilon = (nlon-buffer_lon+1) : nlon
                smthdata[ilon,ilat,idt] = NaN
            end
        end
        if !iszero(buffer_lat)
            for idt = 1 : ndt, ilat = 1 : buffer_lat, ilon = 1 : nlon
                smthdata[ilon,ilat,idt] = NaN
            end
            for idt = 1 : ndt, ilat = (nlat-buffer_lat+1) : nlat, ilon = 1 : nlon
                smthdata[ilon,ilat,idt] = NaN
            end
        end

        save(
            smthdata, dt, e5ds, evar, ereg, lsd,
            smooth=true, smoothlon=smoothlon, smoothlat=smoothlat
        )

        flush(stderr)

    end

end