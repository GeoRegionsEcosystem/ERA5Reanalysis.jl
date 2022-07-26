function extract(
    e5ds :: ERA5Dataset,
	evar :: ERA5Variable,
	ereg :: ERA5Region,
)

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
    
    if typeof(e5ds) <: ERA5Hourly
        rmat = zeros(Int16,nlon,nlat,31*24)
        pmat = zeros(Int16,nplon,nplat,31*24)
    elseif !(e5ds.hours)
        rmat = zeros(Int16,nlon,nlat,12)
        rmat = zeros(Int16,nplon,nplat,12)
    else
        rmat = zeros(Int16,nlon,nlat,12*24)
        rmat = zeros(Int16,nplon,nplat,12*24)
    end

    for dt in extract_time(e5ds)

        pds  = read(e5ds,evar,preg,dt)
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

        save(view(rmat,:,:,1:nt),dt,e5ds,evar,ereg,rlsd,sc,of)

    end

end

extract_time(e5ds::ERA5Hourly)  = e5ds.dtbeg : Month(1) : e5ds.dtend
extract_time(e5ds::ERA5Monthly) = e5ds.dtbeg : Year(1)  : e5ds.dtend