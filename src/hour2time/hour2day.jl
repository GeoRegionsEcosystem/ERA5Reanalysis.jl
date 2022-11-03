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

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,24,31)
    tmpdata = zeros(nlon,nlat,24,31)
    dydata  = zeros(nlon,nlat,366)

    for dt in e5ds.start : Month(1) : e5ds.stop

        if verbose
            @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        end
        ndy = daysinmonth(dt)
        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
        sc  = ds[evar.varID].attrib["scale_factor"]
        of  = ds[evar.varID].attrib["add_offset"]
        mv  = ds[evar.varID].attrib["missing_value"]
        fv  = ds[evar.varID].attrib["_FillValue"]

        for idy = 1 : ndy, ihr = 1 : 24
            it = ihr + (idy-1) * 24
            NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,ihr,idy),:,:,it)
        end
        int2real!(
            view(tmpdata,:,:,:,1:ndy),view(tmpload,:,:,:,1:ndy),
            scale=sc,offset=of,mvalue=mv,fvalue=fv
        )
        close(ds)

        if verbose
            @info "$(modulelog()) - Performing daily-averaging on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
        end
        for idy = 1 : ndy, ilat = 1 : nlat, ilon = 1 : nlon
            dydata[ilon,ilat,idy] = mean(view(tmpdata,ilon,ilat,:,idy))
        end

        save_hourly2daily(view(dydata,:,:,1:ndy), e5dsdy, evar, ereg, lsd, dt)

    end

end

function save_hourly2daily(
    dayts :: AbstractArray{<:Real,3},
    e5ds  :: ERA5Daily,
    evar  :: ERA5Variable,
    ereg  :: ERA5Region,
    lsd   :: LandSea,
    date  :: TimeType
)

    @info "$(modulelog()) - Saving daily $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) ..."

    fnc = e5dfnc(e5ds,evar,ereg,date)
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
    scale,offset = ncoffsetscale(data)

    ds.dim["time"] = ndy
    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "days since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)
    
    nclon[:] = lsd.lon
    nclat[:] = lsd.lat
    nctime[:] = collect(1:ndy) .- 1

    if iszero(scale)
        ncvar.var[:] = 0
    else
        if iszero(sum(isnan.(data)))
              ncvar[:] = data
        else; ncvar.var[:] = real2int16(data,scale,offset)
        end
    end

    close(ds)

    @info "$(modulelog()) - Daily-averaged $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) has been saved into $(fnc)."

end