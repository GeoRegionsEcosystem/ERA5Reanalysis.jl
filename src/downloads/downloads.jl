"""
    download(
        e5ds :: Union{ERA5Hourly,ERA5Monthly},
        evar :: SingleVariable,
        ereg :: ERA5Region;
        ispy :: Bool = false,
        overwrite :: Bool = false
    ) -> nothing

Downloads ERA5 data from the CDS datastore for a specified Single-Level variable and geographic region.  You can specify to download via python scripts generated by selecting `ispy` to `true`, or to instead use Julia directly.

You must have installed the CDSAPI on your machine and have accepted the terms and conditions on the CDS website in order for this to work.

Arguments
=========

- `e5ds` : The ERA5Dataset specified (Hourly or Monthly)
    - `e5ds.start` defines the start date
    - `e5ds.stop` defines the end date
    - `e5ds.path` defines the path to which all reanalysis data is saved
- `evar` : Specifies the Single-Level variable to be downloaded
- `ereg` : Specifies the `GeoRegion` and the resolution of the data to be downloaded
- `ipsy` : Specifies whether to generate a python script that can be used to download the data instead of Julia
- `overwrite` : `false` by default. If set to true, existing data will be overwritten.
"""
function download(
    e5ds :: ERA5CDStore,
    evar :: SingleVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    grib :: Bool = false,
    overwrite :: Bool = false
)

    downloadcheckereg(ereg)

    if ispy
          pythonprint(e5ds,evar,ereg)
    else; cdsretrieve(e5ds,evar,ereg,grib,overwrite)
    end

end

"""
    download(
        e5ds :: Union{ERA5Hourly,ERA5Monthly},
        evar :: Vector{SingleVariable},
        ereg :: ERA5Region;
        overwrite :: Bool = false
    ) -> nothing

Downloads ERA5 data from the CDS datastore for a specified variable and geographic region.  There is no python option for this method.

You must have installed the CDSAPI on your machine and have accepted the terms and conditions on the CDS website in order for this to work.

Arguments
=========

- `e5ds` : The ERA5Dataset specified (Hourly or Monthly)
    - `e5ds.start` defines the start date
    - `e5ds.stop` defines the end date
    - `e5ds.path` defines the path to which all reanalysis data is saved
- `evar` : Specifies a vector of Single-Level variables to be downloaded in a temporary file. Once downloaded, the different variables will be extracted out and saved in their respective folders.
- `ereg` : Specifies the `GeoRegion` and the resolution of the data to be downloaded
- `overwrite` : `false` by default. If set to true, existing data will be overwritten.
"""
function download(
    e5ds :: ERA5CDStore,
    evar :: Vector{SingleVariable},
    ereg :: ERA5Region;
    overwrite :: Bool = false
)

    downloadcheckereg(ereg)
    cdsretrieve(e5ds,evar,ereg,overwrite)

end

"""
    download(
        e5ds :: Union{ERA5Hourly,ERA5Monthly},
        evar :: PressureVariable,
        ereg :: ERA5Region;
        ispy :: Bool = false,
        pall :: Bool = false,
        ptop :: Int = 0,
        pbot :: Int = 0,
        pvec :: Vector{Int} = [0],
        overwrite :: Bool = false
    ) -> nothing

Downloads ERA5 data from the CDS datastore for a specified Pressure-Level variable and geographic region.  You can choose to specify (1) one pressure level, (2) a vector of pressure levels or (3) a set of pressure levels defined by their top and bottom levels.  A python option is also available, but this will generate python scripts for all pressure levels.

You must have installed the CDSAPI on your machine and have accepted the terms and conditions on the CDS website in order for this to work.

Arguments
=========

- `e5ds` : The ERA5Dataset specified (Hourly or Monthly)
    - `e5ds.start` defines the start date
    - `e5ds.stop` defines the end date
    - `e5ds.path` defines the path to which all reanalysis data is saved
- `evar` : Specifies a Pressure-Level variable to be downloaded. By default (if `pall` is not selected), then the pressure level closest to what is specified in evar.hPa will be downloaded.
- `ereg` : Specifies the `GeoRegion` and the resolution of the data to be downloaded
- `ipsy` : Specifies whether to generate a python script that can be used to download the data instead of Julia. If `true`, scripts for **all** pressure levels will be generated
- `pall` : Indicates that we are selecting a range of pressure levels to be downloaded at the same time.
    - `ptop` : Indicates the pressure level at the top layer. `ptop` must be < `pbot`
    - `pbot` : Indicates the pressure level at the bottom layer. `pbot` must be > `ptop`
    - `pvec` : Defines a set of pressure levels to download. Overrides `ptop` and `pbot`
- `overwrite` : `false` by default. If set to true, existing data will be overwritten.
"""
function download(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    pall :: Bool = false,
    ptop :: Int = 0,
    pbot :: Int = 0,
    pvec :: Vector{Int} = [0],
    grib :: Bool = false,
    overwrite :: Bool = false
)

    downloadcheckereg(ereg)

    if ispy
        pythonprint(e5ds,evar,ereg)
    else
        if pvec == [0] || iszero(evar.hPa)
            pvec = downloadcheckplvl(pall,ptop,pbot)
        end
        if pall
            if !grib
                cdsretrieve(e5ds,evar,ereg,pvec,overwrite)
            else
                cdsretrievegrib(e5ds,evar,ereg,pvec,overwrite)
            end
        else
            cdsretrieve(e5ds,evar,ereg,grib,overwrite)
        end
    end

end

function downloadcheckhPa(
    evar :: PressureVariable
)

    if iszero(evar.hPa)

        error("$(modulelog()) - The PressureVariable Level is set to 0, so \"pall\" is set to `true` (i.e., we are downloading all pressure levels, or a range specified by the keyword arguments `ptop`, `pbot` and `pvec`).")

    end

end

function downloadcheckereg(
    ereg :: ERA5Region
)

    if !(typeof(ereg.geo) <: RectRegion)

        error("$(modulelog()) - ERA5Reanalysis is not yet set up to download GeoRegions that are not RectRegions. Check back in a later update for more.")

    end

end

function downloadcheckplvl(
    pall :: Bool,
    ptop :: Int,
    pbot :: Int
)

    if pall 

        @info "$(modulelog()) - Selected option to download pressure-level data as a whole batch instead of level-by-level"
        if iszero(ptop)
            @warn "$(modulelog()) - Top pressure-level not specified, setting to 1 hPa"
            ptop = 1
        end
        if iszero(pbot)
            @warn "$(modulelog()) - Bottom pressure-level not specified, setting to 1000 hPa"
            pbot = 1000
        end
        
        if ptop < 1; ptop = 1; elseif ptop > 1000; ptop = 1000 end
        if pbot < 1; pbot = 1; elseif pbot > 1000; pbot = 1000 end
        if ptop > pbot; error("$(modulelog()) - Bottom pressure-level is higher than top pressure-level") end

        pvec = era5Pressures()
        pvec = pvec[pvec.>=ptop]
        pvec = pvec[pvec.<=pbot]

    else
        @info "$(modulelog()) - Selected option to download pressure-level data level-by-level"
        pvec = []
    end

    flush(stderr)

    return pvec

end