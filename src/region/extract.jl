function extract(
    e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	ereg :: ERA5Region;
    smooth     :: Bool = false,
    smoothlon  :: Real = 0,
    smoothlat  :: Real = 0,
    smoothtime :: Int = 0,
)

    if smooth && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion of \"$(ereg.ID)\", \"$(ereg.geo.parID)\""

    preg = ERA5Region(GeoRegion(ereg.geo.parID,path=ereg.geo.path))
    plsd = getLandSea(e5ds,preg);
    rlsd = getLandSea(e5ds,ereg);
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating RegionGrid for \"$(ereg.ID)\" based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.geo.parID)\""

    rinfo = RegionGrid(ereg,plon,plat)
    nlon = length(rinfo.ilon)
    nlat = length(rinfo.ilat)
    
    ndt  = ntimesteps(e5ds)
    rmat = zeros(Float32,nlon,nlat,ndt)
    pmat = zeros(Float32,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,preg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.ID].var,tmat,:,:,1:nt)
        close(pds)

        @info "$(modulelog()) - Extracting the $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) GeoRegion from the $(preg.geo.name) (Horizontal Resolution: $(preg.resolution)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

        extract!(rmat,tmat,rinfo)

        save(
            view(rmat,:,:,1:nt),dt,e5ds,evar,ereg,rlsd,
            extract=true,extractnc=pnc,
            smooth=smooth,smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )

        flush(stderr)

    end

end

function extract(
	sgeo :: GeoRegion,
    e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	ereg :: ERA5Region;
    smooth     :: Bool = false,
    smoothlon  :: Real = 0,
    smoothlat  :: Real = 0,
    smoothtime :: Int = 0
)

    in(sgeo,ereg.geo)

    if smooth && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion of \"$(sgeo.ID)\", \"$(ereg.ID)\""

    sreg = ERA5Region(sgeo,resolution=ereg.resolution)
    plsd = getLandSea(e5ds,ereg)
    rlsd = getLandSea(e5ds,sreg)
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating RegionGrid for \"$(sreg.ID)\" based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.ID)\""

    rinfo = RegionGrid(sreg,plon,plat)
    nlon = length(rinfo.ilon)
    nlat = length(rinfo.ilat)
    
    ndt  = ntimesteps(e5ds)
    rmat = zeros(Float32,nlon,nlat,ndt)
    pmat = zeros(Float32,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,ereg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.ID].var,tmat,:,:,1:nt)
        close(pds)

        @info "$(modulelog()) - Extracting the $(e5ds.name) $(evar.name) data in $(sreg.geo.name) (Horizontal Resolution: $(sreg.resolution)) GeoRegion from the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

        extract!(rmat,tmat,rinfo)

        save(
            view(rmat,:,:,1:nt),dt,e5ds,evar,sreg,rlsd,
            extract=true,extractnc=pnc,
            smooth=smooth,smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )

        flush(stderr)

    end

end

function extract(
	geov :: Vector{<:GeoRegion},
    e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	ereg :: ERA5Region;
    smooth     :: Bool = false,
    smoothlon  :: Real = 0,
    smoothlat  :: Real = 0,
    smoothtime :: Int = 0,
)

    for sgeo in geov
        in(sgeo,ereg.geo)
    end
    ngeo = length(geov)

    if smooth && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion, \"$(ereg.ID)\""

    sreg = Vector{ERA5Region}(undef,ngeo)
    rlsd = Vector{LandSea}(undef,ngeo)
    plsd = getLandSea(e5ds,ereg)
    for igeo in 1 : ngeo
        sreg[igeo] = ERA5Region(geov[igeo],resolution=ereg.resolution)
        rlsd[igeo] = getLandSea(e5ds,sreg[igeo])
    end
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating vector of RegionGrids based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.ID)\""

    rinfo = Vector{RegionGrid}(undef,ngeo)
    for igeo in 1 : ngeo
        rinfo[igeo] = RegionGrid(sreg[igeo],plon,plat)
        nlon[igeo] = length(rinfo[igeo].ilon)
        nlat[igeo] = length(rinfo[igeo].ilat)
    end

    ndt  = ntimesteps(e5ds)
    rmat = Vector{Array}(undef,ngeo)
    for igeo in 1 : ngeo
        rmat[igeo] = zeros(Float32,nlon[igeo],nlat[igeo],ndt)
    end
    pmat = zeros(Float32,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,ereg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.ID].var,tmat,:,:,1:nt)

        for igeo = 1 : ngeo

            @info "$(modulelog()) - Extracting the $(e5ds.name) $(evar.name) data in $(sreg[igeo].geo.name) (Horizontal Resolution: $(ereg.resolution)) GeoRegion from the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

            extract!(rmat[igeo],tmat,rinfo[igeo])

            close(pds)

            save(
                view(rmat[igeo],:,:,1:nt),dt,e5ds,evar,sreg[igeo],rlsd[igeo],
                extract=true,smooth=smooth,extractnc=pnc,
                smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
            )

            flush(stderr)

        end
        
    end

end

extract_time(e5ds::Union{ERA5Hourly,ERA5Daily}) = e5ds.start : Month(1) : e5ds.stop
extract_time(e5ds::ERA5Monthly) = e5ds.start : Year(1)  : e5ds.stop