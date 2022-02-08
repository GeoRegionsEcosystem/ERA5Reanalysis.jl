struct LandSea{FT<:Real}
    lon  :: Vector{FT}
    lat  :: Vector{FT}
    lsm  :: Array{FT,2}
    z    :: Array{FT,2}
    mask :: Array{Int16,2}
end

function getLandSea(
    e5ds :: ERA5Dataset,
    ereg :: ERA5Region;
    returnlsd = true,
    FT = Float64
)

    lsmfnc = joinpath(e5ds.emask,"emask-$(ereg.gstr).nc")

    if !isfile(lsmfnc)

        @info "$(modulelog()) - The ERA5 Land-Sea mask dataset for the \"$(ereg.geoID)\" ERA5Region is not available, extracting from Global ERA5 Land-Sea mask dataset ..."

        glbfnc = joinpath(e5ds.emask,"emask-GLBx$(@sprintf("%.2f",ereg.gres)).nc")
        if !isfile(glbfnc)
            @info "$(modulelog()) - The Global ERA5 Land-Sea mask dataset for the \"$(ereg.geoID)\" ERA5Region is not available, downloading from the Climate Data Store ..."
            downloadLandSea(e5ds,ereg)
        end

        gds  = NCDataset(glbfnc)
        glon = gds["longitude"][:]
        glat = gds["latitude"][:]
        glsm = gds["lsm"][:] * 1
        goro = gds["z"][:] * 1
        close(gds)

        rinfo = ERA5RegionGrid(ereg,glon,glat)
        ilon  = rinfo.ilon; nlon = length(rinfo.ilon)
        ilat  = rinfo.ilat; nlat = length(rinfo.ilat)
        rlsm  = zeros(nlon,nlat)
        roro  = zeros(nlon,nlat)
        
        rinfo.mask[isnan.(rinfo.mask)] .= 0

        @info "$(modulelog()) - Extracting regional ERA5 Land-Sea mask for the \"$(ereg.geoID)\" ERA5Region from the Global ERA5 Land-Sea mask dataset ..."

        for iglat = 1 : nlat, iglon = 1 : nlon
            rlsm[iglon,iglat] = glsm[ilon[iglon],ilat[iglat]]
            roro[iglon,iglat] = goro[ilon[iglon],ilat[iglat]]
        end

        saveLandSea(e5ds,ereg,rinfo.glon,rinfo.glat,rlsm,roro,Int16.(rinfo.mask))

    end

    if returnlsd

        lds = NCDataset(lsmfnc)
        lon = lds["longitude"][:]
        lat = lds["latitude"][:]
        lsm = lds["lsm"][:] * 1
        oro = lds["z"][:] * 1
        msk = lds["mask"][:]
        close(lds)

        @info "$(modulelog()) - Retrieving the regional ERA5 Land-Sea mask for the \"$(ereg.geoID)\" ERA5Region ..."

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
            "grid" => [ereg.gres, ereg.gres],
            "time" => "00:00"
        ), tmpfnc
    )

    tds = NCDataset(tmpfnc)
    lon = tds["longitude"][:]; nlon = length(lon)
    lat = tds["latitude"][:];  nlat = length(lat)
    lsm = tds["lsm"][:,:,1] * 1
    oro = tds["z"][:,:,1] * 1
    msk = ones(Int16,nlon,nlat)
    close(tds)

    saveLandSea(
        e5ds,ERA5Region(GeoRegion("GLB"),gres=ereg.gres),
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
    msk  :: Array{Int16,2},
)

    fnc = joinpath(e5ds.emask,"emask-$(ereg.gstr).nc")
    if isfile(fnc)
        rm(fnc,force=true)
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(Dates.now())"
    ))

    ds.dim["longitude"] = length(lon)
    ds.dim["latitude"]  = length(lat)

    lscale,loffset = ncoffsetscale(lsm)
    zscale,zoffset = ncoffsetscale(oro)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nclsm = defVar(ds,"lsm",Int16,("longitude","latitude",),attrib = Dict(
        "long_name"     => "land_sea_mask",
        "full_name"     => "Land-Sea Mask",
        "units"         => "0-1",
        "scale_factor"  => lscale,
        "add_offset"    => loffset,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    ))

    ncoro = defVar(ds,"z",Int16,("longitude","latitude",),attrib = Dict(
        "long_name"     => "geopotential",
        "full_name"     => "Surface Geopotential",
        "units"         => "m**2 s**-2",
        "scale_factor"  => zscale,
        "add_offset"    => zoffset,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    ))

    ncmsk = defVar(ds,"mask",Int16,("longitude","latitude",),attrib = Dict(
        "long_name"     => "georegion_mask",
        "full_name"     => "GeoRegion Mask",
        "units"         => "0-1",
    ))

    nclon[:] = lon
    nclat[:] = lat
    nclsm[:] = lsm
    ncoro[:] = oro
    ncmsk[:] = msk

    close(ds)

end

function show(io::IO, lsd::LandSea)
	nlon = length(lsd.lon)
	nlat = length(lsd.lat)
    print(
		io,
		"The Land-Sea Mask Dataset has the following properties:\n",
		"    Longitude Points   (glon) : ", lsd.lon,  '\n',
		"    Latitude Points    (glat) : ", lsd.lat,  '\n',
		"    Region Size (nlon * nlat) : $(nlon) lon points x $(nlat) lat points\n",
	)
end