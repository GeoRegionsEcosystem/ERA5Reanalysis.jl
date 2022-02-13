function extract(
    e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	ereg :: ERA5Region,
)

    @info "$(modulelog()) - Retrieving GeoRegion and LandSea Dataset information for the parent GeoRegion of \"$(ereg.geoID)\", \"$(ereg.geo.parID)\""

    preg = ERA5Region(GeoRegion(ereg.geo.parID))
    plsd = getLandSea(e5ds,preg);
    rlsd = getLandSea(e5ds,ereg);
    plon = plsd.lon
    plat = plsd.lat

    @info "$(modulelog()) - Creating RegionGrid for \"$(ereg.geoID)\" based on the longitude and latitude vectors of the parent GeoRegion \"$(ereg.geo.parID)\""

    rinfo = ERA5RegionGrid(ereg,plon,plat)
    ilon  = rinfo.ilon; nlon = length(ilon)
    ilat  = rinfo.ilat; nlat = length(ilat)
    if typeof(rinfo) <: PolyGrid
          mask = rinfo.mask
    else; mask = ones(nlon,nlat)
    end
    
    if typeof(e5ds) <: ERA5Hourly
          rmat = zeros(Float32,nlon,nlat,31*24)
    elseif !(e5ds.hours)
          rmat = zeros(Float32,nlon,nlat,12)
    else; rmat = zeros(Float32,nlon,nlat,12*24)
    end

    for dt in extract_time(e5ds)

        pnc  = read(e5ds,evar,preg,dt)
        pmat = pnc[evar.varID][:] * 1
        nt   = size(pmat,3)

        @info "$(modulelog()) - Extracting the $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) GeoRegion from the $(preg.geo.name) (Horizontal Resolution: $(preg.gres)) GeoRegion for $(year(dt)) $(Dates.monthname(dt))"

        for it = 1 : nt, i_ilat = 1 : nlat, i_ilon = 1 : nlon

            if isone(mask[i_ilon,i_ilat])
                  rmat[i_ilon,i_ilat,it] = pmat[ilon[i_ilon],ilat[i_ilat],it]
            else; rmat[i_ilon,i_ilat,it] = NaN
            end

        end

        save(view(rmat,:,:,1:nt),dt,e5ds,evar,ereg,rlsd)

    end

end

extract_time(e5ds::ERA5Hourly)  = e5ds.dtbeg : Month(1) : e5ds.dtend
extract_time(e5ds::ERA5Monthly) = e5ds.dtbeg : Year(1)  : e5ds.dtend