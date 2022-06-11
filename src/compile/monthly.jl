function compile(
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    egeo :: ERA5Region
)

    iseramohr = ERA5Monthly.hours

    yrbeg = year(e5ds.dtbeg)
    yrend = year(e5ds.dtend)
    nt    = yrend - yrbeg + 1

    lsd = getLandSea(e5ds,egeo)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the compilation ..."

    if iseramohr
        @info "$(modulelog()) - The ERA5 Dataset is an Hourly Monthly Dataset, allocating and adjusting compilation scripts ..."
        eint = zeros(Int16,nlon,nlat,288)
        eflt = zeros(Float32,nlon,nlat,288)
        earr = zeros(Float32,nlon,nlat,24,12)
    else
        eint = zeros(Int16,nlon,nlat,12)
        earr = zeros(Float32,nlon,nlat,12)
    end

    eavg = zeros(nlon,nlat)
    emax = zeros(nlon,nlat)
    emin = zeros(nlon,nlat)
    esea = zeros(nlon,nlat)

    if iseramohr; edhr = zeros(nlon,nlat) end

    for yr in yrbeg : yrend

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."

        eds = NCDataset(e5danc(e5ds,evar,date))
        sc = eds[evar.varID].attrib["scale_factor"]
        of = eds[evar.varID].attrib["add_offset"]
        mv = eds[evar.varID].attrib["missing_value"]
        fv = eds[evar.varID].attrib["_FillValue"]

        if iseramohr

            NCDatasets.load!(eds[evar.varID].var,eint,:,:,:,:)
            int2real!(eflt,eint,scale=sc,offset=of,mvalue=mv,fvalue=fv)
            for imo = 1 : 12, ihr = 1 : 24, ilat = 1 : nlat, ilon = 1 : nlon
                earr[ilon,ilat,ihr,imo] = eflt[ilon,ilat,ihr + (imo-1)*24]
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

            NCDatasets.load!(eds[evar.varID].var,eint,:,:,:)
            int2real!(earr,eint,scale=sc,offset=of,mvalue=mv,fvalue=fv)

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

    @info "$(modulelog()) - Calculating yearly mean, and diurnal, seasonal and interannual variability for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) ..."
    eavg = eavg / nt
    esea = esea / nt
    eian = emax .- emin

    if iseramohr
        edhr = edhr / nt
        save(eavg, edhr, esea, eian, e5ds, evar, egeo, lsd)
    else
        save(eavg,       esea, eian, e5ds, evar, egeo, lsd)
    end

end

function save(
    eavg :: Array{<:Real,2},
    edhr :: Array{<:Real,2},
    esea :: Array{<:Real,2},
    eian :: Array{<:Real,2},
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving compiled $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) ..."
    fnc = e5dcnc(e5ds,evar)
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
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    )

    scale,offset = ncoffsetscale(eavg)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"average",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = eavg

    scale,offset = ncoffsetscale(edhr)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_diurnal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = edhr

    scale,offset = ncoffsetscale(esea)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_seasonal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = esea

    scale,offset = ncoffsetscale(eian)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_interannual",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = eian

    close(ds)

    @info "$(modulelog()) - Compiled $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) has been saved into $(fnc)."

end

function save(
    eavg :: Array{<:Real,2},
    esea :: Array{<:Real,2},
    eian :: Array{<:Real,2},
    e5ds :: ERA5Monthly,
	evar :: ERA5Variable,
    ereg :: ERA5Region,
    lsd  :: LandSea
)

    @info "$(modulelog()) - Saving compiled $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) ..."
    fnc = e5dcnc(e5ds,evar)
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
        "long_name"     => evar.lname,
        "full_name"     => evar.vname,
        "units"         => evar.units,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
    )

    scale,offset = ncoffsetscale(eavg)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"average",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = eavg

    scale,offset = ncoffsetscale(esea)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_seasonal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = esea

    scale,offset = ncoffsetscale(eian)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_interannual",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = eian

    close(ds)

    @info "$(modulelog()) - Compiled $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) has been saved into $(fnc)."

end