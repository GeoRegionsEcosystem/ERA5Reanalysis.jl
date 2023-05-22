function analysis(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    yrbeg = year(e5ds.start)
    yrend = year(e5ds.stop)

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    mask = lsd.mask

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    davg = zeros(Float64,nlon,nlat,25,13)
    dstd = zeros(Float64,nlon,nlat,25,13)
    dmax = zeros(Float64,nlon,nlat,25,13)
    dmin = zeros(Float64,nlon,nlat,25,13)

    lon_NaN = zeros(Bool,nlon)
    lat_NaN = zeros(Bool,nlat)

    zavg = zeros(Float64,nlat,25,13)
    zstd = zeros(Float64,nlat,25,13)
    zmax = zeros(Float64,nlat,25,13)
    zmin = zeros(Float64,nlat,25,13)

    mavg = zeros(Float64,nlon,25,13)
    mstd = zeros(Float64,nlon,25,13)
    mmax = zeros(Float64,nlon,25,13)
    mmin = zeros(Float64,nlon,25,13)

    tvar = zeros(Int16,nlon,nlat,24,31)
    rvar = zeros(Float64,nlon,nlat,24,31)
    dvar = zeros(Float64,nlon,nlat,31)

    for yr in yrbeg : yrend

        @info "$(modulelog()) - Calculating monthly climatology and diurnal statistics for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."
        for mo in 1 : 12

            if verbose
                @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
            end
            ndy = daysinmonth(Date(yr,mo))
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,Date(yr,mo)))
            sc  = ds[evar.varID].attrib["scale_factor"]
            of  = ds[evar.varID].attrib["add_offset"]
            mv  = ds[evar.varID].attrib["missing_value"]
            fv  = ds[evar.varID].attrib["_FillValue"]
            for idy = 1 : ndy, ihr = 1 : 24
                it = ihr + (idy-1) * 24
                tvr = view(tvar,:,:,ihr,idy)
                NCDatasets.load!(ds[evar.varID].var,tvr,:,:,it)
            end
            int2real!(
                view(rvar,:,:,:,1:ndy), view(tvar,:,:,:,1:ndy),
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            close(ds)

            for idy = 1 : ndy, ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                if iszero(mask[ilon,ilat])
                    rvar[ilon,ilat,ihr,idy] = NaN32
                end
            end

            if verbose
                @info "$(modulelog()) - Calculating daily means for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
            end
            for idy = 1 : ndy, ilat = 1 : nlat, ilon = 1 : nlon
                dvar[ilon,ilat,idy] = mean(view(rvar,ilon,ilat,:,idy))
            end

            if verbose
                @info "$(modulelog()) - Calculating diurnal statistics for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
            end
            for ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,ihr,mo] = mean(view(rvar,ilon,ilat,ihr,1:ndy))
                dstd[ilon,ilat,ihr,mo] = std(view(rvar,ilon,ilat,ihr,1:ndy))
                dmax[ilon,ilat,ihr,mo] = maximum(view(rvar,ilon,ilat,ihr,1:ndy))
                dmin[ilon,ilat,ihr,mo] = minimum(view(rvar,ilon,ilat,ihr,1:ndy))
            end

            if verbose
                @info "$(modulelog()) - Calculating monthly climatology for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr $(monthname(mo)) ..."
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,25,mo] = mean(view(dvar,ilon,ilat,1:ndy))
                dstd[ilon,ilat,25,mo] = std(view(dvar,ilon,ilat,1:ndy))
                dmax[ilon,ilat,25,mo] = maximum(view(dvar,ilon,ilat,1:ndy))
                dmin[ilon,ilat,25,mo] = minimum(view(dvar,ilon,ilat,1:ndy))
            end

        end

        @info "$(modulelog()) - Calculating yearly climatology for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."
        for ihr = 1 : 25, ilat = 1 : nlat, ilon = 1 : nlon
            davg[ilon,ilat,ihr,end] = 0
            dstd[ilon,ilat,ihr,end] = 0
            dmax[ilon,ilat,ihr,end] = 0
            dmin[ilon,ilat,ihr,end] = 0
            for imo = 1 : 12
                dtii = Date(yr,imo)
                davg[ilon,ilat,ihr,end] += davg[ilon,ilat,ihr,imo] * daysinmonth(dtii)
                dstd[ilon,ilat,ihr,end] += dstd[ilon,ilat,ihr,imo] * daysinmonth(dtii)
                dmax[ilon,ilat,ihr,end] += dmax[ilon,ilat,ihr,imo] * daysinmonth(dtii)
                dmin[ilon,ilat,ihr,end] += dmin[ilon,ilat,ihr,imo] * daysinmonth(dtii)
            end
            davg[ilon,ilat,ihr,end] /= daysinyear(yr)
            dstd[ilon,ilat,ihr,end] /= daysinyear(yr)
            dmax[ilon,ilat,ihr,end] /= daysinyear(yr)
            dmin[ilon,ilat,ihr,end] /= daysinyear(yr)
        end

        @info "$(modulelog()) - Calculating zonal-averaged climatology for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."
        for ilat = 1 : nlat, ihr = 1 : 25, imo = 1 : 13
            zavg[ilat,ihr,imo] = nanmean(view(davg,:,ilat,ihr,imo),lon_NaN);
            zstd[ilat,ihr,imo] = nanmean(view(dstd,:,ilat,ihr,imo),lon_NaN);
            zmax[ilat,ihr,imo] = nanmean(view(dmax,:,ilat,ihr,imo),lon_NaN);
            zmin[ilat,ihr,imo] = nanmean(view(dmin,:,ilat,ihr,imo),lon_NaN);
        end
        
        @info "$(modulelog()) - Calculating meridional-averaged climatology for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."
        for imo = 1 : 13, ihr = 1 : 25, ilon = 1 : nlon
            mavg[ilon,ihr,imo] = nanmean(view(davg,ilon,:,ihr,imo),lat_NaN);
            mstd[ilon,ihr,imo] = nanmean(view(dstd,ilon,:,ihr,imo),lat_NaN);
            mmax[ilon,ihr,imo] = nanmean(view(dmax,ilon,:,ihr,imo),lat_NaN);
            mmin[ilon,ihr,imo] = nanmean(view(dmin,ilon,:,ihr,imo),lat_NaN);
        end

        save(
            davg, dstd, dmax, dmin, zavg, zstd, zmax, zmin, mavg, mstd, mmax, mmin,
            Date(yr), e5ds, evar, ereg, lsd
        )

        flush(stderr)

    end

