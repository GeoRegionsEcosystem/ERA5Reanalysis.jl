# Custom `PressureLevel` variables

In ERA5Reanalysis.jl, we have predefined all the pressure-level variables that are available directly from the CDS.  As such, all custom `PressureLevel` variables are defined under the `PressureCustom` type.

## Defining Custom `PressureLevel` Variables

`PressureCustom` variables are defined using the `PressureVariable()` function, as follows:
```@docs
PressureVariable(
    ST = String;
    varID :: AbstractString,
    lname :: AbstractString = "",
    vname :: AbstractString,
    units :: AbstractString,
    hPa   :: Int = 0,
    throw :: Bool = true
)
```

## Removing Custom `PressureLevel` Variables

To remove a `PressureCustom` variable, we can use the `rmPressure()` function:
```@docs
rmPressure( varID :: AbstractString )
```

## An Example!

Let us define the custom variable "vt" for Virtual Temperature, which is a proxy to buoyancy in the atmosphere.  Virtual Temperature is calculated from both the water vapour mixing ratio and atmospheric temperature and is given by the formula:

$$T_v = T(1+0.61q)$$

Virtual Temperature has the units "K", and for this example let us define the pressure level height we are interested in to be at 1000 hPa.  The resultant `PressureCustom` variable is given by:

```@repl
using ERA5Reanalysis
PressureVariable(
    varID = "vt",
    units = "K",
    hPa   = 1000,
    lname = "virtual_temperature",
    vname = "Virtual Temperature"
)
tablePressures()
rmPressure("vt")
isPressure("vt",throw=false) # don't throw error, just show warning
```