# Resetting the `ERA5Variable` Lists

We can reset the list of `ERA5Variable`s back to the default predefined list using the function `resetERA5Variables()`.  Alternatively, if we only want to reset `SingleLevel` or `PressureLevel` variables, we can use `resetSingles()` or `resetPressures()`.

For the `resetERA5Variables()` and `resetSingles()` functions, the `allfiles` keyword will reset the list of `SingleVariable` variables as well, instead of just the list of `SingleCustom` variables.

```@docs
resetERA5Variables
resetSingles
resetPressures
```