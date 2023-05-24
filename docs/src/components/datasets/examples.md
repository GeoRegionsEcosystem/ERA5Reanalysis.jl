# `ERA5Dataset` Examples

Here, we list some basic examples for the creation of `ERA5Dataset`

## Specifying an hourly dataset:

```@repl
using ERA5Reanalysis
ERA5Hourly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1))
```

Note that the resultant `ERA5Hourly` dataset processes data by whole-months.  It is not possible to specify specific days in which to download data.

## Specifying a monthly dataset with custom home directory:

```@repl
using ERA5Reanalysis
ERA5Monthly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1),eroot=pwd())
```

Note that the resultant `ERA5Monthly` dataset processes data by years.  It is not possible to specify specific months in which to download data.  The same holds true for the `ERA5MonthlyHour` dataset.

## Specifying a monthly-hour dataset:

```@repl
using ERA5Reanalysis
ERA5Monthly(dtbeg=Date(2017,1,2),dtend=Date(2018,5,1),hours=[0,3,6,9,12,15,18,21])
```