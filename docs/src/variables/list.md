# List of Predefined `ERA5Variable`s in ERA5Reanalysis.jl

In order to see a list of existing `ERA5Variable`s, we can use the function `tableERA5Variables()`.  Alternatively, if we only want to see `SingleLevel` or `PressureLevel` variables, we can use `tableSingles()` or `tablePressures()`

!!! compat "ERA5Reanalysis ≧ v0.3"
    All Single-Level variables defined in the Climate Data Store are now available in ERA5Reanalysis.jl, but only for versions ≧ v0.3. Otherwise, a small subset of the Single-Level variables are available, but the rest need to be user-defined.

## List of Predefined Single-Level Variables

```@example listvariables
using ERA5Reanalysis
tableSingles()
```

## List of Predefined Pressure-Level Variables

```@example listvariables
using ERA5Reanalysis
tablePressures()
```