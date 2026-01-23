# Custom ERA5 Datasets

ERA5Reanalysis.jl provides custom dataset types that are derived from the CDS datasets. Currently, we have created a custom `ERA5Daily` dataset, which is a daily-average of the hourly data from `ERA5Hourly` data.

### Setup
```@example custom
using ERA5Reanalysis
```

## The `ERA5Daily` Dataset

The `ERA5Daily` dataset structure is used to contain information regarding daily-averaged ERA5 data. This data is not available directly from the CDS, but is computed from `ERA5Hourly` data.

```@example custom
e5ds = ERA5Daily(start=Date(2015),stop=Date(2015),path=homedir())
```
```@example custom
typeof(e5ds)
```

## Creating Daily Data from Hourly Data

In order to create the ERA5 daily datasets from an `ERA5Hourly` dataset, use the `hourly2daily` function:

```julia
using ERA5Reanalysis
e5ds = ERA5Hourly(start=Date(2015),stop=Date(2015),path=datadir())
evar = SingleVariable("t2m")
ereg = ERA5Region(GeoRegion("TRP"))
hourly2daily(e5ds,evar,ereg)
```

This will compute the daily averages from the hourly data and save them in the appropriate directory structure.

## API

```@docs
ERA5Daily
ERA5Daily(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
```
