# Climate Data Store Datasets

CDS Datasets are represented by the `ERA5CDStore` AbstractType, which includes `ERA5Hourly` and `ERA5Monthly` datasets. These datasets can be downloaded directly from the Climate Data Store using the CDSAPI.

The Types that each dataset calls are listed below, along with their function calls.

|      Type       |    Resolution    |       Function       |
| :-------------: | :--------------: | :------------------: |
|  `ERA5Hourly`   |     Hourly       |    `ERA5Hourly()`    |
|  `ERA5Monthly`  |     Monthly      |   `ERA5Monthly()`    |
| `ERA5MonthlyHour` | Monthly by Hour | `ERA5Monthly(hours=...)` |

### Setup
```@example cds
using ERA5Reanalysis
```

## Creating an `ERA5Hourly` dataset

The `ERA5Hourly` dataset structure is used to contain information regarding hourly ERA5 datasets.

```@example cds
e5ds = ERA5Hourly(start=Date(2017,2,1),stop=Date(2017,2,4))
```
```@example cds
typeof(e5ds)
```

!!! warning
    `ERA5Hourly` datasets are designed to process data by whole-months. It is not possible to specify specific days for download - the entire month will be downloaded.

## Creating an `ERA5Monthly` dataset

The `ERA5Monthly` dataset structure is used to contain information regarding monthly-averaged ERA5 datasets.

```@example cds
e5ds = ERA5Monthly(start=Date(2017,2,5),stop=Date(2017,6,9))
```
```@example cds
typeof(e5ds)
```

!!! warning
    `ERA5Monthly` datasets are designed to process data by years. The `start` and `stop` fields define the full years of data.

## Creating an `ERA5MonthlyHour` dataset

The Climate Data Store also provides ERA5 Monthly data by hour-of-day. This is accessed via the `ERA5Monthly` function by specifying the `hours` argument:

```@example cds
e5ds = ERA5Monthly(start=Date(2017,1,2),stop=Date(2018,5,1),hours=[0,6,12,18])
```
```@example cds
typeof(e5ds)
```

## Future Datasets

There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as:
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations

They have not been added yet into ERA5Reanalysis.jl. If you are potentially interested in having these datasets added, please [submit a pull request](https://github.com/GeoRegionsEcosystem/ERA5Reanalysis.jl/pulls).

## API

```@docs
ERA5Hourly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
ERA5Monthly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
)
```
