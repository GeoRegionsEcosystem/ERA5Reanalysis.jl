function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

    nhr = 24 * daysinmonth(dt)
    scale,offset = ncoffsetscale(data)

    ds.dim["longitude"] = length(lsd.lon);
    ds.dim["latitude"]  = length(lsd.lat);
    ds.dim["time"] = nhr

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = (collect(1:nhr).-1) * 24
    ncvar[:]  = data;

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

    nhr = 24 * daysinmonth(dt);
    scale,offset = ncoffsetscale(data);

    lsd = getLandSea(e5ds,ereg)
    ds.dim["longitude"] = length(lsd.lon);
    ds.dim["latitude"]  = length(lsd.lat);
    ds.dim["time"] = nhr

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = (collect(1:nhr).-1) * 24
    ncvar[:]  = data;

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

    nt = 12; if e5ds.hours; nt = nt * 24 end
    scale,offset = ncoffsetscale(data)

    ds.dim["longitude"] = length(lsd.lon);
    ds.dim["latitude"]  = length(lsd.lat);
    ds.dim["time"] = nt

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = save_definetimes(e5ds,dt)
    ncvar[:]  = data;

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

    nt = 12; if e5ds.hours; nt = nt * 24 end
    scale,offset = ncoffsetscale(data);

    lsd = getLandSea(e5ds,ereg)
    ds.dim["longitude"] = length(lsd.lon);
    ds.dim["latitude"]  = length(lsd.lat);
    ds.dim["time"] = nt

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = save_definetimes(e5ds,dt)
    ncvar[:]  = data;

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) has been saved into $(fnc)."

end

function save_createds(
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    dt   :: Date,
)

    fnc = e5dfnc(e5ds,evar,ereg,dt)
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

    return ds,fnc

end

function save_definelonlat!(ds::NCDataset)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    return nclon,nclat

end

function save_definevar!(
    ds     :: NCDataset,
    evar   :: ERA5Variable,
    scale  :: Real,
    offset :: Real
)

    ncvar = defVar(ds,evar.varID,Int16,("longitude","latitude","time"),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
        "scale_factor"  => scale,
        "add_offset"    => offset,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    ))

    return ncvar

end

function save_definetimes(
    e5ds :: ERA5Monthly,
    dt   :: Date
)

    yr = year(dt)
    di = Dates.value(Date(yr,1,1))

    if e5ds.hours

        hr = collect(0:23)
        dy = Dates.value.(Date(yr,1,15):Month(1):Date(yr,12,31)) .- di
        tt = hr .+ (dy' * 24)
        tt = tt[:]

    else

        dy = Dates.value.(Date(yr,1,15):Month(1):Date(yr,12,31)) .- di
        tt = dy * 24

    end

    return tt

end