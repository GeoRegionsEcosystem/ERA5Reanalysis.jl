# Setting up the CDSAPI Key

In order for your downloads to work with ERA5Reanalysis, you first need to set up your CDSAPI key.  To do this, you must first register with the [Climate Data Store](https://cds.climate.copernicus.eu/) in order to obtain your key [here](https://cds.climate.copernicus.eu/api-how-to).

Then, you can either follow the instructions above in the API-how-to, or you can simply use the function `addCDSAPIkey()` to do it for you if you don't want to fiddle around with hidden files and the like.

```@docs
addCDSAPIkey
```

So, example

```@repl
using ERA5Reanalysis
ckeys = ERA5Reanalysis.cdskey()
addCDSAPIkey("<your-key-here>",overwrite=true)
ckeys = ERA5Reanalysis.cdskey()
rm(joinpath(homedir(),".cdsapirc"))
```