function split(
    e5ds :: ERA5Dataset,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    dt   :: Date,
    pvec :: Vector{Int},
    fnc  :: AbstractString,
    tmpd :: Array{Int16,3},
    tmpf :: Array{Float32,3}
)

    ds = NCDataset(fnc)
    nt = ds.dim["time"]
    sc = ds[evar.varID].attrib["scale_factor"]
    of = ds[evar.varID].attrib["add_offset"]
    mv = ds[evar.varID].attrib["missing_value"]
    fv = ds[evar.varID].attrib["_FillValue"]
    dataint = @view tmpd[:,:,1:nt]
    dataflt = @view tmpf[:,:,1:nt]

    for ip in 1 : length(pvec)
        NCDatasets.load!(ds[evar.varID].var,dataint,:,:,ip,:)
        int2real!(dataflt,dataint,scale=sc,offset=of,mvalue=mv,fvalue=fv)

        p = pvec[ip]
        evarii = PressureVariable(evar.varID,hPa=p)
        save(dataflt,dt,e5ds,evarii,ereg,lsd,sc,of)
    end

    close(ds)

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    scale  :: Real,
    offset :: Real
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

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

    if iszero(sum(isnan.(data)))
          ncvar[:] = data
    else; ncvar.var[:] = real2int16(data,scale,offset)
    end

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) $(Dates.monthname(dt)) has been saved into $(fnc)."

end

function save(
    data :: AbstractArray{<:Real,3},
    dt   :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    scale  :: Real,
    offset :: Real
)

    @info "$(modulelog()) - Saving raw $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) ..."

    ds,fnc = save_createds(e5ds,evar,ereg,dt)

    nt = 12; if e5ds.hours; nt = nt * 24 end

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
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

    if iszero(sum(isnan.(data)))
          ncvar[:] = data
    else; ncvar.var[:] = real2int16(data,scale,offset)
    end

    close(ds)

    @info "$(modulelog()) - Raw $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(dt)) has been saved into $(fnc)."

end