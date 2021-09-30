"""
    PressureLevel <: ERA5Variable

Abstract supertype for Pressure-Level variables.  Contains the following fields:
- `varID` : The variable ID, that is also the identifier in the NetCDF files
- `lname` : The variable long-name, which is used to specify retrievals from CDS
- `vname` : The full-name of the variable
- `units` : The units of the variable
- `hPa`   : The pressure-level height of the variable in concern
"""
abstract type PressureLevel <: ERA5Variable end

"""
    PressureVariable <: PressureLevel

Subtype for Pressure-Level variables that can be directly retrieved from the CDS
"""
struct PressureVariable{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    hPa   :: Int
end

"""
    PressureCustom <: PressureLevel

Subtype for custom user-defined Pressure-Level variables
"""
struct PressureCustom{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    hPa   :: Int
end

"""
    PressureVariable(
        varID :: AbstractString,
        ST = String;
        hPa   :: Int = 0
    ) -> evar :: SingleLevel

Retrieve the basic properties of the Pressure-Level variable defined by `varID` at pressure-height indicated by `hPa` and put them in the `evar` SingleLevel type structure.

Arguments
=========

- `varID` : variable ID (in string format)

Keyword Arguments
=================

- `hPa` : Integer specifying pressure-level height in hPa
"""
function PressureVariable(
    varID :: AbstractString,
    ST = String;
    hPa   :: Int = 0,
)

    isPressure(varID)

    @info "$(modulelog()) - Retrieving information for the PressureVariable defined by the ID \"$varID\""
    vlist,flist = listPressures();    ind = findall(varID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis",flist[ind])
    vlist = listera5variables(fname); ind = findall(varID.==vlist)[1]

    IDinfo = readdlm(fname,',',comments=true,comment_char='#')[ind,:]
    varID,lname,vname,units = IDinfo[[1,2,3,4]]

    if vtype == "pressurevariable"
        @info "$(modulelog()) - The ERA5Variable defined by \"$varID\" is of the PressureVariable type"
        return PressureVariable{ST}(varID,lname,vname,units,hPa)
    else
        @info "$(modulelog()) - The ERA5Variable defined by \"$varID\" is of the PressureCustom type"
        return PressureCustom{ST}(varID,lname,vname,units,hPa)
    end

end

"""
    PressureVariable(
        ST = String;
        varID :: AbstractString,
        lname :: AbstractString = "",
        vname :: AbstractString,
        units :: AbstractString,
        hPa   :: Int = 0,
    ) -> evar :: SingleLevel

Create a custom Single-Level variable that is not in the default list exported by ERA5Reanalysis.jl.  These variables are either available in the CDS store (whereby they can be both downloaded analyzed), or not (in which case means that they were separately calculated from other variables and analyzed).

Keyword Arguments
=================

- `varID` : variable ID (in string format)
- `lname` : long-name for variable (used in specifying variable for CDS downloads)
- `vname` : user-defined variable name
- `units` : user-defined units of the variable
- `hPa`   : Pressure level specified in hPa. Default is 0, which indicates all levels.
"""
function PressureVariable(
    ST = String;
    varID :: AbstractString,
    lname :: AbstractString = "",
    vname :: AbstractString,
    units :: AbstractString,
    hPa   :: Int = 0,
)

    if isPressure(varID,throw=false)
        error("$(modulelog()) - The PressureVariable \"$(varID)\" has already been defined, please use another identifier.")
    else
        @info "$(modulelog()) - Adding the PressureVariable \"$(varID)\" to the list."
    end

    open(joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis","pressurecustom.txt"),"a") do io
        write(io,"$varID,$lname,$vname,$units\n")
    end

    return PressureCustom{ST}(varID,lname,vname,units,hPa)

end

"""
    listPressures()

List all Pressure-Level Variables and the files the data are stored in.

Output
======

- `varlist` : List of all the Pressure-Level Variable IDs
- `fidlist` : List of the files that the Pressure-Level Variable information is stored in
"""
function listPressures()

    flist   = ["pressurevariable.txt","pressurecustom.txt"]
    varlist = []
    fidlist = []

    for fname in flist
        copyera5variables(fname)
        vvec = listera5variables(joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis",fname))
        varlist = vcat(varlist,vvec); fvec = fill(fname,length(vvec))
        fidlist = vcat(fidlist,fvec)
    end

    return varlist,fidlist

end

"""
    isPressure(
        varID :: AbstractString;
        throw :: Bool = true
    ) -> tf :: Bool

Extracts information of the Pressure-Level Variable with the ID `varID`.  If no Pressure-Level Variable with this ID exists, an error is thrown.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Pressure-Level Variable.
        If the ID is not valid (i.e. not being used), then an error will be thrown.
- `throw` : If `true`, then throws an error if `RegID` is not a valid Pressure-Level Variable identifier instead of returning the Boolean `tf`

Returns
=======

- `tf` : True / False
"""
function isPressure(
    varID :: AbstractString;
    throw :: Bool = true
)

    @info "$(modulelog()) - Checking to see if the PressureVariable ID \"$varID\" is in use"
    vlist,_ = listPressures()

    if sum(vlist.==varID) == 0
        if throw
            error("$(modulelog()) - \"$(varID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(varID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        @info "$(modulelog()) - The PressureVariable ID \"$varID\" is already in use"
        return true
    end

end

"""
    rmPressure( varID :: AbstractString ) -> nothing

Remove the Pressure-Level Variable with the ID `varID` from the lists.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Pressure-Level Variable that is to be removed
"""
function rmPressure(varID::AbstractString)

    if isPressure(varID,throw=false)
        rmERA5Variable(PressureVariable(varID))
    else
        @warn "$(modulelog()) - No Pressure-Level variable defined by \"$(varID)\" exists, please make sure you specified the correct variable ID"
    end

    return nothing

end

"""
    resetPressures() -> nothing

Reset the list of Pressure-Level variables to the ERA5Reanalysis default.
"""
function resetPressures()

    @info "$(modulelog()) - Resetting the custom list of ERA5 PressureVariables back to the default"
    flist = ["pressurecustom.txt"]

    for fname in flist
        copyera5variables(fname,overwrite=true)
    end

    return nothing

end

"""
    era5Pressures(
        varID :: AbstractString;
        throw :: Bool = true
    ) -> parray :: Vector{Int}

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