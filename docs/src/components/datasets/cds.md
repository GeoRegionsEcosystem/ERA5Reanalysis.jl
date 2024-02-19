# ERA5 Datasets available in CDS
The `ERA5CDStore` Type of the parent type of all ERA5 Datasets that are naturally available from the Climate Data Store and can thus be downloaded directly using the CDSAPI.

!!! note
    The Climate Data Store also has an option to download ERA5 Monthly data by hour-of-day. This is subsumed into the ERA5Monthly dataset and can be selected by specifying `hours = true`.

```@docs
ERA5Hourly
ERA5Monthly
```

There are other potential modules that could be incorporated into ERA5Reanalysis.jl, such as
* ERA5-Land data
* Ensemble model averages, individual members, and standard deviations

They have not been added yet into ERA5Reanalysis.jl. If you are potentially interested in me adding these datasets to ERA5Reanalysis.jl, please [submit a pull request](https://github.com/natgeo-wong/ERA5Reanalysis.jl/pulls).

## API

```@docs
ERA5Hourly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
)
ERA5Monthly(;
    start :: TimeType,
    stop  :: TimeType,
    path  :: AbstractString = homedir(),
    hours :: Union{Int,Vector{Int}} = -1,
)
```