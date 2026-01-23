# Defining ERA5 Datasets

Defining an `ERA5Dataset` is easy. All you need to define are two things:
1. Date range, ranging from `start` to `stop`
2. Data `path`, i.e. where you want to save the ERA5 Reanalysis Data

```julia
DatasetFunction(
    start = Date(),
    stop  = Date(),
    path  = ...
)
```

### Setup
```@example define
using ERA5Reanalysis
```

## Example for an Hourly Dataset

See below for an example of defining an `ERA5Hourly` dataset:

```@example define
e5ds = ERA5Hourly(start=Date(2017,2,1),stop=Date(2017,2,1),path=homedir())
```
```@example define
e5ds.start
```
```@example define
e5ds.stop
```
```@example define
typeof(e5ds)
```
```@example define
typeof(e5ds) <: ERA5Dataset
```

Note that the resultant `ERA5Hourly` dataset processes data by whole-months. It is not possible to specify specific days in which to download data.

## Example for a Monthly Dataset

And below for an example of defining an `ERA5Monthly` dataset with a custom home directory:

```@example define
e5ds = ERA5Monthly(start=Date(2017,1,2),stop=Date(2018,5,1),path=pwd())
```
```@example define
e5ds.start
```
```@example define
e5ds.stop
```
```@example define
typeof(e5ds)
```

Note that the resultant `ERA5Monthly` dataset processes data by years. It is not possible to specify specific months in which to download data. The same holds true for the `ERA5MonthlyHour` dataset.

## Example for a Monthly-Hour Dataset

```@example define
e5ds = ERA5Monthly(start=Date(2017,1,2),stop=Date(2018,5,1),hours=[0,3,6,9,12,15,18,21])
```
```@example define
typeof(e5ds)
```
