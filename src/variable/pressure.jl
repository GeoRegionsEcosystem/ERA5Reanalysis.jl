abstract type PressureLevel <: ERA5Variable end

struct PressureVariable{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    hPa   :: Int
end

struct PressureCustom{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    hPa   :: Int
end

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

function PressureVariable(
    ST = String;
    varID :: AbstractString,
    lname :: AbstractString = "",
    vname :: AbstractString,
    units :: AbstractString,
    hPa   :: Int = 0,
)

    isPressure(varID)

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