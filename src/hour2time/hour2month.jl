function hourly2monthly(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    e5dsmo = ERA5Monthly(start=e5ds.start,stop=e5ds.stop,path=dirname(e5ds.path))

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,ntimesteps(e5ds))
    tmpdata = zeros(nlon,nlat,ntimesteps(e5ds))
    modata  = zeros(nlon,nlat,ntimesteps(e5dsmo))

    for dt in e5ds.start : Year(1) : e5ds.stop

        for imo = 1 : 12

            idt = Date(year(dt),imo)
            if verbose
                @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
            end
            nhr = daysinmonth(idt) * 24
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,idt))
            sc  = ds[evar.ID].attrib["scale_factor"]
            of  = ds[evar.ID].attrib["add_offset"]
            mv  = ds[evar.ID].attrib["missing_value"]
            fv  = ds[evar.ID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.ID].var,view(tmpload,:,:,1:nhr),:,:,:)
            int2real!(
                view(tmpdata,:,:,1:nhr),view(tmpload,:,:,1:nhr),
                scale=sc,offset=of,mvalue=mv,fvalue=fv
            )
            close(ds)

            if verbose
                @info "$(modulelog()) - Performing daily-averaging on $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                modata[ilon,ilat,imo] = mean(view(tmpdata,ilon,ilat,1:nhr))
            end

        end

        save(modata, dt, e5dsmo, evar, ereg, lsd)

    end

end