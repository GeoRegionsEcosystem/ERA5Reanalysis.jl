"""
    ERA5Reanalysis.LandSea <: GeoRegions.LandSeaTopo

Object containing information on the Land Sea mask for ERA5, a subType extension of the `GeoRegions.LandSeaTopo` superType
"""
struct LandSea{FT<:Real} <: GeoRegions.LandSeaTopo
    lon  :: Vector{Float32}
    lat  :: Vector{Float32}
    lsm  :: Array{FT,2}
    z    :: Array{FT,2}
    mask :: Array{Int,2}
end

"""
    getLandSea(
        e5ds :: ERA5Dataset,
        ereg :: ERA5Region = ERA5Region("GLB");
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
- `ereg` : The ERA5Region of interest, each LandSea dataset is different depending on the resolution specified


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
    ereg :: ERA5Region = ERA5Region("GLB");
    save :: Bool = true,
    returnlsd :: Bool = true,
    FT = Float32
)

    fid = "emask-$(ereg.string).nc"
    lsmfnc = joinpath(e5ds.emask,fid)

    if !isfile(lsmfnc)

        @info "$(modulelog()) - The ERA5 Land-Sea mask dataset for the \"$(ereg.ID)\" ERA5Region is not available, extracting from Global ERA5 Land-Sea mask dataset ..."

        glbfnc = joinpath(e5ds.emask,"emask-GLBx$(@sprintf("%.2f",ereg.resolution)).nc")
        if !isfile(glbfnc)
            @info "$(modulelog()) - The Global ERA5 Land-Sea mask dataset is not available, downloading from the Climate Data Store ..."
            downloadLandSea(e5ds,ereg)
        end

        gds  = NCDataset(glbfnc)
        glon = gds["longitude"][:]
        glat = gds["latitude"][:]
        glsm = nomissing(gds["lsm"][:,:,1])
        goro = nomissing(gds["z"][:,:,1])
        close(gds)

        ggrd = RegionGrid(ereg,glon,glat)

        @info "$(modulelog()) - Extracting regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5Region from the Global ERA5 Land-Sea mask dataset ..."
        roro = extract(goro,ggrd)
        rlsm = extract(glsm,ggrd)

        if save
            saveLandSea(
                e5ds, ereg, ggrd.lon, ggrd.lat, rlsm, roro, ggrd.mask,
                smooth, σlon, σlat
            )
        else
            return LandSeaTopo{FT,FT}(ggrd.lon,ggrd.lat,rlsm,roro/9.80665)
        end

    end

    if returnlsd

        lds = NCDataset(lsmfnc)
        lon = lds["longitude"][:]
        lat = lds["latitude"][:]
        lsm = nomissing(lds["lsm"][:,:])
        oro = nomissing(lds["z"][:,:])
        close(lds)

        @info "$(modulelog()) - Retrieving the regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5Region ..."

        return LandSeaTopo{FT,FT}(lon,lat,lsm,oro/9.80665)

    else

        return nothing

    end

end

function downloadLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region
)

    tmpfnc = joinpath(e5ds.emask,"tmp.nc")
    retrieve(
        "reanalysis-era5-single-levels-monthly-means", Dict(
            "product_type" => "monthly_averaged_reanalysis",
            "year" => 2021,
            "month" => 12,
            "format" => "netcdf",
            "variable" => ["geopotential", "land_sea_mask"],
            "grid" => [ereg.resolution, ereg.resolution],
            "time" => "00:00"
        ), tmpfnc
    )

    tds = NCDataset(tmpfnc)
    lon = tds["longitude"][:]; nlon = length(lon)
    lat = tds["latitude"][:];  nlat = length(lat)
    lsm = tds["lsm"][:,:,1]
    oro = tds["z"][:,:,1]
    msk = ones(Int16,nlon,nlat)
    close(tds)

    saveLandSea(
        e5ds,ERA5Region(GeoRegion("GLB"),resolution=ereg.resolution),
        lon,lat,lsm,oro,msk
    )

    rm(tmpfnc,force=true)

end

function saveLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region,
    lon  :: Vector{<:Real},
    lat  :: Vector{<:Real},
    lsm  :: Array{<:Real,2},
    oro  :: Array{<:Real,2},
    mask :: Array{Int16,2},
    smooth :: Bool = false,
    σlon :: Int = 0,
    σlat :: Int = 0,
)

    if !smooth
        fnc = joinpath(e5ds.emask,"emask-$(ereg.string).nc")
    else
        fnc = joinpath(e5ds.emask,"emask-$(ereg.string)-smooth_$(σlon)x$(σlat).nc")
    end
    if isfile(fnc)
        rm(fnc,force=true)
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(Dates.now())"
    ))

    ds.dim["longitude"] = length(lon)
    ds.dim["latitude"]  = length(lat)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nclsm = defVar(ds,"lsm",Float32,("longitude","latitude",),attrib = Dict(
        "long_name"     => "land_sea_mask",
        "full_name"     => "Land-Sea Mask",
        "units"         => "0-1",
    ))

    ncoro = defVar(ds,"z",Float32,("longitude","latitude",),attrib = Dict(
        "long_name"     => "geopotential",
        "full_name"     => "Geopotential",
        "units"         => "m**2 s**-2",
    ))

    ncmsk = defVar(ds,"mask",Int16,("longitude","latitude",),attrib = Dict(
        "long_name"     => "georegion_mask",
        "full_name"     => "GeoRegion Mask",
        "units"         => "0-1",
    ))

    nclon[:] = lon
    nclat[:] = lat
    nclsm[:,:] = lsm
    ncoro[:,:] = oro
    ncmsk[:,:] = mask

    close(ds)

end