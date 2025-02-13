==(evar1 :: ERA5Variable, evar2 :: ERA5Variable) = isequal(evar1,evar2)
!==(evar1 :: ERA5Variable, evar2 :: ERA5Variable) = !isequal(evar1,evar2)

function isequal(
    evar1 :: ERA5Variable,
    evar2 :: ERA5Variable
)

    if typeof(evar1) !== typeof(evar2)
        return false
    elseif (evar1.ID !== evar2.ID) || (evar1.name !== evar2.name)
        return false
    elseif strict && (evar1.units !== evar2.units)
        return false
    elseif !strict && (dimension(evar1.units) !== dimension(evar2.units))
        return false
    else
        return true
    end
end

"""
    isSingle(
        ID :: AbstractString;
        throw :: Bool = true,
        dolog :: Bool = false
    ) -> tf :: Bool

Extracts information of the Single-Level Variable with the ID `ID`.  If no Single-Level Variable with this ID exists, an error is thrown.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Single-Level Variable.
        If the ID is not valid (i.e. not being used), then an error will be thrown.
- `throw` : If `true`, then throws an error if `RegID` is not a valid Single-Level Variable identifier instead of returning the Boolean `tf`
- `dolog` : If `true`, then return logging to screen along with results

Returns
=======

- `tf` : True / False
"""
function isSingleID(
    ID   :: AbstractString;
    path :: AbstractString = homedir(),
    throw   :: Bool = true,
    verbose :: Bool = false
)

    if verbose; @info "$(modulelog()) - Checking if the SingleVariable ID \"$ID\" is in use" end

    vlist,_ = listSingles(path)

    if sum(vlist.==ID) == 0
        if throw
            error("$(modulelog()) - \"$(ID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(ID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        if verbose; @info "$(modulelog()) - The SingleVariable ID \"$ID\" is already in use" end
        return true
    end

end



"""
    isPressure(
        ID :: AbstractString;
        throw :: Bool = true,
        dolog :: Bool = false
    ) -> tf :: Bool

Extracts information of the Pressure-Level Variable with the ID `ID`.  If no Pressure-Level Variable with this ID exists, an error is thrown.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Pressure-Level Variable.
        If the ID is not valid (i.e. not being used), then an error will be thrown.
- `throw` : If `true`, then throws an error if `RegID` is not a valid Pressure-Level Variable identifier instead of returning the Boolean `tf`
- `dolog` : If `true`, then return logging to screen along with results

Returns
=======

- `tf` : True / False
"""
function isPressureID(
    ID   :: AbstractString;
    path :: AbstractString = homedir(),
    throw   :: Bool = true,
    verbose :: Bool = false
)

    if verbose
        @info "$(modulelog()) - Checking if the PressureVariable ID \"$ID\" is in use"
    end

    vlist,_,_ = listPressures(path)

    if sum(vlist.==ID) == 0
        if throw
            error("$(modulelog()) - \"$(ID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(ID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        if verbose; @info "$(modulelog()) - The PressureVariable ID \"$ID\" is already in use" end
        return true
    end

end