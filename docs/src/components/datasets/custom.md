# Custom ERA5 Datasets defined in ERA5Reanalysis.jl

We also have created a custom `ERA5Daily` dataset, which is a daily-average of the hourly data from `ERA5Hourly` data.

```@docs
ERA5Daily
```

In order to create the ERA5 daily datasets from an ERA5Hourly dataset, use the `hour2day` function as below:

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015),path=datadir())
evar = SingleVariable("t2m")
egeo = GeoRegion("TRP")
hourly2daily(e5ds,evar,egeo)
```

## API

```@docs
ERA5Daily(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
```
