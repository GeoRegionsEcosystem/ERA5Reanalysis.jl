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

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion of \"$(ereg.geoID)\", \"$(ereg.geo.parID)\""

    preg = ERA5Region(GeoRegion(ereg.geo.parID))
    plsd = getLandSea(e5ds,preg);
    rlsd = getLandSea(e5ds,ereg);
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating RegionGrid for \"$(ereg.geoID)\" based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.geo.parID)\""

    rinfo = ERA5RegionGrid(ereg,plon,plat)
    ilon  = rinfo.ilon; nlon = length(ilon)
    ilat  = rinfo.ilat; nlat = length(ilat)
    if typeof(rinfo) <: PolyGrid
          mask = rinfo.mask
    else; mask = ones(nlon,nlat)
    end
    
    ndt  = ntimesteps(e5ds)
    rmat = zeros(Int16,nlon,nlat,ndt)
    pmat = zeros(Int16,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,preg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        sc   = pds[evar.varID].attrib["scale_factor"]
        of   = pds[evar.varID].attrib["add_offset"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.varID].var,tmat,:,:,1:nt)

        @info "$(modulelog()) - Extracting the $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) GeoRegion from the $(preg.geo.name) (Horizontal Resolution: $(preg.gres)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

        for it = 1 : nt, i_ilat = 1 : nlat, i_ilon = 1 : nlon

            if isone(mask[i_ilon,i_ilat])
                  rmat[i_ilon,i_ilat,it] = tmat[ilon[i_ilon],ilat[i_ilat],it]
            else; rmat[i_ilon,i_ilat,it] = -32767
            end

        end

        close(pds)

        save(
            view(rmat,:,:,1:nt),dt,e5ds,evar,ereg,rlsd,sc,of,
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

    isinGeoRegion(sgeo,ereg.geo)

    if smooth && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion of \"$(sgeo.regID)\", \"$(ereg.geoID)\""

    sreg = ERA5Region(sgeo,gres=ereg.gres)
    plsd = getLandSea(e5ds,ereg)
    rlsd = getLandSea(e5ds,sreg)
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating RegionGrid for \"$(sreg.geoID)\" based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.geoID)\""

    rinfo = ERA5RegionGrid(sreg,plon,plat)
    ilon  = rinfo.ilon; nlon = length(ilon)
    ilat  = rinfo.ilat; nlat = length(ilat)
    if typeof(rinfo) <: PolyGrid
          mask = rinfo.mask
    else; mask = ones(nlon,nlat)
    end
    
    ndt  = ntimesteps(e5ds)
    rmat = zeros(Int16,nlon,nlat,ndt)
    pmat = zeros(Int16,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,preg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        sc   = pds[evar.varID].attrib["scale_factor"]
        of   = pds[evar.varID].attrib["add_offset"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.varID].var,tmat,:,:,1:nt)

        @info "$(modulelog()) - Extracting the $(e5ds.lname) $(evar.vname) data in $(sreg.geo.name) (Horizontal Resolution: $(sreg.gres)) GeoRegion from the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

        for it = 1 : nt, i_ilat = 1 : nlat, i_ilon = 1 : nlon

            if isone(mask[i_ilon,i_ilat])
                  rmat[i_ilon,i_ilat,it] = tmat[ilon[i_ilon],ilat[i_ilat],it]
            else; rmat[i_ilon,i_ilat,it] = -32767
            end

        end

        close(pds)

        save(
            view(rmat,:,:,1:nt),dt,e5ds,evar,sreg,rlsd,sc,of,
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
        isinGeoRegion(sgeo,ereg.geo)
    end
    ngeo = length(geov)

    if smooth && (iszero(smoothlon) && iszero(smoothlat))
        error("$(modulelog()) - Incomplete specification of smoothing parameters in either the longitude or latitude directions")
    end

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion, \"$(ereg.geoID)\""

    sreg = Vector{ERA5Region}(undef,ngeo)
    rlsd = Vector{LandSea}(undef,ngeo)
    plsd = getLandSea(e5ds,ereg)
    for igeo in 1 : ngeo
        sreg[igeo] = ERA5Region(geov[igeo],gres=ereg.gres)
        rlsd[igeo] = getLandSea(e5ds,sreg[igeo])
    end
    plon = plsd.lon; nplon = length(plon)
    plat = plsd.lat; nplat = length(plat)

    @info "$(modulelog()) - Creating vector of RegionGrids based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.geoID)\""

    rinfo = Vector{RegionGrid}(undef,ngeo)
    ilon  = Vector{Vector}(undef,ngeo)
    ilat  = Vector{Vector}(undef,ngeo)
    nlon  = Vector{Int}(undef,ngeo)
    nlat  = Vector{Int}(undef,ngeo)
    mask  = Vector{Array}(undef,ngeo)
    for igeo in 1 : ngeo
        rinfo[igeo] = ERA5RegionGrid(sreg[igeo],plon,plat)
        ilon[igeo]  = rinfo[igeo].ilon; nlon[igeo] = length(ilon[igeo])
        ilat[igeo]  = rinfo[igeo].ilat; nlat[igeo] = length(ilat[igeo])
        if typeof(rinfo[igeo]) <: PolyGrid
              mask[igeo] = rinfo[igeo].mask
        else; mask[igeo] = ones(nlon[igeo],nlat[igeo])
        end
    end

    ndt  = ntimesteps(e5ds)
    rmat = Vector{Array}(undef,ngeo)
    for igeo in 1 : ngeo
        rmat[igeo] = zeros(Int16,nlon[igeo],nlat[igeo],ndt)
    end
    pmat = zeros(Int16,nplon,nplat,ndt)

    for dt in extract_time(e5ds)

        pds  = read(
            e5ds,evar,preg,dt,smooth=smooth,
            smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
        )
        pnc  = basename(path(pds))
        nt   = pds.dim["time"]
        sc   = pds[evar.varID].attrib["scale_factor"]
        of   = pds[evar.varID].attrib["add_offset"]
        tmat = @view pmat[:,:,1:nt]
        NCDatasets.load!(pds[evar.varID].var,tmat,:,:,1:nt)

        for igeo = 1 : ngeo

            @info "$(modulelog()) - Extracting the $(e5ds.lname) $(evar.vname) data in $(sreg[igeo].geo.name) (Horizontal Resolution: $(ereg.gres)) GeoRegion from the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

            for it = 1 : nt, i_ilat = 1 : nlat[igeo], i_ilon = 1 : nlon[igeo]

                if isone(mask[igeo][i_ilon,i_ilat])
                    rmat[igeo][i_ilon,i_ilat,it] = tmat[ilon[igeo][i_ilon],ilat[igeo][i_ilat],it]
                else; rmat[igeo][i_ilon,i_ilat,it] = -32767
                end

            end

            close(pds)

            save(
                view(rmat[igeo],:,:,1:nt),dt,e5ds,evar,sreg[igeo],rlsd[igeo],sc,of,
                extract=true,smooth=smooth,extractnc=pnc,
                smoothlon=smoothlon,smoothlat=smoothlat,smoothtime=smoothtime
            )

            flush(stderr)

        end
        
    end

end

extract_time(e5ds::Union{ERA5Hourly,ERA5Daily}) = e5ds.start : Month(1) : e5ds.stop
extract_time(e5ds::ERA5Monthly) = e5ds.start : Year(1)  : e5ds.stop