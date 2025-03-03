function hourly2daily(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false,
    dosum   :: Bool = false
)

    e5dsdy = ERA5Daily(start=e5ds.start,stop=e5ds.stop,path=dirname(e5ds.path))

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Float32,nlon,nlat,ntimesteps(e5ds))
    dydata  = zeros(nlon,nlat,ntimesteps(e5dsdy))

    if !dosum; fac = 1; else; fac = 24 end

    for dt in e5ds.start : Month(1) : e5ds.stop

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        end
        ndy = daysinmonth(dt)
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:(ndy*24)),:,:,:)
        close(ds)

        if verbose
            if !dosum
                @info "$(modulelog()) - Performing daily-averaging on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            else
                @info "$(modulelog()) - Performing daily summation on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
            end
        end

        for idy = 1 : ndy
            ibeg = 24 * (idy-1) + 1
            iend = 24 *  idy
            for ilat = 1 : nlat, ilon = 1 : nlon
                dydata[ilon,ilat,idy] = mean(view(tmpload,ilon,ilat,ibeg:iend)) * fac
            end
        end

        save(view(dydata,:,:,1:ndy), dt, e5dsdy, evar, ereg, lsd)

        flush(stderr)

    end

end