function hourly2monthlyhour(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    e5dsmo = ERA5Monthly(start=e5ds.start,stop=e5ds.stop,path=dirname(e5ds.path),hours=true)
    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,ntimesteps(e5ds))
    tmpdata = zeros(nlon,nlat,31)
    modata  = zeros(nlon,nlat,ntimesteps(e5dsdy))

    for dt in e5ds.start : Year(1) : e5ds.stop

        for imo = 1 : 12

            idt = Date(year(dt),imo)
            if verbose
                @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
            end
            ndy = daysinmonth(idt)
            nhr = daysinmonth(idt) * 24
            sc  = ds[evar.varID].attrib["scale_factor"]
            of  = ds[evar.varID].attrib["add_offset"]
            mv  = ds[evar.varID].attrib["missing_value"]
            fv  = ds[evar.varID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nhr),:,:,it)
            close(ds)

            if verbose
                @info "$(modulelog()) - Performing daily-averaging on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(idt)) $(monthname(idt)) ..."
            end

            for ihr = 1 : 24
                it = ihr + (imo-1) * 24
                int2real!(
                    view(tmpdata,:,:,1:ndy),view(tmpload,:,:,ihr:24:nhr),
                    scale=sc,offset=of,mvalue=mv,fvalue=fv
                )
                for ilat = 1 : nlat, ilon = 1 : nlon
                    modata[ilon,ilat,it] = mean(view(tmpdata,ilon,ilat,1:ndy))
                end
            end
        end

        save(modata, dt, e5dsmo, evar, ereg, lsd)

    end

end