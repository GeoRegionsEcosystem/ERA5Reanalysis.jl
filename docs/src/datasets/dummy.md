# Dummy Datasets

Dummy datasets are meant to specify the paths to the ERA5 data root directory and LandSea folder, without needing inputs for date.

### Setup
```@example dummy
using ERA5Reanalysis
```

## Creating a Dummy Dataset

```@example dummy
e5ds = ERA5Dummy(path=homedir())
```
```@example dummy
isdir(e5ds.emask)
```

## Use Cases

Dummy datasets are particularly useful for:
* Retrieving Land-Sea masks without specifying date ranges
* Setting up directory structures before downloading data
* Testing path configurations

## API

```@docs
ERA5Dummy
ERA5Dummy(;
    ST = String;
    path :: AbstractString = homedir(),
)
```
