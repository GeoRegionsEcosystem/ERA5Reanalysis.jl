function cdsretrieve(
    e5ds :: ERA5CDStore,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    grib :: Bool,
    overwrite :: Bool
)

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.name)) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(e5ds.start) to $(e5ds.stop)."

    for dtii in dtvec

        if !grib
            format = "netcdf"
            fnc = e5dfnc(e5ds,evar,ereg,dtii)
        else
            format = "grib"
            fnc = e5dgrib(e5ds,evar,ereg,dtii)
        end
        fol = dirname(fnc); if !isdir(fol); mkpath(fol) end

        

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => evar.long,
            "grid"         => [ereg.resolution, ereg.resolution],
            "time"         => cdsretrieve_time(e5ds),
            "format"       => format,
        )

        if typeof(e5ds) <: ERA5Hourly
            e5dkey["day"] = collect(1:31)
        end

        if typeof(evar) <: PressureVariable
            e5dkey["pressure_level"] = evar.hPa
        end
        
        cdsretrieve_area!(e5dkey,ereg)
        
        if !isfile(fnc) || overwrite
            tryretrieve = 0
            while isinteger(tryretrieve) && (tryretrieve < 20)
                try
                    retrieve(cdsretrieve_dataset(evar,e5ds),e5dkey,fnc,ckeys)
                    tryretrieve += 0.5
                catch
                    tryretrieve += 1
                    @info "$(modulelog()) - Failed to retrieve/request data from CDSAPI on Attempt $(tryretrieve) of 20"
                end
            end
            if tryretrieve == 20
                @warn "$(modulelog()) - Failed to retrieve/request data, skipping to next set of requests"
            end
        end

        flush(stderr)

    end

end

function cdsretrieve(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    pvec :: Vector{Int},
    overwrite :: Bool
)

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Preallocation of temporary data arrays to split downloaded data into their respective pressure levels ..."

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    tmpd = zeros(Int16,nlon,nlat,31*24)

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.name)) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(e5ds.start) to $(e5ds.stop)."

    for dtii in dtvec

        inc = e5dfnc(e5ds,PressureVariable(evar.ID,hPa=pvec[1]),ereg,dtii)
        fnc = "tmp-$(Dates.now()).nc"
        fol = dirname(inc); if !isdir(fol); mkpath(fol) end

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => evar.long,
            "grid"         => [ereg.resolution, ereg.resolution],
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

        if !isfile(inc) || overwrite
            tryretrieve = 0
            while isinteger(tryretrieve) && (tryretrieve < 20)
                try
                    retrieve(cdsretrieve_dataset(evar,e5ds),e5dkey,fnc,ckeys)
                    tryretrieve += 0.5
                catch
                    tryretrieve += 1
                    @info "$(modulelog()) - Failed to retrieve/request data from CDSAPI on Attempt $(tryretrieve) of 20"
                end
            end
            if tryretrieve == 20
                @warn "$(modulelog()) - Failed to retrieve/request data, skipping to next set of requests"
            end
            split(e5ds,evar,ereg,lsd,dtii,pvec,fnc,tmpd)
        end

        flush(stderr)

    end

end

function cdsretrievegrib(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    pvec :: Vector{Int},
    overwrite :: Bool
)

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.name)) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(e5ds.start) to $(e5ds.stop)."

    for dtii in dtvec

        fnc = e5dgrib(e5ds,evar,ereg,dtii,pvec)
        fol = dirname(fnc); if !isdir(fol); mkpath(fol) end

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => evar.long,
            "grid"         => [ereg.resolution, ereg.resolution],
            "time"         => cdsretrieve_time(e5ds),
            "format"       => "grib",
        )

        if typeof(e5ds) <: ERA5Hourly
            e5dkey["day"] = collect(1:31)
        end

        if typeof(evar) <: PressureVariable
            e5dkey["pressure_level"] = pvec
        end
        
        cdsretrieve_area!(e5dkey,ereg)

        if !isfile(fnc) || overwrite
            tryretrieve = 0
            while isinteger(tryretrieve) && (tryretrieve < 20)
                try
                    retrieve(cdsretrieve_dataset(evar,e5ds),e5dkey,fnc,ckeys)
                    tryretrieve += 0.5
                catch
                    tryretrieve += 1
                    @info "$(modulelog()) - Failed to retrieve/request data from CDSAPI on Attempt $(tryretrieve) of 20"
                end
            end
            if tryretrieve == 20
                @warn "$(modulelog()) - Failed to retrieve/request data, skipping to next set of requests"
            end
        end

        flush(stderr)

    end

end

function cdsretrieve(
    e5ds :: ERA5CDStore,
    evar :: Vector{SingleVariable{ST}},
    ereg :: ERA5Region,
    overwrite :: Bool,
) where ST <: AbstractString

    dtvec = cdsretrieve_dtvec(e5ds)
    ckeys = cdskey()

    @info "$(modulelog()) - Using CDSAPI in Julia to download $(uppercase(e5ds.name)) $([evarii.lname for evarii in evar]) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) from $(e5ds.start) to $(e5ds.stop)."

    lsd  = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    tmpd = zeros(Int16,nlon,nlat,31*24)

    for dtii in dtvec

        inc = e5dfnc(e5ds,evar[1],ereg,dtii)
        fnc = "tmp-$(Dates.now()).nc"
        fol = dirname(inc); if !isdir(fol); mkpath(fol) end

        e5dkey = Dict(
            "product_type" => e5ds.ptype,
            "year"         => year(dtii),
            "month"        => cdsretrieve_month(dtii,e5ds),
            "variable"     => [evarii.lname for evarii in evar],
            "grid"         => [ereg.resolution, ereg.resolution],
            "time"         => cdsretrieve_time(e5ds),
            "format"       => "netcdf",
        )

        if typeof(e5ds) <: ERA5Hourly
            e5dkey["day"] = collect(1:31)
        end
        
        cdsretrieve_area!(e5dkey,ereg)
        
        if !isfile(inc) || overwrite
            tryretrieve = 0
            while isinteger(tryretrieve) && (tryretrieve < 20)
                try
                    retrieve(cdsretrieve_dataset(evar[1],e5ds),e5dkey,fnc,ckeys)
                    tryretrieve += 0.5
                catch
                    tryretrieve += 1
                    @info "$(modulelog()) - Failed to retrieve/request data from CDSAPI on Attempt $(tryretrieve) of 20"
                end
            end
            if tryretrieve == 20
                @warn "$(modulelog()) - Failed to retrieve/request data, skipping to next set of requests"
            end
            split(e5ds,evar,ereg,lsd,dtii,fnc,tmpd)
        end

        flush(stderr)

    end

end


cdsretrieve_dtvec(e5ds::ERA5Hourly)  = e5ds.start : Month(1) : e5ds.stop
cdsretrieve_dtvec(e5ds::ERA5Monthly) = e5ds.start : Year(1)  : e5ds.stop

cdsretrieve_dataset(evar::ERA5Variable,::ERA5Hourly)  = evar.dataset
cdsretrieve_dataset(evar::ERA5Variable,::ERA5Monthly) = evar.dataset * "-monthly-means"

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