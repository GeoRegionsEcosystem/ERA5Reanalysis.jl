# `ERA5Module` Examples

## Specifying an hourly dataset:

```@repl
using ERA5Reanalysis
ERA5Hourly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1))
```

## Specifying a monthly dataset:

```@repl
using ERA5Reanalysis
ERA5Monthly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1))
```

## Specifying a monthly-hour dataset:

```@repl
using ERA5Reanalysis
ERA5Monthly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1),hours=[0,3,6,9,12,15,18,21])
```