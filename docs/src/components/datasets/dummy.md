# Custom ERA5 Datasets defined in ERA5Reanalysis.jl
We also have created a custom `ERA5Daily` dataset, which is a daily-average of the hourly data from `ERA5Hourly` data.

```@docs
ERA5Daily
```

```@docs
ERA5Daily(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
```
There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations

## API


