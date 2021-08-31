# The Basic Components of ERA5Reanalysis.jl

There are three essential components to specifying an ERA5 reanalysis dataset:
1. The ERA5 module (hourly, monthly, month-by-hour, etc.), held in an `ERA5Module` supertype
2. The ERA5 variable (single-level, or pressure-level), held in the `ERA5Variable` supertype
3. The ERA5 region to be downloaded/analyzed, held in an `ERA5Region` supertype, built over a `GeoRegion`

## The `ERA5Module` superType

ERA5 reanalysis data is stored on the Climate Data Store in several different categories, so different people with different needs may access different data types depending on their research.  ERA5Reanalysis.jl distinguishes between the modules that are most often called using the `ERA5Module` superType:
* Hourly reanalysis data
* Monthly reanalysis data, which is further broken down in
    * Monthly-averaged data
    * Monthly-averaged hourly data (i.e. a monthly average of the diurnal cycle)

```@docs
ERA5Module
```

There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations

More information on the different Types of `ERA5Module`s can be found [here](modules.md).

## The `ERA5Variable` superType

There are two main variable types in ERA5 reanalysis:
* Single-Level variables, such as surface temperature, or total cloud cover, that are provided in the (lon,lat) space
* Pressure-Level variables, such as atmospheric temperature, or specific humidity, that are provided in the (lon,lat,pressure) space.

In ERA5Reanalysis.jl, information regarding a specific ERA5 variable will be loaded into an `ERA5Variable` Type, with more specifics given [here](variables.md)

```@docs
ERA5Variable
```

## The `ERA5Region` superType

Finally, in order to specify an area for ERA5Reanalysis.jl to conduct downloads, or analyse data over, we need to specify an `ERA5Region`, which is built on top of the `GeoRegion` Type in [GeoRegions.jl](https://github.com/JuliaClimate/GeoRegions.jl).

```@docs
ERA5Region
```