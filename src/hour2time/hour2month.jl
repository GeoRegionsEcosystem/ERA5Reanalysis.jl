function hourly2monthly(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false,
    dosum   :: Bool = false
)

    e5dsmo = ERA5Monthly(start=e5ds.start,stop=e5ds.stop,path=dirname(e5ds.path))

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Float32,nlon,nlat,ntimesteps(e5ds))
    modata  = zeros(nlon,nlat,ntimesteps(e5dsmo))

    for dt in e5ds.start : Year(1) : e5ds.stop

        for imo = 1 : 12

            idt = Date(year(dt),imo)
            if verbose
                @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
            end
            nhr = daysinmonth(idt) * 24; if !dosum; fac = 1; else; fac = nhr end
            ds  = read(e5ds,evar,ereg,idt,quiet=true)
            NCDatasets.load!(ds[evar.ncID].var,view(tmpload,:,:,1:nhr),:,:,:)

            if verbose
                if !dosum
                    @info "$(modulelog()) - Performing daily-averaging on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
                else
                    @info "$(modulelog()) - Performing daily summation on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
                end
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                modata[ilon,ilat,imo] = mean(view(tmpload,ilon,ilat,1:nhr)) * fac
            end
            flush(stderr)

        end

        save(modata, dt, e5dsmo, evar, ereg, lsd)
        flush(stderr)

    end

end