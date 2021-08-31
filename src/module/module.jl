struct ERA5Hourly{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

struct ERA5Monthly{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

struct ERA5MonthlyHour{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
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

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Hourly data to be downloaded"
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

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Monthly data to be downloaded"
    dtbeg = Date(year(dtbeg),1,1)
    dtend = Date(year(dtend),12,31)
    checkdates(dtbeg,dtend,throw)

    if isinteger(hours)
        if (hours<0)
            @info "$(modulelog()) - No hour of day was specified, and therefore retrieving monthly-averaged data"
            return ERA5Monthly{ST,DT}("era5mo",dtbeg,dtend,eroot)
        else
            @info "$(modulelog()) - An hour of day ($(hours):00:00) was specified, and therefore retrieving monthly-averaged hourly data"
            return ERA5MonthlyHour{ST,DT}("era5mh",dtbeg,dtend,[hours],eroot)
        end
    else
        hours = sort(unique(mod.(hours,24)))
        @info "$(modulelog()) - Hours of day $(hours) were specified, and therefore retrieving monthly-averaged hourly data for these hours"
        return ERA5MonthlyHour{ST,DT}("era5mh",dtbeg,dtend,hours,eroot)
    end

end

function checkdates(
    dtbeg :: TimeType,
    dtend :: TimeType,
    throw :: Bool
)

    if dtend > (now() - Day(5))
        error("$(modulelog()) - You have specified an end date that is in the future of the latest available date of the ERA5 reanalysis dataset")
    end

    if dtend > dtbeg
        error("$(modulelog()) - You have specified an end date that is before your beginning date")
    end

    if (dtbeg < Date(1979,1,1)) || (dtend < Date(1979,1,1))
        error("$(modulelog()) - You have specified a date (be it `dtbeg` or `dtend`) that is before the earliest available date of ERA5 reanalysis data")
    end

end