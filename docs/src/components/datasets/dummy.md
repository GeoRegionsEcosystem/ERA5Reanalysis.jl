# Dummy ERA5 Datasets

Dummy datasets are meant to specify the paths to the ERA5 data root directory, and LandSea folder, without needing inputs for date.

```@docs
ERA5Dummy
```

```@repl
using ERA5Reanalysis
e5ds = ERA5Dummy(path=homedir())
isdir(e5ds.emask)
```

## API

```@docs
ERA5Dummy(;
    ST = String;
    path :: AbstractString = homedir(),
)
```