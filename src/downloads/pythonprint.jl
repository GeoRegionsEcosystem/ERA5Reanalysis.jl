function pythonprint(
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
)
    
    if typeof(evar) <: PressureVariable
          fname = "$(e5ds.e5dID)-$(ereg.gstr)-$(evar.varID)-$(evar.hPa)hPa"
    else; fname = "$(e5ds.e5dID)-$(ereg.gstr)-$(evar.varID)"
    end

    fol,fnc = e5dfnc(e5ds,evar,ereg)

    if !isdir(fol)
        mkpath(fol)
        @info "$(modulelog()) - Creating data directory $fol"
    end

    fID = open(joinpath(fol,"$(fname).py"),"w")

    @info "$(modulelog()) - Creating python download scripts to download $(uppercase(e5ds.lname)) $(evar.vname) data in $(ereg.geo.name) (Horizontal Resolution: $(ereg.gres)) from $(e5ds.dtbeg) to $(e5ds.dtend)."

    write(fID,"#!/usr/bin/env python\n")
    write(fID,"import cdsapi\n")
    write(fID,"import os\n")
    write(fID,"c = cdsapi.Client()\n\n")

    yrbeg = year(e5ds.dtbeg); mobeg = month(e5ds.dtbeg)
    yrend = year(e5ds.dtend); moend = month(e5ds.dtend)

    if typeof(e5ds) <: ERA5Hourly
        for yrii in yrbeg : yrend
            folii = joinpath(fol,"$yrii")
            if !isdir(folii)
                mkpath(folii)
            end
        end
    end

    if yrbeg == yrend
        write(fID,"for yr in [$yrbeg]:\n")
        write(fID,"    for mo in $(collect(mobeg : moend)):\n")
        pythonprint_body(fID,fol,fnc,e5ds,evar,ereg)
    else

        write(fID,"for yr in [$yrbeg]:\n")
        write(fID,"    for mo in $(collect(mobeg : 12)):\n")
        pythonprint_body(fID,fol,fnc,e5ds,evar,ereg)

        if yrbeg != (yrend-1)

            write(fID,"for yr in $(collect((yrbeg+1) : (yrend-1))):\n")
            write(fID,"    for mo in $(collect(1 : 12)):\n")
            pythonprint_body(fID,fol,fnc,e5ds,evar,ereg)

        end

        write(fID,"for yr in [$yrend]:\n")
        write(fID,"    for mo in $(collect(1 : moend)):\n")
        pythonprint_body(fID,fol,fnc,e5ds,evar,ereg)

    end

    close(fID); return "$(fname).py"

end

function pythonprint_body(
    fID, fol :: AbstractString, fnc :: AbstractString,
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
)

    pythonprint_body_producttype(fID,e5ds,evar)
    pythonprint_body_variable(fID,evar)
    
    if !(ereg.isglb)
        geo = ereg.geo
        write(fID,"                \"area\": [$(geo.N), $(geo.W), $(geo.S), $(geo.E)],\n");
    end
    write(fID,"                \"grid\": [$(ereg.gres), $(ereg.gres)],\n");

    pythonprint_body_datetime(fID,e5ds)

    write(fID,"                \"format\": \"netcdf\"\n");
    write(fID,"            },\n");

    pythonprint_body_filename(fID,fol,fnc,e5ds)

end

function pythonprint_body_producttype(
    fID,
    e5ds :: ERA5Hourly,
    evar :: ERA5Variable,
)

    write(fID,"        c.retrieve(\"$(evar.dname)\",\n")
    write(fID,"            {\n");
    write(fID,"                \"product_type\": \"$(e5ds.ptype)\",\n");

end

function pythonprint_body_producttype(
    fID,
    e5ds :: ERA5Monthly,
    evar :: ERA5Variable,
)

    write(fID,"        c.retrieve(\"$(evar.dname)-monthly-means\",\n")
    write(fID,"            {\n");
    write(fID,"                \"product_type\": \"$(e5ds.ptype)\",\n");

end

function pythonprint_body_variable(
    fID, evar :: SingleVariable,
)

    write(fID,"                \"variable\": \"$(evar.lname)\",\n");

end

function pythonprint_body_variable(
    fID, evar :: PressureVariable,
)

    write(fID,"                \"variable\": \"$(evar.lname)\",\n");
    write(fID,"                \"pressure_level\": \"$(evar.hPa)\",\n");

end

function pythonprint_body_datetime(
    fID, :: ERA5Hourly,
)

    write(fID,"                \"year\": yr,\n");
    write(fID,"                \"month\": mo,\n");
    write(fID,"                \"day\":[\n");
    write(fID,"                    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,\n");
    write(fID,"                    13, 14, 15, 16, 17, 18, 19, 20, 21, 22,\n");
    write(fID,"                    23, 24, 25, 26, 27, 28, 29, 30, 31 \n");
    write(fID,"                ],\n");
    write(fID,"                \"time\":[\n");
    write(fID,"                    \"00:00\",\"01:00\",\"02:00\",\"03:00\",\"04:00\",\n");
    write(fID,"                    \"05:00\",\"06:00\",\"07:00\",\"08:00\",\"09:00\",\n");
    write(fID,"                    \"10:00\",\"11:00\",\"12:00\",\"13:00\",\"14:00\",\n");
    write(fID,"                    \"15:00\",\"16:00\",\"17:00\",\"18:00\",\"19:00\",\n");
    write(fID,"                    \"20:00\",\"21:00\",\"22:00\",\"23:00\"\n");
    write(fID,"                ],\n");

end

function pythonprint_body_datetime(
    fID, e5ds :: ERA5Monthly,
)

    write(fID,"                \"year\": yr,\n");
    write(fID,"                \"month\": [1,2,3,4,5,6,7,8,9,10,11,12],\n");

    if e5ds.hours
        write(fID,"                \"time\":[\n");
        write(fID,"                    \"00:00\",\"01:00\",\"02:00\",\"03:00\",\n");
        write(fID,"                    \"04:00\",\"05:00\",\"06:00\",\"07:00\",\n");
        write(fID,"                    \"08:00\",\"09:00\",\"10:00\",\"11:00\",\n");
        write(fID,"                    \"12:00\",\"13:00\",\"14:00\",\"15:00\",\n");
        write(fID,"                    \"16:00\",\"17:00\",\"18:00\",\"19:00\",\n");
        write(fID,"                    \"20:00\",\"21:00\",\"22:00\",\"23:00\"\n")
        write(fID,"                ],\n")
    end

end

function pythonprint_body_filename(
    fID, fol :: AbstractString, fnc :: AbstractString,
    :: ERA5Hourly,
)

    write(fID,"            os.path.join(\n")
    write(fID,"                \"$(fol)\", str(yr),\n")
    write(fID,"                \"$(fnc)-\" + str(yr) + str(mo).zfill(2) + \".nc\"\n")
    write(fID,"            )\n");
    write(fID,"        )\n\n");

end

function pythonprint_body_filename(
    fID, fol :: AbstractString, fnc :: AbstractString,
    :: ERA5Monthly,
)
    write(fID,"            os.path.join(\n")
    write(fID,"                \"$(fol)\",\n")
    write(fID,"                \"$(fnc)-\" + str(yr) + \".nc\"\n")
    write(fID,"            )\n");
    write(fID,"        )\n\n");

end