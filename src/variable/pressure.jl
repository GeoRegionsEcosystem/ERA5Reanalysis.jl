"""
    PressureLevel <: ERA5Variable

Abstract supertype for Single-Level variables, with the following subtypes:

    PressureVariable <: PressureLevel
    PressureCustom   <: PressureLevel
"""
abstract type PressureLevel <: ERA5Variable end

"""
    PressureVariable <: PressureLevel

Subtype for Pressure-Level variables that can be directly retrieved from the Climate Data Store.
"""
struct PressureVariable{ST<:AbstractString} <: PressureLevel
    ID    :: ST
    long  :: ST
    name  :: ST
    units :: ST
    hPa   :: Int
    path  :: ST
    dataset   :: ST
    analysis  :: Bool
    forecast  :: Bool
    invariant :: Bool
    ncID :: ST
    mars :: Int
    dkrz :: Union{Int,Missing}
end

"""
    PressureCustom <: PressureLevel

Subtype for custom user-defined Pressure-Level variables which can only be calculated and not downloaded from the Climate Data Store.
"""
struct PressureCustom{ST<:AbstractString} <: PressureLevel
    ID    :: ST
    long  :: ST
    name  :: ST
    units :: ST
    hPa   :: Int
    path  :: ST
    ncID  :: ST
end

