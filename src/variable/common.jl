"""
    resetERA5Variables( allfiles :: Bool ) -> nothing

Reset the list of Single-Level and PressureCustom variables.

Arguments
=========

- `allfiles` : If false, only get rid of all the SingleCustom variables, but if true, then the SingleVariable list will be reset back to the default for ERA5Reanalysis.jl
"""
function setupERA5Variables(;
    path :: AbstractString = pwd(),
    overwrite :: Bool = false
)

    if !isdir(path); mkpath(path) end
    for fname in ["singlecustom.txt","pressurecustom.txt"]

        ftem = joinpath(eradir,fname)
        freg = joinpath(path,fname)

        if !overwrite
            if !isfile(freg)

                @debug "$(modulelog()) - Unable to find $freg, copying data from $ftem ..."

                open(freg,"w") do io
                    open(ftem) do f
                        for line in readlines(f)
                            write(io,"$line\n")
                        end
                    end
                end

            end
        else

            if isfile(freg)
                @warn "$(modulelog()) - Overwriting $freg with original file in $ftem ..."
                rm(freg,force=true)
            end

            open(freg,"w") do io
                open(ftem) do f
                    for line in readlines(f)
                        write(io,"$line\n")
                    end
                end
            end

        end

    end

    return nothing

end

function readGeoRegions(
    fname :: AbstractString
)

    @info "$(modulelog()) - Importing user-defined GeoRegions from the file $fname directly into the custom lists"

    vtype  = evarfiletype(fname)
    vlist  = listera5variables(fname); nvar = length(vlist)
    varray = readdlm(fname,',',comments=true,comment_char='#')

    if vtype == "SingleCustom"
        evar = Vector{SingleCustom}(undef,nvar)
        for ivar in 1 : nvar
            evar[ivar] = SingleVariable(
                ID = varray[ivar,1], long = varray[ivar,2],
                name = varray[ivar,3], units = varray[ivar,4]
            )
        end
    elseif vtype == "PressureCustom"
        evar = Vector{PressureCustom}(undef,nvar)
        for ivar in 1 : nvar
            evar[ivar] = PressureVariable(
                ID = varray[ivar,1], long = varray[ivar,2],
                name = varray[ivar,3], units = varray[ivar,4]
            )
        end
    end

    return evar

end

function addERA5Variables(
    fname :: AbstractString;
    path  :: AbstractString = pwd(),
    overwrite :: Bool = false,
    verbose   :: Bool = false
)

    @info "$(modulelog()) - Importing user-defined GeoRegions from the file $fname directly into the custom lists"

    vtype  = evarfiletype(fname)
    vlist  = listera5variables(fname); nvar = length(vlist)
    varray = readdlm(fname,',',comments=true,comment_char='#')

    if vtype == "SingleCustom"
        for ivar in 1 : nvar
            evar = SingleVariable(
                ID = varray[ivar,1], long = varray[ivar,2],
                name = varray[ivar,3], units = varray[ivar,4]
            )
            if !isSingle(vlist[ivar],path=path,throw=false)
                add(evar,path=path)
            elseif overwrite
                overwrite(evar,path=path)
            else
                @warn "$(modulelog()) - The SingleVariable ID \"$(vlist[ivar])\" is already in use and thus cannot be added to singlecustom.txt, please use another ID"
            end
        end
    elseif vtype == "PressureCustom"
        for ivar in 1 : nvar
            evar = PressureVariable(
                ID = varray[ivar,1], long = varray[ivar,2],
                name = varray[ivar,3], units = varray[ivar,4]
            )
            if !isPressure(vlist[ivar],path=path,throw=false)
                add(evar,path=path)
            elseif overwrite
                overwrite(evar,path=path)
            else
                @warn "$(modulelog()) - The PressureVariable ID \"$(vlist[ivar])\" is already in use and thus cannot be added to pressurecustom.txt, please use another ID"
            end
        end
    elseif vtype == "PressureLevel"
        error("$(modulelog()) - All the downloadable pressure-level variables from the ERA5 Climate Data Store have been listed in ERA5Reanalysis.jl")
    elseif vtype == "PressureLevel"
        error("$(modulelog()) - All the downloadable single-level variables from the ERA5 Climate Data Store have been listed in ERA5Reanalysis.jl")
    end

    return nothing

end

function deleteERA5Variables(;
    path :: AbstractString = pwd()
)

    @warn "$(modulelog()) - Removing custom ERA5Variable files from $path, all ERA5Variable information saved into these files will be permanently lost."
    flist = ["singlecustom.txt","pressurecustom.txt"]
    for fname in flist
        rm(joinpath(path,fname),force=true)
    end

    return nothing

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