"""
    resetERA5Variables( allfiles :: Bool ) -> nothing

Reset the list of Single-Level and PressureCustom variables.

Arguments
=========

- `allfiles` : If false, only get rid of all the SingleCustom variables, but if true, then the SingleVariable list will be reset back to the default for ERA5Reanalysis.jl
"""
function resetERA5Variables(;allfiles=false)

    if allfiles

        @info "$(modulelog()) - Resetting both the master and custom lists of ERA5 variables back to the default"
        flist = [
            "singlevariable.txt","singlecustom.txt",
            "pressurevariable.txt","pressurecustom.txt"
        ]
    else
        @info "$(modulelog()) - Resetting the custom lists of ERA5 variables back to the default"
        flist = ["singlevariable.txt","singlecustom.txt","pressurecustom.txt"]
    end

    for fname in flist
        copyera5variables(fname,overwrite=true)
    end

    return

end

function addERA5Variables(fname::AbstractString)

    @info "$(modulelog()) - Importing user-defined GeoRegions from the file $fname directly into the custom lists"

    vtype  = evarfiletype(fname)
    vlist  = listera5variables(fname); nvar = length(vlist)
    varray = readdlm(fname,',',comments=true,comment_char='#')

    if vtype == "SingleLevel"
        for ivar in 1 : nvar
            if isSingle(vlist[ivar],throw=false)
                @warn "$(modulelog()) - The SingleVariable ID \"$(vlist[ivar])\" is already in use and thus cannot be added to singlevariable.txt, please use another ID"
            else
                SingleVariable(
                    ID = varray[ivar,1], long = varray[ivar,2],
                    name = varray[ivar,3], units = varray[ivar,4],
                    inCDS = false
                )
            end
        end
    elseif vtype == "SingleCustom"
        for ivar in 1 : nvar
            if isSingle(vlist[ivar],throw=false)
                @warn "$(modulelog()) - The SingleVariable ID \"$(vlist[ivar])\" is already in use and thus cannot be added to singlecustom.txt, please use another ID"
            else
                SingleVariable(
                    ID = varray[ivar,1], long = varray[ivar,2],
                    name = varray[ivar,3], units = varray[ivar,4]
                )
            end
        end
    elseif vtype == "PressureCustom"
        for ivar in 1 : nvar
            if isPressure(vlist[ivar],throw=false)
                @warn "$(modulelog()) - The PressureVariable ID \"$(vlist[ivar])\" is already in use and thus cannot be added to pressurecustom.txt, please use another ID"
            else
                PressureVariable(
                    ID = varray[ivar,1], long = varray[ivar,2],
                    name = varray[ivar,3], units = varray[ivar,4],
                )
            end
        end
    elseif vtype == "PressureLevel"
        error("$(modulelog()) - All the downloadable pressure variables from the ERA5 Climate Data Store have been listed in ERA5Reanalysis.jl")
    else
        error("$(modulelog()) - Unable to identify ERA5 Variable type, please go back and check the file header again")
    end

    return nothing

end

function rmERA5Variable(
    evar :: ERA5Variable
)

    if typeof(evar) <: Union{SingleVariable,PressureVariable}
        error("$(modulelog()) - Variables of the types SingleVariable and PressureVariable cannot be removed")
    end

    if typeof(evar) <: SingleCustom
        fid = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis","singlecustom.txt")
    elseif typeof(evar) <: PressureCustom
        fid = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis","pressurecustom.txt")
    end

    flines = readlines(fid)
    nlines = length(flines)

    open("tmp.txt","w") do io
        for iline = 1 : nlines
            if !occursin("$(evar.ID),",flines[iline])
                write(io,"$(flines[iline])\n")
            end
        end
    end

    mv("tmp.txt",fid,force=true)

    return nothing

end

function tableERA5Variables(;custom::Bool=false)

    jfol = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis"); mkpath(jfol);
    if custom
        fvar = ["SingleCustom","PressureCustom"]
    else
        fvar = ["SingleVariable","SingleCustom","PressureVariable","PressureCustom"]
    end
    fmat = []
    
    for fname in fvar
        fid  = joinpath(jfol,"$(lowercase(fname)).txt")
        try
            vmat = readdlm(fid,',',comments=true,comment_char='#')
            nvar = size(vmat,1); ff = fill(fname,nvar)
            vmat = cat(ff,vmat[:,[1,3,4,2]],dims=2)
            fmat = cat(fmat,vmat,dims=1)
        catch
        end
    end

    head = ["Variable Type","ID","Name","Units","ERA5 Long-Name"];

    if isempty(fmat)
        fmat  = Array{String,2}(undef,1,5)
        fmat .= "N/A"
    end
    
    pretty_table(
        fmat,header=head,
        alignment=[:c,:c,:l,:c,:l],
        crop = :none, tf = tf_compact
    );

    

end

function templateERA5Variables(;path=pwd(),force=false)

    flist = ["singlevariable.txt","singlecustom.txt","pressurecustom.txt"]

    for fname in flist
        ftem = joinpath(@__DIR__,"..","..","extra",fname)
        fvar = joinpath(path,fname)
        cp(ftem,fvar,force=force)
    end

    return nothing

end

## Backend Functions

function copyera5variables(
    fname::AbstractString;
    overwrite::Bool=false
)

    jfol = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis"); mkpath(jfol);
    ftem = joinpath(@__DIR__,"..","..","extra",fname)
    fvar = joinpath(jfol,fname)

    if !overwrite
        if !isfile(fvar)

            @debug "$(modulelog()) - Unable to find $fvar, copying data from $ftem ..."

            open(fvar,"w") do io
                open(ftem) do f
                    for line in readlines(f)
                        write(io,"$line\n")
                    end
                end
            end

        end
    else

        if isfile(fvar)
            @warn "$(modulelog()) - Overwriting $fvar with original file in $ftem ..."
            rm(fvar,force=true)
        end

        open(fvar,"w") do io
            open(ftem) do f
                for line in readlines(f)
                    write(io,"$line\n")
                end
            end
        end

    end

    return

end

function listera5variables(fname::AbstractString)

    try
        return readdlm(fname,',',comments=true,comment_char='#')[:,1]
    catch
        return []
    end

end

function evarfiletype(fname::AbstractString)

    vtype = readlines(fname)[1]
    vtype = replace(vtype,"#"=>"")
    vtype = replace(vtype," "=>"")

    return vtype

end