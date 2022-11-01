function hourly2monthly(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region;
    verbose :: Bool = false
)

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the analysis of data in the $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) Region ..."

    tmpload = zeros(Int16,nlon,nlat,744)
    tmpdata = zeros(nlon,nlat,744)
    modata  = zeros(nlon,nlat,12)

    for dt in e5ds.start : Year(1) : e5ds.stop

        for imo = 1 : 12

            if verbose
                @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
            end
            nhr = daysinmonth(dt)
            ds  = NCDataset(e5dfnc(e5ds,evar,ereg,dt))
            sc  = ds[evar.varID].attrib["scale_factor"]
            of  = ds[evar.varID].attrib["add_offset"]
            mv  = ds[evar.varID].attrib["missing_value"]
            fv  = ds[evar.varID].attrib["_FillValue"]
            NCDatasets.load!(ds[evar.varID].var,view(tmpload,:,:,1:nhr),:,:,:)
            int2real!(
                view(tmpdata,:,:,1:nhr),view(tmpload,:,:,1:nhr),
                scale=sc,offset=of,mvalue=mv,fvalue=fv
            )
            close(ds)

            if verbose
                @info "$(modulelog()) - Performing daily-averaging on $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $(year(dt)) $(monthname(dt)) ..."
            end
            for ilat = 1 : nlat, ilon = 1 : nlon
                modata[ilon,ilat,imo] = mean(view(tmpdata,ilon,ilat,1:nhr))
            end

            save_hourly2monthly(view(dydata,:,:,1:ndy), e5ds, evar, ereg, lsd, dt)

        end

    end

end

function save_hourly2monthly(
    dayts :: AbstractArray{<:Real,3},
    e5ds  :: ERA5Hourly,
    evar  :: ERA5Variable,
    ereg  :: ERA5Region,
    lsd   :: LandSea,
    date  :: TimeType
)

    @info "$(modulelog()) - Saving daily $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) ..."

    fnc = e5dh2d(e5ds,evar,ereg,date)
    fol = dirname(fnc); if !isdir(fol); mkpath(fol) end
    if isfile(fnc)
        @info "$(modulelog()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end
    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions" => "CF-1.6",
        "history"     => "Created on $(Dates.now()) with ERA5Reanalysis.jl",
        "comments"    => "ERA5Reanalysis.jl creates NetCDF files in the same format that data is saved on the Climate Data Store"
    ))

    if typeof(evar) <: SingleVariable
        ds.attrib["doi"] = e5ds.sldoi
    elseif typeof(evar) <: PressureVariable
        ds.attrib["doi"] = e5ds.pldoi
    end

    ndy = size(dayts,3)
    ds.dim["time"] = ndy
    ds.dim["longitude"] = length(lsd.lon)
    ds.dim["latitude"]  = length(lsd.lat)

    nclon = defVar(ds,"longitude",Float32,("longitude",),attrib = Dict(
        "units"     => "degrees_east",
        "long_name" => "longitude",
    ))

    nclat = defVar(ds,"latitude",Float32,("latitude",),attrib = Dict(
        "units"     => "degrees_north",
        "long_name" => "latitude",
    ))

    nctime = defVar(ds,"time",Int32,("time",),attrib = Dict(
        "units"     => "days since $(date) 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "gregorian",
    ))

    ncday = defVar(ds,"$(evar.varID)",Float64,("longitude","latitude","time",),attrib = Dict(
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
    ))
    
    nclon[:] = lsd.lon
    nclat[:] = lsd.lat
    nctime[:] = collect(1:ndy) .- 1
    ncday[:] = dayts

    close(ds)

    @info "$(modulelog()) - Daily timeseries of $(uppercase(e5ds.lname)) $(evar.vname) in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) for $(year(date)) $(Dates.monthname(date)) has been saved into $(fnc)."

end