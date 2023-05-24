function timeseries(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    yrbeg = year(e5ds.start);  yrend = year(e5ds.stop)
    mobeg = month(e5ds.start); moend = month(e5ds.stop)
    dtbeg = Date(yrbeg,mobeg)
    dtend = Date(yrend,moend) + Month(1)
    ndt   = Dates.value(dtend-dtbeg) * 24

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    wgtmask = lsd.mask .* cosd.(lsd.lat)'
    summask = sum(wgtmask)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,744)
    tmpdata = zeros(nlon,nlat,744)
    totts = zeros(ndt)
    lndts = zeros(ndt)
    ocnts = zeros(ndt)

    for dt in e5ds.start : Month(1) : e5ds.stop

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        end
        ndy = daysinmonth(dt)
        nt  = ndy * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]

        iiload = @view tmpload[:,:,1:nt]
        iidata = @view tmpdata[:,:,1:nt]
        NCDatasets.load!(ds[evar.varID].var,iiload,:,:,:)
        int2real!(iidata,iiload,scale=sc,offset=of,mvalue=mv,fvalue=fv)
        close(ds)

        if verbose
            @info "$(modulelog()) - Finding latitude-weighted domain-mean of $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) and allocating into timeseries vector ..."
        end
        ii = Dates.value(dt-dtbeg) * 24
        for it = 1 : nt
            totii = 0; adjsum = summask
            ocnii = 0; ocnsum = summask
            lndii = 0; lndsum = summask
            for ilat = 1 : nlat, ilon = 1 : nlon
                idata = iidata[ilon,ilat,it]
                ilsm  = lsd.lsm[ilon,ilat]
                if !isnan(idata)
                    totii += idata * wgtmask[ilon,ilat]
                    if ilsm <= 0.5
                        ocnii += idata * wgtmask[ilon,ilat]
                        lndsum -= wgtmask[ilon,ilat]
                    end
                    if ilsm >= 0.5
                        lndii += idata * wgtmask[ilon,ilat]
                        ocnsum -= wgtmask[ilon,ilat]
                    end
                else
                    adjsum -= wgtmask[ilon,ilat]
                    lndsum -= wgtmask[ilon,ilat]
                    ocnsum -= wgtmask[ilon,ilat]
                end
            end
            if !iszero(adjsum); totts[ii+it] = totii / adjsum; else; totts[ii+it] = NaN end
            if !iszero(lndsum); lndts[ii+it] = lndii / lndsum; else; lndts[ii+it] = NaN end
            if !iszero(ocnsum); ocnts[ii+it] = ocnii / ocnsum; else; ocnts[ii+it] = NaN end
        end

        flush(stderr)

    end

    save_timeseries(totts, lndts, ocnts, e5ds, evar, ereg)

end

function timeseries(
    sgeo :: GeoRegion,
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    yrbeg = year(e5ds.start);  yrend = year(e5ds.stop)
    mobeg = month(e5ds.start); moend = month(e5ds.stop)
    dtbeg = Date(yrbeg,mobeg)
    dtend = Date(yrend,moend) + Month(1)
    ndt   = Dates.value(dtend-dtbeg) * 24

    lsd  = getLandSea(e5ds,ereg)
    slsd = getLandSea(e5ds,ERA5Region(sgeo,gres=ereg.resolution))
    ggrd = RegionGrid(sgeo,lsd.lon,lsd.lat)
    nlon = length(lsd.lon); iglon = ggrd.ilon; nglon = length(iglon)
    nlat = length(lsd.lat); iglat = ggrd.ilat; nglat = length(iglat)
    wgtmask = slsd.mask .* cosd.(slsd.lat)'
    summask = sum(wgtmask)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,744)
    tmpdata = zeros(nlon,nlat,744)
    totts = zeros(ndt)
    lndts = zeros(ndt)
    ocnts = zeros(ndt)

    for dt in e5ds.start : Month(1) : e5ds.stop

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) ..."
        end
        ndy = daysinmonth(dt)
        nt  = ndy * 24
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]

        iiload = @view tmpload[:,:,1:nt]
        iidata = @view tmpdata[:,:,1:nt]
        NCDatasets.load!(ds[evar.varID].var,iiload,:,:,:)
        int2real!(iidata,iiload,scale=sc,offset=of,mvalue=mv,fvalue=fv)
        close(ds)

        if verbose
            @info "$(modulelog()) - Finding latitude-weighted domain-mean of $(e5ds.lname) $(evar.vname) data in $(sgeo.name) (Horizontal Resolution: $(ereg.resolution)) during $(year(dt)) $(monthname(dt)) and allocating into timeseries vector ..."
        end

        ii = Dates.value(dt-dtbeg) * 24
        for it = 1 : nt
            totii = 0; adjsum = summask
            ocnii = 0; ocnsum = summask
            lndii = 0; lndsum = summask
            for ilat = 1 : nglat, ilon = 1 : nglon
                idata = iidata[iglon[ilon],iglat[ilat],it]
                ilsm  = slsd.lsm[ilon,ilat]
                if !isnan(idata)
                    totii += idata * wgtmask[ilon,ilat]
                    if ilsm <= 0.5
                        ocnii += idata * wgtmask[ilon,ilat]
                        lndsum -= wgtmask[ilon,ilat]
                    end
                    if ilsm >= 0.5
                        lndii += idata * wgtmask[ilon,ilat]
                        ocnsum -= wgtmask[ilon,ilat]
                    end
                else
                    adjsum -= wgtmask[ilon,ilat]
                    lndsum -= wgtmask[ilon,ilat]
                    ocnsum -= wgtmask[ilon,ilat]
                end
            end
            totts[ii+it] = totii / adjsum
            lndts[ii+it] = lndii / lndsum
            ocnts[ii+it] = ocnii / ocnsum
        end

    end

    save_timeseries(totts, lndts, ocnts, e5ds, evar, ERA5Region(sgeo,gres=ereg.resolution))

    flush(stderr)

end

function save_timeseries(
    totts :: Vector{<:Real},
    lndts :: Vector{<:Real},
    ocnts :: Vector{<:Real},
    e5ds  :: ERA5Hourly,
    evar  :: ERA5Variable,
    ereg  :: ERA5Region
)

    @info "$(modulelog()) - Saving domain-mean timeseries of $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(year(e5ds.start)) $(Dates.monthname(e5ds.start)) to $(year(e5ds.stop)) $(Dates.monthname(e5ds.stop)) ..."

    fnc = e5dtnc(e5ds,evar,ereg)
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

    nhr = length(totts)
    ds.dim["time"] = nhr

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(e5ds.start) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    nctot = defVar(ds,"$(evar.varID)_domain",Float64,("time",),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
    ))

    nclnd = defVar(ds,"$(evar.varID)_land",Float64,("time",),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
    ))

    ncocn = defVar(ds,"$(evar.varID)_ocean",Float64,("time",),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
    ))
    
    nctime[:] = collect(1:nhr) .- 1
    nctot[:] = totts
    nclnd[:] = lndts
    ncocn[:] = ocnts

    close(ds)

    @info "$(modulelog()) - Domain-mean timeseries of $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(year(e5ds.start)) $(Dates.monthname(e5ds.start)) to $(year(e5ds.stop)) $(Dates.monthname(e5ds.stop)) has been saved into $(fnc)."

end