# List of Existing `ERA5Variable`s

In order to see a list of existing `ERA5Variable`s, we can use the function `tableERA5Variables()`.  Alternatively, if we only want to see `SingleLevel` or `PressureLevel` variables, we can use `tableSingles()` or `tablePressures()`

```@repl
using ERA5Reanalysis
tableERA5Variables()
```