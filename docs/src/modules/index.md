# The `ERA5Module` superType

ERA5 reanalysis data is stored on the Climate Data Store in several different categories, so different people with different needs may access different data types depending on their research.  In ERA5Reanalysis, we defined these datasets as `ERA5Module` Types.

When defining an `ERA5Module` container, we also indicate the start and end dates of the dataset that we want to work on.

```@docs
ERA5Module
```

## Available Modules in ERA5Reanalysis.jl

The following datasets are currently supported by ERA5Reanalysis.jl:
* Hourly reanalysis data (`ERA5Hourly`)
* Monthly reanalysis data, which is further broken down in
    * Monthly-averaged data (`ERA5Monthly`)
    * Monthly-averaged hourly data (i.e. a monthly average of the diurnal cycle) (`ERA5MonthlyHour`)

```@docs
ERA5Hourly
ERA5Monthly
ERA5MonthlyHour
```

There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations

## Functions to create `ERA5Module`s

There are two functions used to create `ERA5Module`s:
* `ERA5Hourly()`, which creates the `ERA5Hourly` subtype
* `ERA5Monthly()`, which creates either the `ERA5Monthly` or `ERA5MonthlyHour` subtypes depending on inputs

```@docs
ERA5Hourly(;
        dtbeg :: TimeType,
        dtend :: TimeType,
        eroot :: AbstractString = homedir(),
    )
```
```@docs
ERA5Monthly(;
    dtbeg :: TimeType,
    dtend :: TimeType,
    eroot :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
)
```