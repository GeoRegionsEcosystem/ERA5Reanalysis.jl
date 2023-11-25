function analysis(
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region
)

    yrbeg = year(e5ds.start)
    yrend = year(e5ds.stop)

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    mask = lsd.mask

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) Region ..."

    lon_NaN = zeros(Bool,nlon)
    lat_NaN = zeros(Bool,nlat)

    if iseramohr
        davg = zeros(Float64,nlon,nlat,28,16)
        zavg = zeros(Float64,nlat,28,16)
        mavg = zeros(Float64,nlon,28,16)
        tint = zeros(Int16,nlon,nlat,24,12)
        traw = zeros(Int16,nlon,nlat,288)
    else
        davg = zeros(Float64,nlon,nlat,16)
        zavg = zeros(Float64,nlat,16)
        mavg = zeros(Float64,nlon,16)
        tvar = zeros(Int16,nlon,nlat,12)
    end


    for yr in yrbeg : yrend

        @info "$(modulelog()) - Calculating monthly climatology and diurnal statistics for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."

        ds  = NCDataset(e5dfnc(e5ds,evar,ereg,Date(yr)))
        sc  = ds[evar.ID].attrib["scale_factor"]
        of  = ds[evar.ID].attrib["add_offset"]
        mv  = ds[evar.ID].attrib["missing_value"]
        fv  = ds[evar.ID].attrib["_FillValue"]

        if iseramohr
            NCDatasets.load!(ds[evar.ID].var,traw,:,:,:,:)
            for imo = 1 : 12, ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                tint[ilon,ilat,ihr,imo] = traw[ilon,ilat,ihr + (imo-1)*24]
            end
            int2real!(
                view(davg,:,:,1:24,1:12), tint,
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            for imo = 1 : 12, ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                if iszero(mask[ilon,ilat])
                    davg[ilon,ilat,ihr,imo] = NaN32
                end
            end
        else
            NCDatasets.load!(ds[evar.ID].var,tvar,:,:,:)
            int2real!(
                view(davg,:,:,1:12), tvar,
                scale=sc, offset=of, mvalue=mv, fvalue=fv
            )
            for imo = 1 : 12, ilat = 1 : nlat, ilon = 1 : nlon
                if iszero(mask[ilon,ilat])
                    davg[ilon,ilat,imo] = NaN32
                end
            end
        end

        close(ds)

        if iseramohr

            @info "$(modulelog()) - Calculating monthly climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for imo = 1 : 12, ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,25,imo] = mean(view(davg,ilon,ilat,1:24,imo))    # domain_monthly_mean_climatology
                dstd[ilon,ilat,26,imo] = std(view(davg,ilon,ilat,1:24,imo))     # domain_monthly_std_climatology
                dmax[ilon,ilat,27,imo] = maximum(view(davg,ilon,ilat,1:24,imo)) # domain_monthly_maximum_climatology
                dmin[ilon,ilat,28,imo] = minimum(view(davg,ilon,ilat,1:24,imo)) # domain_monthly_minimum_climatology
            end

            @info "$(modulelog()) - Calculating yearly diurnal climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,ihr,13] = mean(view(davg,ilon,ilat,ihr,1:12))    # domain_yearly_mean_hourly
                dstd[ilon,ilat,ihr,14] = std(view(davg,ilon,ilat,ihr,1:12))     # domain_yearly_std_hourly
                dmax[ilon,ilat,ihr,15] = maximum(view(davg,ilon,ilat,ihr,1:12)) # domain_yearly_maximum_hourly
                dmin[ilon,ilat,ihr,16] = minimum(view(davg,ilon,ilat,ihr,1:12)) # domain_yearly_minimum_hourly
            end

            @info "$(modulelog()) - Calculating yearly climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,25,13] = mean(view(davg,ilon,ilat,1:24,1:12))    # domain_yearly_mean_climatology
                dstd[ilon,ilat,26,14] = std(view(davg,ilon,ilat,1:24,1:12))     # domain_yearly_std_climatology
                dmax[ilon,ilat,27,15] = maximum(view(davg,ilon,ilat,1:24,1:12)) # domain_yearly_maximum_climatology
                dmin[ilon,ilat,28,16] = minimum(view(davg,ilon,ilat,1:24,1:12)) # domain_yearly_minimum_climatology
            end

            @info "$(modulelog()) - Calculating zonal-averaged climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for ilat = 1 : nlat, ihr = 1 : 28, imo = 1 : 16
                zavg[ilat,ihr,imo] = nanmean(view(davg,:,ilat,ihr,imo),lon_NaN)
                zstd[ilat,ihr,imo] = nanmean(view(dstd,:,ilat,ihr,imo),lon_NaN)
                zmax[ilat,ihr,imo] = nanmean(view(dmax,:,ilat,ihr,imo),lon_NaN)
                zmin[ilat,ihr,imo] = nanmean(view(dmin,:,ilat,ihr,imo),lon_NaN)
            end
            
            @info "$(modulelog()) - Calculating meridional-averaged climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for imo = 1 : 16, ihr = 1 : 28, ilon = 1 : nlon
                mavg[ilon,ihr,imo] = nanmean(view(davg,ilon,:,ihr,imo),lat_NaN)
                mstd[ilon,ihr,imo] = nanmean(view(dstd,ilon,:,ihr,imo),lat_NaN)
                mmax[ilon,ihr,imo] = nanmean(view(dmax,ilon,:,ihr,imo),lat_NaN)
                mmin[ilon,ihr,imo] = nanmean(view(dmin,ilon,:,ihr,imo),lat_NaN)
            end

        else
            
            @info "$(modulelog()) - Calculating yearly climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for ilat = 1 : nlat, ilon = 1 : nlon
                davg[ilon,ilat,13] = mean(view(davg,ilon,ilat,1:12))    # domain_yearly_mean_climatology
                davg[ilon,ilat,14] = std(view(davg,ilon,ilat,1:12))     # domain_yearly_std_climatology
                davg[ilon,ilat,15] = maximum(view(davg,ilon,ilat,1:12)) # domain_yearly_maximum_climatology
                davg[ilon,ilat,16] = minimum(view(davg,ilon,ilat,1:12)) # domain_yearly_minimum_climatology
            end

            @info "$(modulelog()) - Calculating zonal-averaged climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for ilat = 1 : nlat, imo = 1 : 16
                zavg[ilat,imo] = nanmean(view(davg,:,ilat,imo),lon_NaN)
            end
            
            @info "$(modulelog()) - Calculating meridional-averaged climatology for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."
            for imo = 1 : 16, ilon = 1 : nlon
                mavg[ilon,imo] = nanmean(view(davg,ilon,:,imo),lat_NaN)
            end

        end

        save(davg, zavg, mavg, Date(yr), e5ds, evar, ereg, lsd)

        flush(stderr)

    end

end

function save(
    davg :: Array{Float64,3},
    zavg :: Array{Float64,2},
    mavg :: Array{Float64,2},
    date :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving analyzed $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(date)) ..."
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
        "long_name"     => evar.long,
        "full_name"     => evar.name,
        "units"         => evar.units,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    )

    if typeof(evar) <: PressureLevel
        attr_var["level"] = evar.hPa
    end

    ## DOMAIN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(davg,:,:,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_mean_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_mean_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = real2int16(view(davg,:,:,13),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_std_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = real2int16(view(davg,:,:,14),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_maximum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(davg,:,:,15),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_minimum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(davg,:,:,16),scale,offset)

    ## ZONAL-MEAN CLIMATOLOGY

    scale,offset = ncoffsetscale(view(zavg,:,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_mean_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_mean_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zavg,:,13),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_std_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zstd,:,14),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_maximum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmax,:,15),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_minimum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zmin,:,16),scale,offset)

    ## MERIDIONAL-MEAN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(mavg,:,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_mean_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_mean_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mavg,:,13),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_std_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mavg,:,14),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_maximum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,15),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_minimum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,16),scale,offset)

    close(ds)

    @info "$(modulelog()) - Analyzed $(uppercase(e5ds.name)) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(date)) has been saved into $(fnc)."

