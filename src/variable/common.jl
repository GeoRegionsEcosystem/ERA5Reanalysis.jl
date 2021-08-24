function resetERA5Variables(;allfiles=false)

    if allfiles

        @info "$(now()) - ERA5Reanalysis.jl - Resetting both the master and custom lists of ERA5 variables back to the default"
        flist = [
            "singlevariable.txt","singletemplate.txt","singlecustom.txt",
            "pressurevariable.txt","pressurecustom.txt"
        ]
    else
        @info "$(now()) - ERA5Reanalysis.jl - Resetting the custom lists of ERA5 variables back to the default"
        flist = ["singletemplate.txt","singlecustom.txt","pressurecustom.txt"]
    end

    for fname in flist
        copyERA5Variable(fname,overwrite=true)
    end

    return

end

function addERA5Variables(fname::AbstractString)

    @info "$(now()) - ERA5Reanalysis.jl - Importing user-defined GeoRegions from the file $fname directly into the custom lists"

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
            @warn "$(now()) - ERA5Reanalysis.jl - The ERA5Variable ID $var is already in use. Please use a different ID, or you can remove the ID using rmERA5Variable()."
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
    ftem = joinpath(@__DIR__,"..","extra",fname)
    fvar = joinpath(jfol,fname)

    if !overwrite
        if !isfile(fvar)

            @debug "$(now()) - ERA5Reanalysis.jl - Unable to find $fvar, copying data from $ftem ..."

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
            @warn "$(now()) - ERA5Reanalysis.jl - Overwriting $fvar with original file in $ftem ..."
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

    return readdlm(fname,',',comments=true,comment_char='#')[:,1]

end

function isera5variable(
    varID :: AbstractString,
    vlist :: AbstractArray;
    throw :: Bool=true)


    @info "$(now()) - ERA5Reanalysis.jl - Checking to see if the ID $varID is in use"

    if sum(vlist.==varID) == 0
        if throw
            error("$(now()) - ERA5Reanalysis.jl - $(varID) is not a valid GeoRegion identifier, use either RectRegion() or PolyRegion() to add this GeoRegion to the list.")
        else
            @warn "$(now()) - ERA5Reanalysis.jl - $(varID) is not a valid GeoRegion identifier, use either RectRegion() or PolyRegion() to add this GeoRegion to the list."
            return false
        end
    else
        @info "$(now()) - ERA5Reanalysis.jl - The ID $varID is already in use"
        return true
    end

end