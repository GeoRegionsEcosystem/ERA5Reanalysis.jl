"""
    ERA5Hourly <: ERA5CDStore

Specifies that the dataset to be analyzed contains hourly data.  All fields are the same as that specified in the `ERA5Dataset` docstring.
"""
struct ERA5Hourly{ST<:AbstractString, DT<:TimeType} <: ERA5CDStore
    ID    :: ST
    name  :: ST
    ptype :: ST
	sldoi :: ST
	pldoi :: ST
    start :: Date
    stop  :: Date
    path  :: ST
    emask :: ST
end

"""
    ERA5Daily <: ERA5Custom

Specifies that the dataset to be analyzed contains hourly data.  All fields are the same as that specified in the `ERA5Dataset` docstring.  However, the fields `sldoi`, `pldoi` and `ptype` are all set to `N/A` because `ERA5Daily` is not available in, nor downloadable from, the Climate Data Store.
"""
struct ERA5Daily{ST<:AbstractString, DT<:TimeType} <: ERA5Custom
    ID    :: ST
    name  :: ST
    ptype :: ST
	sldoi :: ST
	pldoi :: ST
    start :: Date
    stop  :: Date
    path  :: ST
    emask :: ST
end

"""
    ERA5Monthly <: ERA5CDStore

Specifies that the dataset to be analyzed contains monthly-mean data.  The `ERA5Monthly` Type will also contain the following fields:
- `hours` : specifies the hour(s) of day for which monthly data is downloaded
"""
struct ERA5Monthly{ST<:AbstractString, DT<:TimeType} <: ERA5CDStore
    ID    :: ST
    name  :: ST
    ptype :: ST
	sldoi :: ST
	pldoi :: ST
    start :: Date
    stop  :: Date
    hours :: Bool
    path  :: ST
    emask :: ST
end

"""
    ERA5Dummy <: ERA5Dataset

The ERA5Dummy dataset contains only information on the data and mask paths.
"""
struct ERA5Dummy{ST<:AbstractString} <: ERA5Dataset
    path  :: ST
    emask :: ST
end

"""
    ERA5Hourly(;
        start :: TimeType,
        stop  :: TimeType,
        path  :: AbstractString = homedir(),
    ) -> ERA5Hourly <: ERA5Dataset

A function that creates an `ERA5Hourly` module.  All possible hours are downloaded, and data is saved month-by-month.

Keyword Arguments
=================
- `path` : The specified directory in which to save the data
- `start` : The date for which downloads/analysis begins, automatically rounded to the nearest month
- `stop` : The date for which downloads/analysis finishes, automatically rounded to the nearest month
"""
function ERA5Hourly(
    ST = String,
    DT = Date;
    start :: TimeType = now() - Month(3),
    stop  :: TimeType = now() - Month(3),
    path  :: AbstractString = homedir(),
)

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Hourly data to be downloaded"
    start = Date(year(start),month(start),1)
	stop = Date(year(stop),month(stop),daysinmonth(stop))
    dtext = checkdates(start,stop,)

    if !isdir(joinpath(path,"era5hr"))
        mkpath(joinpath(path,"era5hr"))
    end

    if !isdir(joinpath(path,"emask"))
        mkpath(joinpath(path,"emask"))
    end

    return ERA5Hourly{ST,DT}(
        "era5hr","ERA5 Hourly","reanalysis",
        "10.24381/cds.adbb2d47","10.24381/cds.bd0915c6",
        start,stop,dtext,
        joinpath(path,"era5hr"),joinpath(path,"emask")
    )

end

"""
    ERA5Daily(;
        start :: TimeType,
        stop  :: TimeType,
        path  :: AbstractString = homedir(),
    ) -> ERA5Daily <: ERA5Dataset

A function that creates an `ERA5Hourly` module.  All possible hours are downloaded, and data is saved month-by-month.

Keyword Arguments
=================
- `path` : The specified directory in which to save the data
- `start` : The date for which downloads/analysis begins, automatically rounded to the nearest month
- `stop` : The date for which downloads/analysis finishes, automatically rounded to the nearest month
"""
function ERA5Daily(
    ST = String,
    DT = Date;
    start :: TimeType = now() - Month(3),
    stop  :: TimeType = now() - Month(3),
    path  :: AbstractString = homedir(),
)

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Daily data to be created from ERA5 Hourly data"
    start = Date(year(start),month(start),1)
	stop = Date(year(stop),month(stop),daysinmonth(stop))
    dtext = checkdates(start,stop,)

    if !isdir(joinpath(path,"era5dy"))
        mkpath(joinpath(path,"era5dy"))
    end

    if !isdir(joinpath(path,"emask"))
        mkpath(joinpath(path,"emask"))
    end

    return ERA5Daily{ST,DT}(
        "era5dy","ERA5 Daily","N/A",
        "N/A","N/A",
        start,stop,
        joinpath(path,"era5dy"),joinpath(path,"emask")
    )

