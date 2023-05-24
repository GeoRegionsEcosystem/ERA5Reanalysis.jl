# The `ERA5Dataset` superType

ERA5 reanalysis data is stored on the Climate Data Store in several different categories, so different people with different needs may access different data types depending on their research.  In ERA5Reanalysis, we defined these datasets as `ERA5Dataset` Types.

When defining an `ERA5Dataset` container, we also indicate the start and end dates of the dataset that we want to work on.

```@docs
ERA5Dataset
```

## Available in the Climate Data Store (CDS)
The following datasets are currently available by default in the Climate Data Store:
* Hourly reanalysis data (`ERA5Hourly`)
* Monthly reanalysis data, (`ERA5Monthly`)

!!! note
    The Climate Data Store also has an option to download ERA5 Monthly data by hour-of-day. This is subsumed into the ERA5Monthly dataset and can be selected by specifying `hours = true`.

```@docs
ERA5Hourly
ERA5Hourly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
ERA5Monthly
ERA5Monthly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
)
```

## Custom ERA5Reanalysis.jl Dataset, not available in CDS
We also have created a custom `ERA5Daily` dataset, which is a daily-average of the hourly data from `ERA5Hourly` data.

```@docs
ERA5Daily
```

!!! warning
    Because the Climate Data Store does not provide daily data by default, the `download()` functionality cannot be used for this `ERA5Dataset` type.

There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations