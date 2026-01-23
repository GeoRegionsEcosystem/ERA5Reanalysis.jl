# The Basics of ERA5Reanalysis.jl

There are three essential components in ERA5Reanalysis.jl:

* An ERA5 dataset of interest (i.e., an `ERA5Dataset` `e5ds`)
* An ERA5 variable of interest (i.e., an `ERA5Variable` `evar`)
* A geographic region of interest (i.e., an `ERA5Region` `ereg`)

With these three components, you can perform the following actions:

* Download data of interest using `download(e5ds, evar, ereg)`
* Read downloaded data using `read(e5ds, evar, ereg, dt)`
* Perform basic analysis on the data

## The `ERA5Dataset` Type

All `ERA5Dataset` types _(except for the Dummy types)_ contain the following information:
* `start` - The beginning of the date-range of our data of interest
* `stop` - The end of the date-range of our data of interest
* `path` - The data directory in which our dataset is saved into

```@docs
ERA5Dataset
```

## The `ERA5Variable` Type

An `ERA5Variable` specifies the meteorological variable to download or analyze. There are two main types:
* `SingleLevel` variables - provided in the (lon, lat) space (e.g., surface temperature, total cloud cover)
* `PressureLevel` variables - provided in the (lon, lat, pressure) space (e.g., atmospheric temperature, specific humidity)

```@docs
ERA5Variable
```

## The `ERA5Region` Type

An `ERA5Region` defines the geometry of your geographical region of interest, built on top of the `GeoRegion` functionality in [GeoRegions.jl](https://github.com/GeoRegionsEcosystem/GeoRegions.jl). It additionally specifies the resolution at which the data will be downloaded/analyzed.

```@docs
ERA5Region
```
