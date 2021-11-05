# Custom `SingleLevel` variables

The Climate Data Store provides a very large number of `SingleLevel` variables.  As such, we only predefine a small subset of the variables available on CDS in ERA5Reanalysis.jl.  However, only `SingleVariable` type variables can be downloaded from the Climate Data Store - `SingleCustom` type variables are not defined on CDS.  Therefore, we allow the user the option to define if the custom `SingleLevel` variable they are defining exists on the Climate Data Store, and store it as a `SingleVariable` type.

## Defining a new `SingleVariable` or `SingleCustom`

To define both `SingleVariable` and `SingleCustom` variables, we use the funciton `SingleVariable()`.  To create a `SingleCustom` variable, the keyword argument `inCDS` must be set to false.

```@docs
SingleVariable(
    ST = String;
    varID :: AbstractString,
    lname :: AbstractString = "",
    vname :: AbstractString,
    units :: AbstractString,
    inCDS :: Bool = true
)
```

## Removing Custom `PressureLevel` Variables

To remove a `SingleLevel` variable, we can use the `rmSingle()` function:
```@docs
rmSingle( varID :: AbstractString )
```

## An Example!

In this example, we add two `SingleLevel` variables to the list:
* `hvc`, for High Vegetation Cover, which is a downloadable variable in the CDS
* `eke`, for Eddy Kinetic Energy, which is not downloadable and must be calculated using other variables

The Eddy Kinetic Energy is calculated by the following:

```math
E = \frac{1}{2g} \int_0^{p_s} \overline{u'^2} + \overline{v'^2} \>dp
```

And it is often used as a measure of storm-track intensity.

```@repl
using ERA5Reanalysis
SingleVariable(
    varID = "hvc",
    units = "0-1",
    vname = "High Vegetation Cover",
    lname = "high_vegetation_cover",
)
SingleVariable(
    varID = "eke",
    units = "J m**-2",
    vname = "Eddy Kinetic Energy",
    lname = "eddy_kinetic_energy",
    inCDS = false
)
tableSingles()
rmSingle.(["eke","hvc"])
isSingle("eke",throw=false) # don't throw error, just show warning
```