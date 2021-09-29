"""
    ERA5Hourly <: ERA5Module

Specifies that the dataset to be analyzed contains hourly data.  All fields are the same as that specified in the `ERA5Module` docstring.
"""
struct ERA5Hourly{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

"""
    ERA5Monthly <: ERA5Module

Specifies that the dataset to be analyzed contains monthly-mean data.  All fields are the same as that specified in the `ERA5Module` docstring.
"""
struct ERA5Monthly{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
    dtbeg :: Date
    dtend :: Date
    eroot :: ST
end

"""
    ERA5MonthlyHour <: ERA5Module

Specifies that the dataset to be analyzed contains monthly-mean hourly data.  There is one additional field compared to ERA5Module:

Additional fields
=================
- `hours` : A vector of integers containing the hours-of-day to be downloaded/analyzed.
"""
struct ERA5MonthlyHour{ST<:AbstractString, DT<:TimeType} <: ERA5Module
    modID :: ST
    dtbeg :: Date
    dtend :: Date
    hours :: Vector{Int}
    eroot :: ST
end

"""
    ERA5Hourly(;
        dtbeg :: TimeType,
        dtend :: TimeType,
        eroot :: AbstractString = homedir(),
    ) -> ERA5Hourly <: ERA5Module

A function that creates an `ERA5Hourly` module.

Keyword Arguments
=================
- `eroot` : The specified directory in which to save the data
- `dtbeg` : The date for which downloads/analysis begins, automatically rounded to the nearest month
- `dtend` : The date for which downloads/analysis finishes, automatically rounded to the nearest month
"""
function ERA5Hourly(
    ST = String,
    DT = Date;
    dtbeg :: TimeType,
    dtend :: TimeType,
    eroot :: AbstractString = homedir(),
)

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Hourly data to be downloaded"
    dtbeg = Date(year(dtbeg),month(dtbeg),1)
	dtend = Date(year(dtend),month(dtend),daysinmonth(dtend))
    checkdates(dtbeg,dtend,)

    return ERA5Hourly{ST,DT}("era5hr",dtbeg,dtend,eroot)

end

"""
    ERA5Monthly(;
        dtbeg :: TimeType,
        dtend :: TimeType,
        eroot :: AbstractString = homedir(),
        hours :: Union{Int,Vector{Int}} = -1,
    ) -> ERA5Monthly <: ERA5Module or ERA5MonthlyHour <: ERA5Module

A function that creates an `ERA5Monthly` or `ERA5MonthlyHour` module depending on the input arguments of `hours`.

Keyword Arguments
=================
- `eroot` : The specified directory in which to save the data
- `dtbeg` : The date for which downloads/analysis begins, automatically rounded to the nearest year
- `dtend` : The date for which downloads/analysis finishes, automatically rounded to the nearest year
- `hours` : If `hours` < 0 or > 24, then it is assumed that we simply want monthly-averages without resolution on hour-of-day and we return an `ERA5Monthly` type.  Otherwise, if an `Int` specifying a single hour-of-day (0-24), or a vector of `Int`s specifying multiple hours of days, then returns an `ERA5MonthlyHour` type.
"""
function ERA5Monthly(
    ST = String,
    DT = Date;
    dtbeg :: TimeType,
    dtend :: TimeType,
    eroot :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
)

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Monthly data to be downloaded"
    dtbeg = Date(year(dtbeg),1,1)
    dtend = Date(year(dtend),12,31)
    checkdates(dtbeg,dtend)

    if typeof(hours) <: Int
        if (hours<0) || (hours>24)
            @info "$(modulelog()) - No valid hour of day was specified, and therefore retrieving monthly-averaged data"
            return ERA5Monthly{ST,DT}("era5mo",dtbeg,dtend,eroot)
        else
            if hours == 24; hours = 0 end
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
    dtend :: TimeType
)

    if dtend > (now() - Day(5))
        error("$(modulelog()) - You have specified an end date that is in the future of the latest available date of the ERA5 reanalysis dataset")
    end

    if dtend < dtbeg
        error("$(modulelog()) - You have specified an end date that is before your beginning date")
    end

    if (dtbeg < Date(1979,1,1)) || (dtend < Date(1979,1,1))
        error("$(modulelog()) - You have specified a date (be it `dtbeg` or `dtend`) that is before the earliest available date of ERA5 reanalysis data")
    end

end