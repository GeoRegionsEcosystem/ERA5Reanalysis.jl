function resetERA5Variables(;allfiles=false)

    if allfiles

        @info "$(modulelog()) - Resetting both the master and custom lists of ERA5 variables back to the default"
        flist = [
            "singlevariable.txt","singletemplate.txt","singlecustom.txt",
            "pressurevariable.txt","pressurecustom.txt"
        ]
    else
        @info "$(modulelog()) - Resetting the custom lists of ERA5 variables back to the default"
        flist = ["singletemplate.txt","singlecustom.txt","pressurecustom.txt"]
    end

    for fname in flist
        copyERA5Variable(fname,overwrite=true)
    end

    return

end

function addERA5Variables(fname::AbstractString)

    @info "$(modulelog()) - Importing user-defined GeoRegions from the file $fname directly into the custom lists"

    vvec,vtype = listvariables(fname)
    for var in vvec
        if !isERA5Variable(var,throw=false)
            v = getgeoregion(var,fname,vtype)
            if vtype == "SingleLevel"
                SingleLevel()
            elseif vtype == "SingleCustom"
                SingleCustom()
            else
                PressureCustom()
            end
        else
            @warn "$(modulelog()) - The ERA5Variable ID $var is already in use. Please use a different ID, or you can remove the ID using rmERA5Variable()."
        end
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

function isera5variable(
    varID :: AbstractString,
    vlist :: AbstractArray;
    throw :: Bool=true)


    @info "$(modulelog()) - Checking to see if the ID $varID is in use"

    if sum(vlist.==varID) == 0
        if throw
            error("$(modulelog()) - $(varID) is not a valid GeoRegion identifier, use either RectRegion() or PolyRegion() to add this GeoRegion to the list.")
        else
            @warn "$(modulelog()) - $(varID) is not a valid GeoRegion identifier, use either RectRegion() or PolyRegion() to add this GeoRegion to the list."
            return false
        end
    else
        @info "$(modulelog()) - The ID $varID is already in use"
        return true
    end

end