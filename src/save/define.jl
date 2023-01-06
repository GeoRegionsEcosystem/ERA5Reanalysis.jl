function save_createds(
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    dt   :: Date,
    extract :: Bool = false,
    smooth  :: Bool = false,
    extractnc :: AbstractString = "",
    smoothlon :: Real = 0,
    smoothlat :: Real = 0,
)

    fnc = e5dfnc(e5ds,evar,ereg,dt)
    if smooth
        fnc = e5dsmth(e5ds,evar,ereg,dt,smoothlon,smoothlat)
    end
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
    if extract
        ds.attrib["extract"] = "Data for current NetCDF file was extracted from file $(extractnc) on $(Dates.now())"
    end

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