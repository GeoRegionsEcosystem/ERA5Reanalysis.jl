# Creating Custom `ERA5Variables`

While the list of available `ERA5Variable`s in the Climate Data Store is very extensive, they are not exhaustive.  Furthermore, due to the very large number of `SingleLevel` variables, we only predefine a small subset of the variables available on CDS in ERA5Reanalysis.jl.  There is therefore a need to define a list of custom `ERA5Variable`s that will be otherwise calculated (although this has to be done separately outside of ERA5Reanalysis.jl), and then can thus be saved and manipulated and analyzed in the same way that the default `ERA5Variable`s in ERA5Reanalysis.jl can be.  In this page, we break this down into the `SingleLevel` and `PressureLevel` components

## Custom `SingleLevel` Variables

We allow the user the option to define if the custom `SingleLevel` variable they are defining exists on the Climate Data Store, and store it as a `SingleVariable` type.  If a variable is not available on the Climate Data Store, they should be defined as a `SingleCustom` type.

### Defining a new `SingleVariable` or `SingleCustom`

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

### Removing Custom `SingleLevel` Variables

To remove a `SingleLevel` variable, we can use the `rmSingle()` function:
```@docs
rmSingle( varID :: AbstractString )
```

### An Example!

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
    varID = "cvh",
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

## Custom `PressureLevel` variables

In ERA5Reanalysis.jl, we have predefined all the pressure-level variables that are available directly from the CDS.  As such, all custom `PressureLevel` variables are defined under the `PressureCustom` type.

### Defining Custom `PressureLevel` Variables

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

### Removing Custom `PressureLevel` Variables

To remove a `PressureCustom` variable, we can use the `rmPressure()` function:
```@docs
rmPressure( varID :: AbstractString )
```

### An Example!

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