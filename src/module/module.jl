struct ERA5Hourly{ST<:AbstractString, DT<:TimeType} <: ERA5Dataset
    e5dID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

struct ERA5Monthly{ST<:AbstractString, DT<:TimeType} <: ERA5Dataset
    e5dID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

struct ERA5MonthlyHour{ST<:AbstractString, DT<:TimeType} <: ERA5Dataset
    e5dID :: ST
    dtbeg :: Date
    dtend :: Date
    hours :: Vector{Int}
    eroot :: ST
end

function ERA5Hourly(
    ST = String,
    DT = Date;
    dtbeg :: TimeType,
    dtend :: TimeType,
    eroot :: AbstractString = homedir(),
    throw :: Bool = true
)

    dtbeg = Date(year(dtbeg),month(dtbeg),1)
	dtend = Date(year(dtend),month(dtend),daysinmonth(dtend))
    checkdates(dtbeg,dtend,throw)

    return ERA5Hourly{ST,DT}("era5hr",dtbeg,dtend,eroot)

end

function ERA5Monthly(
    ST = String,
    DT = Date;
    dtbeg :: TimeType,
    dtend :: TimeType,
    eroot :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
    throw :: Bool = true
)

    dtbeg = Date(year(dtbeg),1,1)
    dtend = Date(year(dtend),12,31)
    checkdates(dtbeg,dtend,throw)

    if isinteger(hours)
        if (hours<0)
              return ERA5Monthly{ST,DT}("era5mo",dtbeg,dtend,eroot)
        else; return ERA5MonthlyHour{ST,DT}("era5mh",dtbeg,dtend,[hours],eroot)
        end
    else
        hours = sort(unique(mod.(hours,24)))
        return ERA5MonthlyHour{ST,DT}("era5mh",dtbeg,dtend,hours,eroot)
    end

end