"""
    SingleLevel <: ERA5Variable

Abstract supertype for Single-Level variables, with the following subtypes:

    SingleVariable <: SingleLevel
    SingleCustom   <: SingleLevel
"""
abstract type SingleLevel <: ERA5Variable end

"""
    SingleVariable <: SingleLevel

Subtype for Single-Level variables that can be directly retrieved from the Climate Data Store.
"""
struct SingleVariable{ST<:AbstractString} <: SingleLevel
    ID      :: ST
    long    :: ST
    name    :: ST
    units   :: ST
    path    :: ST
    dataset :: ST
end


"""
    SingleCustom <: SingleLevel

Subtype for custom user-defined Single-Level variables, which can only be calculated and not downloaded from the Climate Data Store.
"""
struct SingleCustom{ST<:AbstractString} <: SingleLevel
    ID      :: ST
    long    :: ST
    name    :: ST
    units   :: ST
    path    :: ST
    dataset :: ST
end

"""
    SingleVariable(
        ID :: AbstractString,
        ST = String,
    ) -> evar :: SingleLevel

Retrieve the basic properties of the Single-Level variable defined by `ID` and put them in the `evar` SingleLevel type structure.

Arguments
=========

- `ID` : variable ID (in string format) used in the NetCDF file
"""
function SingleVariable(
    ID   :: AbstractString,
    ST = String;
    path :: AbstractString = pwd(),
    verbose :: Bool = false
)

    isSingleID(ID,path=path)

    if verbose; @info "$(modulelog()) - Retrieving information for the SingleVariable defined by the ID \"$ID\"" end
    vlist,flist,dlist = listSingles(path); ind = findall(ID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = joinpath(dlist[ind],flist[ind])
    vlist = listera5variables(fname); ind = findall(ID.==vlist)[1]

    ID,long,name,units = readdlm(fname,',',comments=true,comment_char='#')[ind,:]

    if vtype == "singlevariable"
        if verbose; @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the SingleVariable type" end
        return SingleVariable{ST}(ID,long,name,units,fname,"reanalysis-era5-single-levels")
    else
        if verbose; @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the SingleCustom type" end
        return SingleCustom{ST}(ID,long,name,units,fname,"reanalysis-era5-single-levels")
    end

end

"""
    SingleVariable(
        ST = String;
        ID :: AbstractString,
        long :: AbstractString = "",
        name :: AbstractString,
        units :: AbstractString
    ) -> evar :: SingleLevel

Create a custom Single-Level variable that is not in the default list exported by ERA5Reanalysis.jl.  These variables are not available in the CDS store, and so they must be separately calculated from other variables and analyzed.

Keyword Arguments
=================

- `ID` : variable ID (in string format) used in the NetCDF file
- `long` : long-name for variable (used in specifying variable for CDS downloads)
- `name` : user-defined variable name
- `units` : user-defined units of the variable
- `inCDS` : Boolean that indicates if this variable is available on the CDS store.  True if available.
"""
function SingleVariable(
    ST = String;
    ID :: AbstractString,
    long :: AbstractString = "",
    name :: AbstractString,
    units :: AbstractString,
    path  :: AbstractString = pwd(),
    save  :: Bool = false,
    verbose :: Bool = false,
)

    if isSingleID(ID,path=path,throw=false)
        error("$(modulelog()) - The SingleVariable \"$(ID)\" has already been defined,please use another identifier.")
    elseif verbose
        @info "$(modulelog()) - Adding the SingleVariable \"$(ID)\" to the list."
    end

    if save
        varfile = joinpath(path,"singlecustom.txt")
        if !isfile(varfile)
            cp(joinpath(eradir,"singlecustom.txt"),varfile)
        end
        open(varfile,"a") do io
            write(io,"$ID,$long,$name,$units\n")
        end
    end

    return SingleCustom{ST}(
        ID,long,name,units,joinpath(path,"singlecustom.txt"),
        "reanalysis-era5-single-levels"
    )

end

"""
    listSingles() -> varlist :: Array{ST}, fidlist :: Array{ST}

List all Single-Level Variables and the files the data are stored in.

Output
======

- `varlist` : List of all the Single-Level Variable IDs
- `fidlist` : List of the files that the Single-Level Variable information is stored in
"""
function listSingles(path :: AbstractString)

    varlist = []
    fidlist = []
    dirlist = []

    vvec = listera5variables(joinpath(eradir,"singlevariable.txt"))
    varlist = vcat(varlist,vvec);
    fvec = fill("singlevariable.txt",length(vvec)); fidlist = vcat(fidlist,fvec)
    dvec = fill(eradir,length(vvec)); dirlist = vcat(dirlist,dvec)

    vvec = listera5variables(joinpath(path,"singlecustom.txt"))
    varlist = vcat(varlist,vvec);
    fvec = fill("singlecustom.txt",length(vvec)); fidlist = vcat(fidlist,fvec)
    dvec = fill(path,length(vvec)); dirlist = vcat(dirlist,dvec)

    return varlist,fidlist,dirlist

end

"""
    resetSingles( allfiles :: Bool ) -> nothing

Reset the list of Single-Level variables.

Arguments
=========

- `allfiles` : If false, only get rid of all the SingleCustom variables, but if true, then the SingleVariable list will be reset back to the default for ERA5Reanalysis.jl
"""
function resetSingles(path :: AbstractString = pwd())

    @info "$(modulelog()) - Resetting the custom list of ERA5 SingleVariables back to the default"

    open(joinpath(path,"singlecustom.txt"),"w") do io
        open(joinpath(eradir,"singlecustom.txt")) do f
            for line in readlines(f)
                write(io,"$line\n")
            end
        end
    end

    return nothing

end