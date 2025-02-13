function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSeaTopo;
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc :: AbstractString = "",
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
)

    @info "$(modulelog()) - Saving raw $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) ..."

    ds,fnc = save_createds(
        e5ds,evar,ereg,dt,extract,smooth,
        extractnc,smoothlon,smoothlat
    )

    scale,offset = ncoffsetscale(data)

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
    ds.dim["time"] = ntimesteps(e5ds)

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = save_definetimes(e5ds,dt)
    ncvar[:,:,:] = data

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.name)) $(evar.name) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region;
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc :: AbstractString = "",
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
)

    @info "$(modulelog()) - Saving raw $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) ..."

    ds,fnc = save_createds(
        e5ds,evar,ereg,dt,extract,smooth,
        extractnc,smoothlon,smoothlat
    )

    lsd = getLandSea(e5ds,ereg)
    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
    ds.dim["time"] = ntimesteps(e5ds)

    nclon,nclat = save_definelonlat!(ds)

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "hours since $(dt) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncvar = save_definevar!(ds,evar)

    nclon[:]  = lsd.lon
    nclat[:]  = lsd.lat
    nctime[:] = save_definetimes(e5ds,dt)
    ncvar[:,:,:] = data

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.name)) $(evar.name) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(dt)) has been saved into $(fnc)."

end