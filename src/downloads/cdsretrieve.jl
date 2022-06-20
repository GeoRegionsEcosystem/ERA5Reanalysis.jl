function cdsretrieve(
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
)

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) from $(e5ds.dtbeg) to $(e5ds.dtend)."

    for dtii in dtvec

        fnc = e5dfnc(e5ds,evar,ereg,dtii)
        fol = dirname(fnc); if !isdir(fol); mkpath(fol) end

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => evar.lname,
            "grid"         => [ereg.gres, ereg.gres],
            "time"         => cdsretrieve_time(e5ds),
            "format"       => "netcdf",
        )

        if typeof(e5ds) <: ERA5Hourly
            e5dkey["day"] = collect(1:31)
        end

        if typeof(evar) <: PressureVariable
            e5dkey["pressure_level"] = evar.hPa
        end
        
        cdsretrieve_area!(e5dkey,ereg)

        retrieve(cdsretrieve_dataset(evar,e5ds),e5dkey,fnc,ckeys)

    end

end

function cdsretrieve(
    e5ds :: ERA5Dataset,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    pvec :: Vector{Int}
)

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Preallocation of temporary data arrays to split downloaded data into their respective pressure levels ..."

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    tmpd = zeros(Int16,nlon,nlat,31*24)
    tmpf = zeros(Float32,nlon,nlat,31*24)

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) from $(e5ds.dtbeg) to $(e5ds.dtend)."

    for dtii in dtvec

        fnc = "tmp.nc"
        fol = dirname(fnc); if !isdir(fol); mkpath(fol) end

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => evar.lname,
            "grid"         => [ereg.gres, ereg.gres],
            "time"         => cdsretrieve_time(e5ds),
            "format"       => "netcdf",
        )

        if typeof(e5ds) <: ERA5Hourly
            e5dkey["day"] = collect(1:31)
        end

        if typeof(evar) <: PressureVariable
            e5dkey["pressure_level"] = pvec
        end
        
        cdsretrieve_area!(e5dkey,ereg)

        retrieve(cdsretrieve_dataset(evar,e5ds),e5dkey,fnc,ckeys)
        split(e5ds,evar,ereg,lsd,dtii,pvec,fnc,tmpd,tmpf)

    end

end


cdsretrieve_dtvec(e5ds::ERA5Hourly)  = e5ds.dtbeg : Month(1) : e5ds.dtend
cdsretrieve_dtvec(e5ds::ERA5Monthly) = e5ds.dtbeg : Year(1)  : e5ds.dtend

cdsretrieve_dataset(evar::ERA5Variable,::ERA5Hourly)  = evar.dname
cdsretrieve_dataset(evar::ERA5Variable,::ERA5Monthly) = evar.dname * "-monthly-means"

function cdsretrieve_area!(
    dkeys :: AbstractDict,
    ereg  :: ERA5Region
)

    if !(ereg.isglb)
        geo = ereg.geo
        dkeys["area"] = [geo.N,geo.W,geo.S,geo.E]
    end

    return

end

cdsretrieve_month(dtii::Date,::ERA5Hourly)  = month(dtii)
cdsretrieve_month(dtii::Date,::ERA5Monthly) = collect(1:12)

cdsretrieve_time(::ERA5Hourly) = [
    "00:00", "01:00", "02:00", "03:00", "04:00", "05:00",
    "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
    "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
    "18:00", "19:00", "20:00", "21:00", "22:00", "23:00",
]

function cdsretrieve_time(e5ds::ERA5Monthly)

    if e5ds.hours
        return [
            "00:00", "01:00", "02:00", "03:00", "04:00", "05:00",
            "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
            "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
            "18:00", "19:00", "20:00", "21:00", "22:00", "23:00",
        ]
    else
        return "00:00"
    end
    
end