end

"""
    ERA5Monthly(;
        start :: TimeType,
        stop  :: TimeType,
        path  :: AbstractString = homedir(),
        hours :: Bool = false,
    ) -> ERA5Monthly <: ERA5Dataset or ERA5MonthlyHour <: ERA5Dataset

A function that creates an `ERA5Monthly` or `ERA5MonthlyHour` module depending on the input arguments of `hours`.  Data is saved year-by-year.

Keyword Arguments
=================
- `path` : The specified directory in which to save the data
- `start` : The date for which downloads/analysis begins, automatically rounded to the nearest year
- `stop` : The date for which downloads/analysis finishes, automatically rounded to the nearest year
- `hours` : If false, download monthly-averaged data. If true, download monthly-averaged data for each hour
"""
function ERA5Monthly(
    ST = String,
    DT = Date;
    start :: TimeType = now() - Month(3),
    stop  :: TimeType = now() - Month(3),
    path  :: AbstractString = homedir(),
    hours :: Bool = false,
)

    @info "$(modulelog()) - Setting up data structure containing information on the ERA5 Monthly data to be downloaded"
    start = Date(year(start),1,1)
    stop = Date(year(stop),12,31)
    dtext = checkdates(start,stop)

    if !isdir(joinpath(path,"emask"))
        mkpath(joinpath(path,"emask"))
    end

    if hours

        if !isdir(joinpath(path,"era5mh"))
            mkpath(joinpath(path,"era5mh"))
        end

        return ERA5Monthly{ST,DT}(
            "era5mh","ERA5 Monthly Averages (by Hour-of-Day)",
            "monthly_averaged_reanalysis_by_hour_of_day",
            "10.24381/cds.f17050d7","10.24381/cds.6860a573",
            start,stop,dtext,true,
            joinpath(path,"era5mh"),joinpath(path,"emask")
        )

    else

        if !isdir(joinpath(path,"era5mo"))
            mkpath(joinpath(path,"era5mo"))
        end

        return ERA5Monthly{ST,DT}(
            "era5mo","ERA5 Monthly Averages",
            "monthly_averaged_reanalysis",
            "10.24381/cds.f17050d7","10.24381/cds.6860a573",
            start,stop,dtext,false,
            joinpath(path,"era5mo"),joinpath(path,"emask")
        )

    end

end

"""
    ERA5Dummy(;
        path  :: AbstractString = homedir(),
    ) -> ERA5Dummy <: ERA5Dataset

A function that creates a dummy `ERA5Dataset` that contains only information on the path of the ERA5 LandSea mask

Keyword Arguments
=================
- `path` : The specified directory in which to save the data
"""
function ERA5Dummy(
    ST = String;
    path :: AbstractString = homedir(),
)

    @info "$(modulelog()) - Setting up data structure for the ERA5 Dummy Dataset"
    if !isdir(path); mkpath(path) end
    if !isdir(joinpath(path,"emask"))
        mkpath(joinpath(path,"emask"))
    end

    return ERA5Dummy{ST}(path,joinpath(path,"emask"))
     
end

function checkdates(
    start :: TimeType,
    stop  :: TimeType
)

    dtext = false

    if stop > (now() - Day(5))
        error("$(modulelog()) - You have specified an end date that is likely in the future of the latest available date of the ERA5 reanalysis dataset")
    end

    if stop < start
        error("$(modulelog()) - You have specified an end date that is before your beginning date")
    end

    if start < Date(1950,1,1)
        error("$(modulelog()) - You have specified a date that is before the earliest available date of preliminary ERA5 reanalysis dataset from 1950 to 1978")
    end

    if start < Date(1979,1,1)
        @info "$(modulelog()) - You have specified the preliminary back-extension ERA5 reanalysis dataset from 1950 to 1978"
        if stop >= Date(1979,1,1)
            error("$(modulelog()) - You have specified an end date that is outside the range of the preliminary back-extension (i.e. it is within the actual reanalysis dataset) and must be specified separately")
        end
        dtext = true
    end

    return dtext

end