end

function save(
    davg :: Array{Float64,4},
    dstd :: Array{Float64,4},
    dmax :: Array{Float64,4},
    dmin :: Array{Float64,4},
    zavg :: Array{Float64,3},
    zstd :: Array{Float64,3},
    zmax :: Array{Float64,3},
    zmin :: Array{Float64,3},
    mavg :: Array{Float64,3},
    mstd :: Array{Float64,3},
    mmax :: Array{Float64,3},
    mmin :: Array{Float64,3},
    date :: Date,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving analyzed $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) ..."
    fnc = e5danc(e5ds,evar,ereg,date)
    fol = dirname(fnc); if !isdir(fol); mkpath(fol) end
    if isfile(fnc)
        @info "$(modulelog()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end
    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(modulelog()) with ERA5Reanalysis.jl",
        "comments"    => "ERA5Reanalysis.jl creates NetCDF files in the same format that data is saved on the Climate Data Store"
    ))
    ds.attrib["doi"] = e5ds.sldoi

    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)
    ds.dim["hour"]  = 24
    ds.dim["month"] = 12

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nclon[:] = lsd.lon
    nclat[:] = lsd.lat
    
    attr_var = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    )

    if typeof(evar) <: PressureLevel
        attr_var["level"] = evar.hPa
    end

    ## DOMAIN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(davg,:,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_mean_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = real2int16(view(davg,:,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(dstd,:,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_std_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = real2int16(view(dstd,:,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(dmax,:,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_maximum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmax,:,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(dmin,:,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_minimum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmin,:,:,25,13),scale,offset)

    ## DOMAIN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_mean_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(davg,:,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(dstd,:,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_std_hourly",Int16,
    ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dstd,:,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(dmax,:,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_maximum_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmax,:,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(dmin,:,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_minimum_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmin,:,:,1:24,13),scale,offset)

    ## DOMAIN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(davg,:,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_mean_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(davg,:,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dstd,:,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_std_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dstd,:,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dmax,:,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_maximum_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmax,:,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dmin,:,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_minimum_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmin,:,:,25,1:12),scale,offset)

    ## DOMAIN MONTHLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_mean_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(davg,:,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dstd,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_std_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
        ncvar.var[:] = real2int16(view(dstd,:,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dmax,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_maximum_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmax,:,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(dmin,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_minimum_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(dmin,:,:,1:24,1:12),scale,offset)

    ## ZONAL-MEAN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(zavg,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_mean_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zavg,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(zstd,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_std_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zstd,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(zmax,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_maximum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmax,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(zmin,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_minimum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmin,:,25,13),scale,offset)

    ## ZONAL-MEAN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(zavg,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_mean_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zavg,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(zstd,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_std_hourly",Int16,
    ("latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zstd,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(zmax,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_maximum_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmax,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(zmin,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_minimum_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmin,:,1:24,13),scale,offset)

    ## ZONAL-MEAN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(zavg,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_mean_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zavg,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zstd,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_std_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zstd,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zmax,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_maximum_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmax,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zmin,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_minimum_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmin,:,25,1:12),scale,offset)

    ## ZONAL-MEAN MONTHLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(zavg,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_mean_hourly",Int16,
        ("latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zavg,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zstd,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_std_hourly",Int16,
        ("latitude","hour","month"),attrib=attr_var);
        ncvar.var[:] = real2int16(view(zstd,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zmax,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_maximum_hourly",Int16,
        ("latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmax,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zmin,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_minimum_hourly",Int16,
        ("latitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmin,:,1:24,1:12),scale,offset)

    ## MERIDIONAL-MEAN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(mavg,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_mean_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mavg,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(mstd,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_std_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mstd,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(mmax,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_maximum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmax,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(mmin,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_minimum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmin,:,25,13),scale,offset)

    ## MERIDIONAL-MEAN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(mavg,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_mean_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(mstd,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_std_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mstd,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(mmax,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_maximum_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmax,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(mmin,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_minimum_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmin,:,1:24,13),scale,offset)

    ## MERIDIONAL-MEAN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(mavg,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_mean_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mstd,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_std_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mstd,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mmax,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_maximum_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmax,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mmin,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_minimum_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmin,:,25,1:12),scale,offset)

    ## MERIDIONAL-MEAN MONTHLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(mavg,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_mean_hourly",Int16,
        ("longitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mstd,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_std_hourly",Int16,
        ("longitude","hour","month"),attrib=attr_var);
        ncvar.var[:] = real2int16(view(mstd,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mmax,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_maximum_hourly",Int16,
        ("longitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmax,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mmin,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_minimum_hourly",Int16,
        ("longitude","hour","month"),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mmin,:,1:24,1:12),scale,offset)

    close(ds)

    @info "$(modulelog()) - Analyzed $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) has been saved into $(fnc)."

end