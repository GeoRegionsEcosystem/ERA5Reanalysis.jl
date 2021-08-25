abstract type SingleLevel <: ERA5Variable end

struct SingleVariable{ST<:AbstractString} <: SingleLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
end

struct SingleCustom{ST<:AbstractString} <: SingleLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
end

function SingleVariable(
    varID :: AbstractString,
    ST = String,
)

    isSingle(varID)

    @info "$(modulelog()) - Retrieving information for the SingleVariable defined by the ID \"$varID\""
    vlist,flist = listSingles();      ind = findall(varID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis",flist[ind])
    vlist = listera5variables(fname); ind = findall(varID.==vlist)[1]

    IDinfo = readdlm(fname,',',comments=true,comment_char='#')[ind,:]
    varID,lname,vname,units = IDinfo[[1,2,3,4]]

    if vtype == "singlevariable"
          return SingleVariable{ST}(varID,lname,vname,units)
    else; return SingleCustom{ST}(varID,lname,vname,units)
    end

end

"""
    listSingles()

List all Single-Level Variables and the files the data are stored in.

Output
======

- `varlist` : List of all the Single-Level Variable IDs
- `fidlist` : List of the files that the Single-Level Variable information is stored in
"""
function listSingles()

    flist   = ["singlevariable.txt","singlecustom.txt"]
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
    sSingle(
        varID :: AbstractString;
        throw :: Bool = true
    ) -> tf :: Bool

Extracts information of the Single-Level Variable with the ID `varID`.  If no Single-Level Variable with this ID exists, an error is thrown.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Single-Level Variable.
        If the ID is not valid (i.e. not being used), then an error will be thrown.
- `throw` : If `true`, then throws an error if `RegID` is not a valid Single-Level Variable identifier instead of returning the Boolean `tf`

Returns
=======

- `tf` : True / False
"""
function isSingle(
    varID :: AbstractString;
    throw :: Bool = true
)

    @info "$(modulelog()) - Checking to see if the SingleVariable ID \"$varID\" is in use"
    vlist,_ = listSingles()

    if sum(vlist.==varID) == 0
        if throw
            error("$(modulelog()) - \"$(varID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(varID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        @info "$(modulelog()) - The SingleVariable ID \"$varID\" is already in use"
        return true
    end

end