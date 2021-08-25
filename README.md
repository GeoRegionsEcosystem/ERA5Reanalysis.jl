# **<div align="center">ERA5Reanalysis.jl</div>**

<p align="center">
  <a href="https://www.repostatus.org/#active">
    <img alt="Repo Status" src="https://www.repostatus.org/badges/latest/active.svg?style=flat-square" />
  </a>
  <a href="https://github.com/natgeo-wong/ERA5Reanalysis.jl/actions/workflows/CI.yml">
    <img alt="GitHub Actions" src="https://github.com/natgeo-wong/ERA5Reanalysis.jl/actions/workflows/CI.yml/badge.svg?branch=main&style=flat-square">
  </a>
  <br>
  <a href="https://mit-license.org">
    <img alt="MIT License" src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square">
  </a>
	<img alt="Release Version" src="https://img.shields.io/github/v/release/natgeo-wong/ERA5Reanalysis.jl.svg?style=flat-square">
  <a href="https://natgeo-wong.github.io/ERA5Reanalysis.jl/stable/">
    <img alt="Stable Documentation" src="https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square">
  </a>
  <a href="https://natgeo-wong.github.io/ERA5Reanalysis.jl/dev/">
    <img alt="Latest Documentation" src="https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square">
  </a>
</p>

**Created By:** Nathanael Wong (nathanaelwong@fas.harvard.edu)

## **Introduction**

`ERA5Reanalysis.jl` is a Julia package that aims to streamline the following processes:
* downloads of ERA5 Datasets from the Climate Data Store (does not include MARS requests)
* basic analysis of said datasets
* perform all the above operations innately over a given geographical region using the [`GeoRegion`](https://github.com/JuliaClimate/GeoRegions.jl) functionality of GeoRegions.jl (v2 and above)

`ERA5Reanalysis.jl` has not been officially registered as a Julia package yet.  To install it, add it directly using the GitHub link as follows:
```
julia> ]
(@v1.6) pkg> add https://github.com/natgeo-wong/ERA5Reanalysis.jl.git
```

## **Required Installation**

In order to download data from the Climate Data Store (CDS), you need to register with [Copernicus](https://cds.climate.copernicus.eu/#!/home) first, and then follow the instructions [here](https://cds.climate.copernicus.eu/api-how-to) such that the information can be retrieved from the `~/.cdsapirc` file

## **Usage**

Please refer to the [documentation](https://natgeo-wong.github.io/ERA5Reanalysis.jl/dev/) for instructions and examples.  A working knowledge of the `GeoRegion` supertypes used in [`GeoRegions.jl`](https://github.com/JuliaClimate/GeoRegions.jl) v2 is also needed.

*__Tip:__ Both the `GeoRegions.jl` and `Dates` dependencies are reexported by `ERA5Reanalysis.jl`, and therefore there is no need to call either `GeoRegions.jl` or `Dates` separately when using the `ERA5Reanalysis.jl` package.*

## **Supported Datasets**

The following ERA5 datasets available on CDS are supported:
* **Hourly Data**, 0.25º resolution, from 1979-present
	* Early and Late runs of Half-Hourly and Daily Data
    * Ensemble data, mean and std not yet supported, addition is possible depending on demand
* **Monthly Data**, 0.25º resolution, from 1979-present
	* Both monthly reanalysis, and monthly-by-hour are supported
    * Ensemble data not yet supported, addition is possible depending on demand
* Support for the back-extension (1950-1978) for all datasets coming soon
* Support for ERA5-Land reanalysis will eventually be included.  How fast depends on demand

Only the calibrated precipitation data is downloaded, with units of rate in log2(mm/s).

If there is demand, I can try to add other datasets available on the Climate Data Store to the mix as well. Please open an issue if you want me to do so.