"""
    PressureVariable(
        ID :: AbstractString,
        ST = String;
        hPa   :: Int = 0
        throw :: Bool = true
    ) -> evar :: SingleLevel

Retrieve the basic properties of the Pressure-Level variable defined by `ID` at pressure-height indicated by `hPa` and put them in the `evar` SingleLevel type structure.

Arguments
=========

- `ID` : variable ID (in string format) used in the NetCDF file

Keyword Arguments
=================

- `hPa` : Integer specifying pressure-level height in hPa
- `throw` : if `hPa` level does not exist and `throw` is true, throw error, otherwise find nearest pressure level
"""
function PressureVariable(
    ID :: AbstractString,
    ST = String;
    hPa  :: Int = 0,
    path :: AbstractString = homedir(),
    throw   :: Bool = true,
    verbose :: Bool = false
)

    isPressureID(ID,path=path)

    if verbose; @info "$(modulelog()) - Retrieving information for the PressureVariable defined by the ID \"$ID\"" end
    vlist,flist,plist = listPressures(path); ind = findall(ID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = joinpath(plist[ind],flist[ind])
    vlist = listera5variables(fname); ind = findall(ID.==vlist)[1]

    ID,name,units,long = readdlm(fname,',',comments=true,comment_char='#')[ind,[1,2,3,7]]

    hPa = checkPressure(hPa,throw=throw)

    if vtype == "pressurevariable"
        if verbose; @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the PressureVariable type" end
        an,fc,iv,nc,mars,dkrz = readdlm(fname,',',comments=true,comment_char='#')[ind,[4,5,6,8,9,10]]
        return PressureVariable{ST}(
            ID,long,name * " ($(hPa) hPa)",units,hPa,fname,
            "reanalysis-era5-pressure-levels",an,fc,iv,nc,mars,dkrz
        )
    else
        if verbose; @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the PressureCustom type" end
        return PressureCustom{ST}(ID,long,name * " ($(hPa) hPa)",units,hPa,fname,ID)
    end

end

"""
    PressureVariable(
        ST = String;
        ID :: AbstractString,
        long :: AbstractString = "",
        name :: AbstractString,
        units :: AbstractString,
        hPa   :: Int = 0,
        throw :: Bool = true
    ) -> evar :: PressureCustom

Create a custom Pressure-Level variable that is not in the default list exported by ERA5Reanalysis.jl.  These variables are not available in the CDS store, and so they must be separately calculated from other variables and analyzed.

Keyword Arguments
=================

- `ID` : variable ID (in string format) used in the NetCDF file
- `long` : long-name for variable (used in specifying variable for CDS downloads)
- `name` : user-defined variable name
- `units` : user-defined units of the variable
- `hPa`   : Pressure level specified in hPa. Default is 0, which indicates all levels.
- `throw` : if `hPa` level does not exist and `throw` is true, throw error, otherwise find nearest pressure level
"""
function PressureVariable(
    ST = String;
    ID :: AbstractString,
    long :: AbstractString = "",
    name :: AbstractString,
    units :: AbstractString,
    hPa   :: Int = 0,
    path  :: AbstractString = pwd(),
    save  :: Bool = false,
    throw :: Bool = true,
    verbose :: Bool = false
)

    if isPressureID(ID,path=path,throw=false)
        error("$(modulelog()) - The PressureVariable \"$(ID)\" has already been defined, please use another identifier.")
    elseif verbose
        @info "$(modulelog()) - Adding the PressureVariable \"$(ID)\" to the list."
    end

    if save
        varfile = joinpath(path,"pressurecustom.txt")
        if !isfile(varfile)
            cp(joinpath(eradir,"pressurecustom.txt"),varfile)
        end
        open(varfile,"a") do io
            write(io,"$ID,$name,$units,false,false,false,$long,$ID,missing,missing\n")
        end
    end

    hPa = checkPressure(hPa,throw=throw)

    return PressureCustom{ST}(
        ID,long,name * " ($(hPa) hPa)",units,hPa,joinpath(path,"pressurecustom.txt"),ID
    )

end

"""
    listPressures()

List all Pressure-Level Variables and the files the data are stored in.

Output
======

- `varlist` : List of all the Pressure-Level Variable IDs
- `fidlist` : List of the files that the Pressure-Level Variable information is stored in
"""
function listPressures(path :: AbstractString)

    varlist = []
    fidlist = []
    dirlist = []

    vvec = listera5variables(joinpath(eradir,"pressurevariable.txt"))
    varlist = vcat(varlist,vvec);
    fvec = fill("pressurevariable.txt",length(vvec)); fidlist = vcat(fidlist,fvec)
    dvec = fill(eradir,length(vvec)); dirlist = vcat(dirlist,dvec)

    vvec = listera5variables(joinpath(path,"pressurecustom.txt"))
    varlist = vcat(varlist,vvec);
    fvec = fill("pressurecustom.txt",length(vvec)); fidlist = vcat(fidlist,fvec)
    dvec = fill(path,length(vvec)); dirlist = vcat(dirlist,dvec)

    return varlist,fidlist,dirlist

end

"""
    resetPressures() -> nothing

Reset the list of Pressure-Level variables to the ERA5Reanalysis default.
"""
function resetPressures(path :: AbstractString = pwd())

    @info "$(modulelog()) - Resetting the custom list of ERA5 PressureVariables back to the default"

    open(joinpath(path,"pressurecustom.txt"),"w") do io
        open(joinpath(eradir,"pressurecustom.txt")) do f
            for line in readlines(f)
                write(io,"$line\n")
            end
        end
    end

    return nothing

end

"""
    era5Pressures() -> parray :: Vector{Int}

Returns the a vector containing the 37 pressure levels available in ERA5 in hPa units.

Returns
=======

- `parray` : vector containing list of pressures in Int format and hPa units
"""
era5Pressures() = [
    1,2,3,5,7,10,20,30,50,70,100,125,150,175,200,
    225,250,300,350,400,450,500,550,600,650,700,750,
    775,800,825,850,875,900,925,950,975,1000
]

function checkPressure(
    hPa :: Int;
    throw :: Bool = true
)

    if !iszero(hPa)
        prelist = era5Pressures()
        if iszero(sum(prelist.==hPa))
            if throw
                error("$(modulelog()) - Pressure level specified in \"hPa\" argument is invalid, please check and see if you requested correctly")
            else
                @warn "$(modulelog()) - Pressure level specified in \"hPa\" argument does not exist, snapping to nearest pressure level"
                ipre = argmin(abs.(prelist.-hPa))
                hPa  = prelist[ipre]
            end
        end
    end
    
    return hPa

end