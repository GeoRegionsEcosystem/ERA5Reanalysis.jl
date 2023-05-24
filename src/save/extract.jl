function save(
    data :: AbstractArray{Int16,3},
    dt   :: Date,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    scale  :: Real,
    offset :: Real;
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc  :: AbstractString = "",
    smoothlon  :: Real = 0,
    smoothlat  :: Real = 0,
    smoothtime :: Int = 0
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) $(Dates.monthname(dt)) ..."

    ds,fnc = save_createds(
        e5ds, evar, ereg, dt, extract, smooth,
        extractnc, smoothlon, smoothlat, smoothtime
    )

    nhr = 24 * daysinmonth(dt)

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
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
    nctime[:] = collect(1:nhr) .- 1
    ncvar.var[:] = data

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) $(Dates.monthname(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{Int16,3},
    dt   :: Date,
    e5ds :: ERA5Daily,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    scale  :: Real,
    offset :: Real;
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc :: AbstractString = "",
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    smoothtime :: Int = 0
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) $(Dates.monthname(dt)) ..."

    ds,fnc = save_createds(
        e5ds, evar, ereg, dt, extract, smooth,
        extractnc, smoothlon, smoothlat, smoothtime
    )

    nhr = daysinmonth(dt)

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
    ds.dim["time"] = nhr

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "days since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar,scale,offset)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = collect(1:nhr) .- 1
    ncvar.var[:] = data

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) $(Dates.monthname(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{Int16,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    scale  :: Real,
    offset :: Real;
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc :: AbstractString = "",
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
    smoothtime :: Int = 0
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt,extract,smooth,extractnc,smoothlon,smoothlat)

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
    ds.dim["time"] = ntimesteps(e5ds)

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
    ncvar.var[:] = data

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) has been saved into $(fnc)."

end