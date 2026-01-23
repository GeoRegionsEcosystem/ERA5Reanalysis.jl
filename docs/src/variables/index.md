# Variable Types in ERA5Reanalysis.jl

In order to download data from the Climate Data Store, we need to specify at least a variable to download. This variable can be one found directly from CDS, or it can be a custom user-defined variable (in which case it has to be calculated by the user). Information regarding this variable will be loaded into an `ERA5Variable`.

### Setup
```@example variables
using ERA5Reanalysis
```

## The `ERA5Variable` Type

```@docs
ERA5Variable
```

## `SingleLevel` and `PressureLevel` Variables

There are two main `ERA5Variable` types in ERA5 reanalysis:
* `SingleLevel` variables - such as surface temperature, or total cloud cover, provided in the (lon, lat) space
* `PressureLevel` variables - such as atmospheric temperature, or specific humidity, provided in the (lon, lat, pressure) space

|    SuperType     |    CDS Variable   |  Custom Variable   |
| :--------------: | :---------------: | :----------------: |
|  `SingleLevel`   | `SingleVariable`  |  `SingleCustom`    |
| `PressureLevel`  | `PressureVariable`| `PressureCustom`   |

```@docs
ERA5Reanalysis.SingleLevel
ERA5Reanalysis.PressureLevel
```

## Custom `ERA5Variable`s

Each of these supertypes are further broken down into `XXVariable` and `XXCustom` subtypes:
* `XXVariable` represents a variable that is available directly from CDS
* `XXCustom` variables are user-defined variables

!!! warning
    `XXCustom` variables cannot be downloaded - trying to do so will result in a `method` error - and can only be calculated from existing variable data.

```@docs
ERA5Reanalysis.SingleVariable
ERA5Reanalysis.SingleCustom
ERA5Reanalysis.PressureVariable
ERA5Reanalysis.PressureCustom
```
