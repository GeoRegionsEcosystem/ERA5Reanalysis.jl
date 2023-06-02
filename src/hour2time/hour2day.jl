function hourly2daily(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    e5dsdy = ERA5Daily(start=e5ds.start,stop=e5ds.stop,path=dirname(e5ds.path))

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    isaccumulate = checkaccumulate(evar)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,ntimesteps(e5ds))
    tmpdata = zeros(nlon,nlat,24)
    dydata  = zeros(nlon,nlat,ntimesteps(e5dsdy))

    for dt in e5ds.start : Month(1) : e5ds.stop

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        end
        ndy = daysinmonth(dt)
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.ID].attrib["scale_factor"]
        of  = ds[evar.ID].attrib["add_offset"]
        mv  = ds[evar.ID].attrib["missing_value"]
        fv  = ds[evar.ID].attrib["_FillValue"]
        NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:(ndy*24)),:,:,:)
        close(ds)

        if verbose
            @info "$(modulelog()) - Performing daily-averaging on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        end

        for idy = 1 : ndy
            ibeg = 24 * (idy-1) + 1
            iend = 24 *  idy
            int2real!(
                tmpdata,view(tmpload,:,:,ibeg:iend),
                scale=sc,offset=of,mvalue=mv,fvalue=fv
            )
            for ilat = 1 : nlat, ilon = 1 : nlon
                if isaccumulate
                    dydata[ilon,ilat,idy] = sum(view(tmpdata,ilon,ilat,:))
                else
                    dydata[ilon,ilat,idy] = mean(view(tmpdata,ilon,ilat,:))
                end
            end
        end

        save(view(dydata,:,:,1:ndy), dt, e5dsdy, evar, ereg, lsd)

        flush(stderr)

    end

end