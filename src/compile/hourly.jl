function compile(
    e5ds :: ERA5Hourly,
	evar :: ERA5Variable,
    ereg :: ERA5Region
)

    yrbeg = year(e5ds.start)
    yrend = year(e5ds.stop)
    nt    = yrend - yrbeg + 1

    lsd = getLandSea(e5ds,ereg)
    nlon = length(lsd.lon)
    nlat = length(lsd.lat)

    @info "$(modulelog()) - Preallocating data arrays for the compilation ..."

    eavg = zeros(Float64,nlon,nlat)
    emax = zeros(Float64,nlon,nlat)
    emin = zeros(Float64,nlon,nlat)
    erng = zeros(Float64,nlon,nlat)
    edhr = zeros(Float64,nlon,nlat)
    eitr = zeros(Float64,nlon,nlat)
    esea = zeros(Float64,nlon,nlat)

    for yr in yrbeg : yrend

        @info "$(modulelog()) - Loading $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) during $yr ..."

        eds = NCDataset(e5danc(e5ds,evar,date))

        eavg += eds["domain_yearly_mean_climatology"][:]
        erng += (eds["domain_yearly_maximum_climatology"][:] .- 
                 eds["domain_yearly_minimum_climatology"][:])
        esea += dropdims(maximum(eds["domain_monthly_mean_climatology"][:],dims=3) .- 
                         minimum(eds["domain_monthly_mean_climatology"][:],dims=3),dims=3)
        eitr += dropdims(mean(eds["domain_monthly_maximum_climatology"][:] .- 
                              eds["domain_monthly_minimum_climatology"][:],dims=3),dims=3)
        edhr += dropdims(maximum(eds["domain_yearly_mean_hourly"][:],dims=3) .- 
                         minimum(eds["domain_yearly_mean_hourly"][:],dims=3),dims=3)

        if yr == yrbeg
            emax += eds["domain_yearly_mean_climatology"][:]
            emin += eds["domain_yearly_mean_climatology"][:]
        else
            emax .= max.(eds["domain_yearly_mean_climatology"][:],emax)
            emin .= min.(eds["domain_yearly_mean_climatology"][:],emax)
        end

        close(eds)

    end

    @info "$(modulelog()) - Calculating yearly mean, and diurnal, seasonal and interannual variability for $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) ..."
    eavg = eavg / nt
    edhr = edhr / nt
    eitr = eitr / nt
    esea = esea / nt
    erng = erng / nt .- (esea .+ eitr)
    eian = emax .- emin

    save(eavg, edhr, eitr, esea, erng, eian, e5ds, evar, ereg, lsd)

end

function save(
    eavg :: Array{Float64,2},
    edhr :: Array{Float64,2},
    eitr :: Array{Float64,2},
    esea :: Array{Float64,2},
    erng :: Array{Float64,2},
    eian :: Array{Float64,2},
    e5ds :: ERA5Hourly,
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

    scale,offset = ncoffsetscale(eitr)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_intraseasonal",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = eitr

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

    scale,offset = ncoffsetscale(erng)
    attr_var["scale_factor"] = scale
    attr_var["add_offset"]   = offset
    ncvar = defVar(ds,"variability_noise",Int16,
        ("longitude","latitude"),attrib=attr_var)
    ncvar.var[:] = erng

    close(ds)

    @info "$(modulelog()) - Compiled $(e5ds.lname) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) has been saved into $(fnc)."

end