end

function save(
    davg :: Array{Float64,4},
    zavg :: Array{Float64,3},
    mavg :: Array{Float64,3},
    date :: Date,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving analyzed $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(date)) ..."
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

    nclon = defVar(ds,"longitude",Float64,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float64,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nclon[:] = lsd.lon
    nclat[:] = lsd.lat
    
    attr_var = Dict(
        "long_name"     => evar.long,
        "full_name"     => evar.name,
        "units"         => evar.units,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    )

    if typeof(evar) <: PressureLevel
        attr_var["level"] = evar.hPa
    end

    ## MONTHLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_mean_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:,:,:,:] = real2int16(view(davg,:,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_mean_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:,:,:,:] = real2int16(view(zavg,:,:,1:24,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,:,1:24,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_mean_hourly",Int16,
        ("longitude","latitude","hour","month"),attrib=attr_var);
    ncvar.var[:,:,:,:] = real2int16(view(mavg,:,:,1:24,1:12),scale,offset)

    ## DOMAIN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(davg,:,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_mean_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = real2int16(view(davg,:,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,26,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_std_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = real2int16(view(davg,:,:,26,14),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,27,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_maximum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(davg,:,:,27,15),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,28,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_minimum_climatology",Int16,
        ("longitude","latitude"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(davg,:,:,28,16),scale,offset)

    ## DOMAIN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_mean_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_std_hourly",Int16,
    ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,1:24,14),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_maximum_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,1:24,15),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,1:24,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_yearly_minimum_hourly",Int16,
        ("longitude","latitude","hour"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,1:24,16),scale,offset)

    ## DOMAIN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(davg,:,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_mean_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,26,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_std_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,26,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,27,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_maximum_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,27,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(davg,:,:,28,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"domain_monthly_minimum_climatology",Int16,
        ("longitude","latitude","month"),attrib=attr_var);
    ncvar.var[:,:,:] = real2int16(view(davg,:,:,28,1:12),scale,offset)

    ## ZONAL-MEAN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(zavg,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_mean_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zavg,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,26,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_std_climatology",Int16,
        ("latitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(zavg,:,26,14),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,27,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_maximum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zavg,:,27,15),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,28,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_minimum_climatology",Int16,
        ("latitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(zavg,:,28,16),scale,offset)

    ## ZONAL-MEAN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(zavg,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_mean_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,1:24,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_std_hourly",Int16,
    ("latitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,1:24,14),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,1:24,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_maximum_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,1:24,15),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,1:24,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_yearly_minimum_hourly",Int16,
        ("latitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,1:24,16),scale,offset)

    ## ZONAL-MEAN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(zavg,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_mean_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,26,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_std_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,26,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,27,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_maximum_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,27,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(zavg,:,28,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"zonalavg_monthly_minimum_climatology",Int16,
        ("latitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(zavg,:,28,1:12),scale,offset)

    ## MERIDIONAL-MEAN YEARLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(mavg,:,25,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_mean_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mavg,:,25,13),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,26,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_std_climatology",Int16,
        ("longitude",),attrib=attr_var)
    ncvar.var[:] = real2int16(view(mavg,:,26,14),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,27,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_maximum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,27,15),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,28,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_minimum_climatology",Int16,
        ("longitude",),attrib=attr_var);
    ncvar.var[:] = real2int16(view(mavg,:,28,16),scale,offset)

    ## MERIDIONAL-MEAN YEARLY DIURNAL STATISTICS

    scale,offset = ncoffsetscale(view(mavg,:,1:24,13))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_mean_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,1:24,13),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,1:24,14))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_std_hourly",Int16,
    ("longitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,1:24,14),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,1:24,15))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_maximum_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,1:24,15),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,1:24,16))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_yearly_minimum_hourly",Int16,
        ("longitude","hour"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,1:24,16),scale,offset)

    ## MERIDIONAL-MEAN MONTHLY CLIMATOLOGY

    scale,offset = ncoffsetscale(view(mavg,:,25,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_mean_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,25,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,26,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_std_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,26,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,27,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_maximum_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,27,1:12),scale,offset)

    scale,offset = ncoffsetscale(view(mavg,:,28,1:12))
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"meridionalavg_monthly_minimum_climatology",Int16,
        ("longitude","month"),attrib=attr_var);
    ncvar.var[:,:] = real2int16(view(mavg,:,28,1:12),scale,offset)

    close(ds)

    @info "$(modulelog()) - Analyzed $(uppercase(e5ds.name)) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) for $(year(date)) has been saved into $(fnc)."

end