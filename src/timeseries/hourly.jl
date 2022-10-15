function timeseries(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    egeo :: ERA5Region;
    verbose :: Bool = false
)

    yrbeg = year(e5ds.start);  yrend = year(e5ds.stop)
    mobeg = month(e5ds.start); moend = month(e5ds.stop)
    dtbeg = Date(yrbeg,mobeg)
    dtend = Date(yrend,moend) + Month(1)
    ndt   = Dates.value(dtend-dtbeg)

    lsd = getLandSea(e5ds,egeo)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    wgtmask = lsd.mask .* lsd.lat'
    wgtmask = wgtmask / sum(wgtmask)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,744)
    tmpdata = zeros(nlon,nlat,744)
    tsvec   = zeros(ndt)
    ii = 0

    for yr in yrbeg : yrend, mo = 1 : 12

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
        end
        ndy = daysinmonth(Date(yr,mo))
        nt  = ndy * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,egeo,Date(yr,mo)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]

        iiload = @view tmpload[:,:,1:nt]
        iidata = @view tmpdata[:,:,1:nt]
        NCDatasets.load!(ds[evar.varID].var,tvr,:,:,:)
        int2real!(iidata,iiload,scale=sc,offset=of,mvalue=mv,fvalue=fv)
        close(ds)

        if verbose
            @info "$(modulelog()) - Finding latitude-weighted domain-mean of $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) and allocating into timeseries vector ..."
        end
        for it = 1 : nt
            ii += 1
            for ilat = 1 : nlat, ilon = 1 : nlon
                idata = iidata[ilon,ilat,it]
                if !isnan(idata)
                    tsvec[ii] += idata * wgtmask[ilon,ilat]
                end
            end
        end

    end

    save_timeseries(tsvec, e5ds, evar, egeo)

end

function timeseries(
    sgeo :: GeoRegion,
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    egeo :: ERA5Region;
    verbose :: Bool = false
)

    yrbeg = year(e5ds.start);  yrend = year(e5ds.stop)
    mobeg = month(e5ds.start); moend = month(e5ds.stop)
    dtbeg = Date(yrbeg,mobeg)
    dtend = Date(yrend,moend) + Month(1)
    ndt   = Dates.value(dtend-dtbeg)

    lsd  = getLandSea(e5ds,egeo)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    ggrd = RegionGrid(sgeo,lsd.lon,lsd.lat)
    iglon = ggrd.ilon; nglon = length(iglon)
    iglat = ggrd.ilat; nglat = length(iglat)
    wgtmask = zeros(nglon,nglat)
    for ilat = 1 : nglat, ilon = 1 : nglon
        if !isnan(ggrd.mask[ilon,ilat])
            wgtmask[ilon,ilat] = lsd.mask[iglon[ilon],iglat[ilat]] * lsd.lat[iglat[ilat]]
        end
    end
    wgtmask = wgtmask / sum(wgtmask)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,744)
    tmpdata = zeros(nlon,nlat,744)
    tsvec   = zeros(ndt)
    ii = 0

    for yr in yrbeg : yrend, mo = 1 : 12

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
        end
        ndy = daysinmonth(Date(yr,mo))
        nt  = ndy * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,egeo,Date(yr,mo)))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]

        iiload = @view tmpload[:,:,1:nt]
        iidata = @view tmpdata[:,:,1:nt]
        NCDatasets.load!(ds[evar.varID].var,tvr,:,:,:)
        int2real!(iidata,iiload,scale=sc,offset=of,mvalue=mv,fvalue=fv)
        close(ds)

        if verbose
            @info "$(modulelog()) - Finding latitude-weighted domain-mean of $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) and allocating into timeseries vector ..."
        end
        for it = 1 : nt
            ii += 1
            for ilat = 1 : nglat, ilon = 1 : nglon
                idata = iidata[iglon[ilon],iglat[ilat],it]
                if !isnan(idata)
                    tsvec[ii] += idata * wgtmask[ilon,ilat]
                end
            end
        end

    end

    save_timeseries(tsvec, e5ds, evar, ERA5Region(sgeo,gres=egeo.gres))

end

function save_timeseries(
    data :: Vector{<:Real},
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) ..."

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

    nhr = length(data)
    scale,offset = ncoffsetscale(data)
    ds.dim["time"] = nhr

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(e5ds.start) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nctime[:] = collect(1:nhr) .- 1

    if iszero(scale)
        ncvar.var[:] = 0
    else
        if iszero(sum(isnan.(data)))
              ncvar[:] = data
        else; ncvar.var[:] = real2int16(data,scale,offset)
        end
    end

    close(ds)

    @info "$(modulelog()) - Domain-mean timeseries of $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) from $(year(e5ds.start)) $(Dates.monthname(e5ds.start)) to $(year(e5ds.stop)) $(Dates.monthname(e5ds.stop)) has been saved into $(fnc)."

end