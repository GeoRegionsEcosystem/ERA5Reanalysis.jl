function compile(
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region
)

    iseramohr = ERA5Monthly.hours

    yrbeg = year(e5ds.start)
    yrend = year(e5ds.stop)
    nt    = yrend - yrbeg + 1

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)
    mask = lsd.mask

    @info "$(modulelog()) - Preallocating data arrays for the compilation ..."

    if iseramohr
        @info "$(modulelog()) - The ERA5 Dataset is an Hourly Monthly Dataset, allocating and adjusting compilation scripts ..."
        eint = zeros(Int16,nlon,nlat,288)
        eflt = zeros(Float64,nlon,nlat,288)
        earr = zeros(Float64,nlon,nlat,24,12)
    else
        eint = zeros(Int16,nlon,nlat,12)
        earr = zeros(Float64,nlon,nlat,12)
    end

    eavg = zeros(Float64,nlon,nlat)
    emax = zeros(Float64,nlon,nlat)
    emin = zeros(Float64,nlon,nlat)
    esea = zeros(Float64,nlon,nlat)

    if iseramohr; edhr = zeros(nlon,nlat) end

    for yr in yrbeg : yrend

        @info "$(modulelog()) - Loading $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) during $yr ..."

        eds = NCDataset(e5danc(e5ds,evar,date))
        sc = eds[evar.ID].attrib["scale_factor"]
        of = eds[evar.ID].attrib["add_offset"]
        mv = eds[evar.ID].attrib["missing_value"]
        fv = eds[evar.ID].attrib["_FillValue"]

        if iseramohr

            NCDatasets.load!(eds[evar.ID].var,eint,:,:,:,:)
            int2real!(eflt,eint,scale=sc,offset=of,mvalue=mv,fvalue=fv)
            for imo = 1 : 12, ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                if iszero(mask[ilon,ilat])
                    earr[ilon,ilat,ihr,imo] = NaN32
                else
                    earr[ilon,ilat,ihr,imo] = eflt[ilon,ilat,ihr + (imo-1)*24]
                end
            end

            eyr   = dropdims(mean(earr,dims=(3,4)),dims=(3,4))

            eavg += eyr
            esea += dropdims(maximum(mean(earr,dims=3),dims=4) .- 
                             minimum(mean(earr,dims=3),dims=4), dims=(3,4))
            edhr += dropdims(maximum(mean(earr,dims=4),dims=3) .- 
                             minimum(mean(earr,dims=4),dims=3), dims=(3,4))

            if yr == yrbeg
                emax += eyr
                emin += eyr
            else
                emax .= max.(eyr,emax)
                emin .= min.(eyr,emax)
            end

        else

            NCDatasets.load!(eds[evar.ID].var,eint,:,:,:)
            int2real!(earr,eint,scale=sc,offset=of,mvalue=mv,fvalue=fv)
            for imo = 1 : 12, ilat = 1 : nlat, ilon = 1 : nlon
                if iszero(mask[ilon,ilat])
                    earr[ilon,ilat,imo] = NaN32
                end
            end

            eyr   = dropdims(mean(earr,dims=3),dims=3)

            eavg += eyr
            esea += dropdims(maximum(earr,dims=3) .- 
                             minimum(earr,dims=3), dims=3)

            if yr == yrbeg
                emax += eyr
                emin += eyr
            else
                emax .= max.(eyr,emax)
                emin .= min.(eyr,emax)
            end

        end

        close(eds)

    end

    @info "$(modulelog()) - Calculating yearly mean, and diurnal, seasonal and interannual variability for $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) ..."
    eavg = eavg / nt
    esea = esea / nt
    eian = emax .- emin

    if iseramohr
        edhr = edhr / nt
        save(eavg, edhr, esea, eian, e5ds, evar, ereg, lsd)
    else
        save(eavg,       esea, eian, e5ds, evar, ereg, lsd)
    end

end

function save(
    eavg :: Array{Float64,2},
    edhr :: Array{Float64,2},
    esea :: Array{Float64,2},
    eian :: Array{Float64,2},
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSeaTopo
)

    @info "$(modulelog()) - Saving compiled $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) ..."
    fnc = e5dcnc(e5ds,evar,ereg)
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

    scale,offset = ncoffsetscale(eavg)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"average",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = eavg

    scale,offset = ncoffsetscale(edhr)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_diurnal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = edhr

    scale,offset = ncoffsetscale(esea)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_seasonal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = esea

    scale,offset = ncoffsetscale(eian)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_interannual",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = eian

    close(ds)

    @info "$(modulelog()) - Compiled $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) has been saved into $(fnc)."

end

function save(
    eavg :: Array{Float64,2},
    esea :: Array{Float64,2},
    eian :: Array{Float64,2},
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSeaTopo
)

    @info "$(modulelog()) - Saving compiled $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) ..."
    fnc = e5dcnc(e5ds,evar,ereg)
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

    scale,offset = ncoffsetscale(eavg)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"average",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = eavg

    scale,offset = ncoffsetscale(esea)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_seasonal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = esea

    scale,offset = ncoffsetscale(eian)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_interannual",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:,:] = eian

    close(ds)

    @info "$(modulelog()) - Compiled $(e5ds.name) $(evar.name) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.resolution)) has been saved into $(fnc)."

end