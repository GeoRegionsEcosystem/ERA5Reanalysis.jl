# Reading in Pre-existing `ERA5Variable` Information

In order to familiarize ourselves with using `ERA5Variable`s, we load some of the pre-existing variables that are prepackaged with ERA5Reanalysis.jl.

## Loading Single-Level Variable Information

The easiest example is to load a single-level variable using the `SingleVariable()` function, for example the u-component of wind 100m above the surface:
```@docs
SingleVariable(
    varID :: AbstractString,
    ST = String,
)
```

!!! note
    As of v0.3 and above, all Single-Level variables available in the CDS are available by default in ERA5Reanalysis.jl.

```@repl
using ERA5Reanalysis
SingleVariable("u100")
```

## Loading Pressure-Level Variable Information

Loading pressure-level variables using the `PressureVariable()` function is similar overall.  However, an additional argument `hPa` is needed to specify the pressure-levels in question.  By default `hPa = 0` refers to all available pressure-levels.  However, if the input for `hPa` is not a valid ERA5 pressure-level in CDS, then `throw` determines if an error is thrown, or if the nearest pressure level will be used instead.
```@docs
PressureVariable(
    varID :: AbstractString,
    ST = String;
    hPa   :: Int = 0,
    throw :: Bool = true
)
```
```@repl
using ERA5Reanalysis
PressureVariable("cc",hPa=1000)
PressureVariable("cc",hPa=890)
PressureVariable("cc",hPa=890,throw=false)
```

## Valid ERA5 Pressure-Levels in CDS

A list of valid ERA5 pressure-levels available directly from CDS can be retrieved using the function `era5Pressures`
```@docs
era5Pressures()
```
```@repl
using ERA5Reanalysis
era5Pressures()
```

## Does the `ERA5Variable` exist?

If we want to check if the `ERA5Variable` exists, we use either the `isSingle()` or `isPressure` functions.  

!!! note
    There is no generic `isERA5Variable` function, because some pressure-level variables and single-level variables on the CDS have the same identifier (e.g. Total Cloud Cover, and Cloud Cover Fraction, both of which use the identifer `cc`).

```@docs
isSingle
isPressure
```
```@repl
using ERA5Reanalysis
isSingle("tcwv")
```