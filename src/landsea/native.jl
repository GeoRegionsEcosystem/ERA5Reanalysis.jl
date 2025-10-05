"""
    getLandSea(
        e5ds :: ERA5Dataset,
        ereg :: ERA5Native = ERA5Region("GLB",native=true);
        save :: Bool = true,
        returnlsd :: Bool = true,
        smooth    :: Bool = false,
        σlon :: Int = 0,
        σlat :: Int = 0,
        iterations :: Int = 100,
        FT = Float64
    ) -> LandSea

Retrieve the Land-Sea Mask data for the `ERA5Dataset` specified.

Arguments
=========
- `e5ds` : The `ERA5Dataset` specified, which downloads the LandSea data into the path specified in `e5ds`.
- `ereg` : The ERA5LonLat of interest, each LandSea dataset is different depending on the resolution specified


Keyword Arguments
=================
- `save` : If `true`, save a copy of the LandSea dataset in a NetCDF file specified by e5ds.emask for ease of future retrieval (i.e., no need to repeat the download)
- `returnlsd` : If `true` return the data as a `LandSea` dataset. Otherwise, the data is simply saved into the e5ds.emask directory.
- `smooth` : If `smooth` = true, then you can smooth the land-sea mask using the Gaussian Filter of ImageFiltering.jl such that the coastline (i.e. the separation between land and ocean) becomes blurred.
- `σlon` : Smooth in the longitude direction (every increase of 1 in σlon roughly - corresponds to 8 pixels)
- `σlat` : Smooth in the latitude direction (every increase of 1 in σlat roughly corresponds to 8 pixels)
- `iterations` : Iterations of gausssian smoothing, the higher, the closer the smoothing follows a semi-log. 50-100 iterations is generally enough.
"""
function getLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Native;
    save :: Bool = true,
    returnlsd :: Bool = true,
)

    fid = "emask-$(ereg.string).nc"
    lsmfnc = joinpath(e5ds.emask,fid)

    if !isfile(lsmfnc)

        @info "$(modulelog()) - The ERA5 Land-Sea mask dataset for the \"$(ereg.ID)\" ERA5Native Grid is not available, extracting from Global ERA5 Land-Sea Mask Native Grid dataset ..."

        glbfnc = joinpath(e5ds.emask,"emask-$(ereg.string).nc")
        if !isfile(glbfnc)
            @info "$(modulelog()) - The Global ERA5 Land-Sea mask dataset is not available, you must extract it from the DKRZ servers and save it as $(glbfnc) first ..."
            downloadLandSea(e5ds,ereg)
        end

        gds  = NCDataset(lsmfnc)
        glon = gds["longitude"][:]
        glat = gds["latitude"][:]
        glsm = nomissing(gds["lsm"][:])
        goro = nomissing(gds["z"][:])
        close(gds)

        ggrd = RegionGrid(ereg,Point2.(glon,glat))

        @info "$(modulelog()) - Extracting regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5LonLat from the Global ERA5 Land-Sea mask dataset ..."
        roro = extract(goro,ggrd)
        rlsm = extract(glsm,ggrd)
        
        ggrd.mask[isnan.(ggrd.mask)] .= 0

        if save
            saveLandSea(e5ds,ereg,ggrd.lon,ggrd.lat,rlsm,roro,Int16.(ggrd.mask))
        else
            return LandSeaTopo{Float64,Float32}(ggrd.lon,ggrd.lat,rlsm,roro/9.80665)
        end

    end

    if returnlsd

        lds = NCDataset(lsmfnc)
        lon = lds["longitude"][:]
        lat = lds["latitude"][:]
        lsm = nomissing(lds["lsm"][:])
        oro = nomissing(lds["z"][:])
        close(lds)

        @info "$(modulelog()) - Retrieving the regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5LonLat ..."

        return LandSeaTopo{Float64,Float32}(lon,lat,lsm,oro/9.80665)

    else

        return nothing

    end

end

function downloadLandSea(
    e5ds :: ERA5Dataset,
         :: ERA5Native
)
    
    grb_lsm = "/pool/data/ERA5/E5/sf/an/IV/E5sf00_IV_INVARIANT_172.grb"
    grb_oro = "/pool/data/ERA5/E5/sf/an/IV/E5sf00_IV_INVARIANT_129.grb"

    if !isdir("/pool/data/ERA5/E5/sf/an/IV/")
        error("$(modulelog()) - Access to the DKRZ servers is required to retrieve the global Land-Sea Dataset on the Native Grid, so run this on the DKRZ servers or mount the DKRZ servers to access the data")
    end

    tds = GRIBDataset(grb_lsm)
    lon = tds["longitude"].var[:]; npnt = length(lon)
    lat = tds["latitude"].var[:]
    lsm = tds["lsm"].var[:]
    msk = ones(Int16,npnt)
    close(tds)
    tds = GRIBDataset(grb_oro)
    oro = tds["z"].var[:]
    close(tds)

    saveLandSea(
        e5ds,ERA5Region(GeoRegion("GLB"),native=true),
        lon,lat,lsm,oro,msk
    )

end

function saveLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Native,
    lon  :: Vector{<:Real},
    lat  :: Vector{<:Real},
    lsm  :: Vector{<:Real,2},
    oro  :: Vector{<:Real,2},
    mask :: Vector{Int16,2},
)

    fnc = joinpath(e5ds.emask,"emask-$(ereg.string).nc")
    if isfile(fnc)
        rm(fnc,force=true)
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(Dates.now())"
    ))

    ds.dim["values"] = length(lon)

    nclon = defVar(ds,"longitude",Float64,("values",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float64,("values",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nclsm = defVar(ds,"lsm",Float32,("values",),attrib = Dict(
        "long_name"     => "land_sea_mask",
        "full_name"     => "Land-Sea Mask",
        "units"         => "0-1",
    ))

    ncoro = defVar(ds,"z",Float32,("values",),attrib = Dict(
        "long_name"     => "geopotential",
        "full_name"     => "Geopotential",
        "units"         => "m**2 s**-2",
    ))

    ncmsk = defVar(ds,"mask",Int16,("values",),attrib = Dict(
        "long_name"     => "georegion_mask",
        "full_name"     => "GeoRegion Mask",
        "units"         => "0-1",
    ))

    nclon[:] = lon
    nclat[:] = lat
    nclsm[:] = lsm
    ncoro[:] = oro
    ncmsk[:] = mask

    close(ds)

end