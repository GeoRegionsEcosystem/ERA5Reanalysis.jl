struct LandSea{FT<:Real}
    lon  :: Vector{Float32}
    lat  :: Vector{Float32}
    lsm  :: Array{FT,2}
    z    :: Array{FT,2}
    mask :: Array{Int,2}
end

function getLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region = ERA5Region(GeoRegion("GLB"));
    save :: Bool = true,
    returnlsd :: Bool = true,
    smooth    :: Bool = false,
    σlon :: Int = 0,
    σlat :: Int = 0,
    iterations :: Int = 100,
    FT = Float64
)

    if smooth && (iszero(σlon) && iszero(σlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters, at least one of σlon and σlat must be nonzero")
    end

    if !smooth
        fid = "emask-$(ereg.string).nc"
    else
        fid = "emask-$(ereg.string)-smooth_$(σlon)x$(σlat).nc"
    end
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
        glsm = nomissing(gds["lsm"][:,:,1],NaN)
        goro = nomissing(gds["z"][:,:,1],NaN)
        close(gds)

        if smooth
            smooth!(glsm,σlon=σlon,σlat=σlat,iterations=iterations)
        end

        ggrd = RegionGrid(ereg,glon,glat)
        nlon = length(ggrd.ilon)
        nlat = length(ggrd.ilat)

        @info "$(modulelog()) - Extracting regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5Region from the Global ERA5 Land-Sea mask dataset ..."
        roro = extractGrid(goro,ggrd)
        rlsm = extractGrid(glsm,ggrd)

        if typeof(ggrd) <: PolyGrid
              mask = ggrd.mask; mask[isnan.(mask)] .= 0
        else; mask = ones(Int,nlon,nlat)
        end

        if isGeoRegion(ereg.ID,throw=false) && save
            saveLandSea(
                e5ds, ereg, ggrd.lon, ggrd.lat, rlsm, roro, Int16.(mask),
                smooth, σlon, σlat
            )
        else
            return LandSea{FT}(ggrd.lon,ggrd.lat,rlsm,roro,Int16.(mask))
        end

    end

    if isGeoRegion(ereg.ID,throw=false) && returnlsd

        lds = NCDataset(lsmfnc)
        lon = lds["longitude"][:]
        lat = lds["latitude"][:]
        lsm = nomissing(lds["lsm"][:,:], NaN)
        oro = nomissing(lds["z"][:,:],   NaN)
        msk = lds["mask"][:,:]
        close(lds)

        @info "$(modulelog()) - Retrieving the regional ERA5 Land-Sea mask for the \"$(ereg.ID)\" ERA5Region ..."

        return LandSea{FT}(lon,lat,lsm,oro,msk)

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
    lsm = tds["lsm"][:,:,1] * 1
    oro = tds["z"][:,:,1] / 9.80665
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

    nclsm = defVar(ds,"lsm",Float64,("longitude","latitude",),attrib = Dict(
        "long_name"     => "land_sea_mask",
        "full_name"     => "Land-Sea Mask",
        "units"         => "0-1",
    ))

    ncoro = defVar(ds,"z",Float64,("longitude","latitude",),attrib = Dict(
        "long_name"     => "height",
        "full_name"     => "Surface Height",
        "units"         => "m",
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

function show(io::IO, lsd::LandSea)
	nlon = length(lsd.lon)
	nlat = length(lsd.lat)
    print(
		io,
		"The Land-Sea Mask Dataset has the following properties:\n",
		"    Longitude Points    (lon) : ", lsd.lon,  '\n',
		"    Latitude Points     (lat) : ", lsd.lat,  '\n',
		"    Region Size (nlon * nlat) : $(nlon) lon points x $(nlat) lat points\n",
	)
end