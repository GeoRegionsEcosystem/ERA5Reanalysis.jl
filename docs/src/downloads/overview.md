# An Overview of the Download Functionality of ERA5Reanalysis

The backend download functionality of ERA5Reanalysis.jl are based upon the build of (https://github.com/JuliaClimate/CDSAPI.jl)[CDSAPI.jl], but with the following extensions:
* Eliminates the need to know the CDSAPI syntax for the frontend - all you need is to specify the Dataset, Variable and Region of interest
* Extracts and places the downloaded data in a patterned, organized and systematic manner for easy retrieval
* More detailed and organized logging information during the downloading process similar to the python version of CDSAPI
* Allowing for repeated (up to 20) attempts at downloading a specific set of data

However, the download functionality of ERA5Reanalysis.jl is also limited in several ways:
* It currently only is able to download the `reanalysis` data, not ensemble members
* It currently is unable to retrieve any dataset outside the ERA5 Reanalysis datasets, including ERA5-Land data
* It is not possible to specify multiple Pressure-Level variables for download in the same manner as Single-Level variables