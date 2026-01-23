# Setting up the CDS API

ERA5Reanalysis.jl downloads data from the Copernicus Climate Data Store (CDS), which requires registering an account to access the data. The steps are as follows:

1. Register an account at the [Climate Data Store](https://cds.climate.copernicus.eu/)
2. Obtain your API key from the [CDS API How-To](https://cds.climate.copernicus.eu/api-how-to) page
3. Set up your API key using ERA5Reanalysis.jl

If this sounds complicated however, fear not! You need only perform the first two steps yourself (i.e., create your own account and retrieve your API key). Once you have your API key, you can use the function `addCDSAPIkey()` to set it up:

```julia
using ERA5Reanalysis

addCDSAPIkey("<your-api-key-here>")
```

The API key format is typically `<user-id>:<api-key>`, for example: `123456:abcd1234-ef56-gh78-ij90-klmn12345678`

## Verifying Your Setup

You can verify that your CDS API key is set up correctly by checking the key:

```@repl
using ERA5Reanalysis
ckeys = ERA5Reanalysis.cdskey()
```

## API

```@docs
addCDSAPIkey
```
