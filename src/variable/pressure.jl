abstract type PressureLevel <: ERA5Variable end

struct PressureVariable{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    plvl  :: Int
end

struct PressureCustom{ST<:AbstractString} <: PressureLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    plvl  :: Int
end

function PressureVariable(
    varID :: AbstractString,
    plvl  :: Int = 0,
    ST = String,
)

    vlist,flist = listPressureVariables(); ind = findall(varID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = flist[ind]
    vlist = listera5variables(fname);      ind = findall(varID.==vlist)[1]

    IDinfo = readdlm(fname,',',comments=true,comment_char='#')[ind,:]
    varID,lname,vname,units = IDinfo[[1,2,3,4]]

    if vtype == "singlevariable"
          return PressureVariable{ST}(varID,lname,vname,units,plvl)
    else; return PressureCustom{ST}(varID,lname,vname,units,plvl)
    end

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

    for fname in fidlist
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
    throw :: Bool=true
)

    vlist,_ = listPressureVariables()
    return isera5variable(varID,vlist;throw=throw)

end