"""
    SingleLevel <: ERA5Variable

Abstract supertype for Single-Level variables.  Contains the following fields:
- `varID` : The variable ID, that is also the identifier in the NetCDF files
- `lname` : The variable long-name, which is used to specify retrievals from CDS
- `vname` : The full-name of the variable
- `units` : The units of the variable
- `dname` : The name of the ERA5 dataset containing the variable
"""
abstract type SingleLevel <: ERA5Variable end

"""
    SingleVariable <: SingleLevel

Subtype for Single-Level variables that can be directly retrieved from the CDS
"""
struct SingleVariable{ST<:AbstractString} <: SingleLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    dname :: ST
end


"""
    SingleCustom <: SingleLevel

Subtype for custom user-defined Single-Level variables
"""
struct SingleCustom{ST<:AbstractString} <: SingleLevel
    varID :: ST
    lname :: ST
    vname :: ST
    units :: ST
    dname :: ST
end

"""
    SingleVariable(
        varID :: AbstractString,
        ST = String,
    ) -> evar :: SingleLevel

Retrieve the basic properties of the Single-Level variable defined by `varID` and put them in the `evar` SingleLevel type structure.

Arguments
=========

- `varID` : variable ID (in string format) used in the NetCDF file
"""
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
          return SingleVariable{ST}(varID,lname,vname,units,"reanalysis-era5-single-levels")
    else; return SingleCustom{ST}(varID,lname,vname,units,"reanalysis-era5-single-levels")
    end

end

"""
    SingleVariable(
        ST = String;
        varID :: AbstractString,
        lname :: AbstractString = "",
        vname :: AbstractString,
        units :: AbstractString,
        inCDS :: Bool = true
    ) -> evar :: SingleLevel

Create a custom Single-Level variable that is not in the default list exported by ERA5Reanalysis.jl.  These variables are either available in the CDS store (whereby they can be both downloaded analyzed), or not (in which case means that they were separately calculated from other variables and analyzed).

Keyword Arguments
=================

- `varID` : variable ID (in string format) used in the NetCDF file
- `lname` : long-name for variable (used in specifying variable for CDS downloads)
- `vname` : user-defined variable name
- `units` : user-defined units of the variable
- `inCDS` : Boolean that indicates if this variable is available on the CDS store.  True if available.
"""
function SingleVariable(
    ST = String;
    varID :: AbstractString,
    lname :: AbstractString = "",
    vname :: AbstractString,
    units :: AbstractString,
    inCDS :: Bool = true
)

    if isSingle(varID,throw=false)
        error("$(modulelog()) - The SingleVariable \"$(varID)\" has already been defined,please use another identifier.")
    else
        @info "$(modulelog()) - Adding the SingleVariable \"$(varID)\" to the list."
    end

    if inCDS

        open(joinpath(
            DEPOT_PATH[1],"files","ERA5Reanalysis","singlevariable.txt"
        ),"a") do io
            write(io,"$varID,$lname,$vname,$units\n")
        end
        return SingleVariable{ST}(varID,lname,vname,units,"reanalysis-era5-single-levels")

    else

        open(joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis","singlecustom.txt"),"a") do io
            write(io,"$varID,$lname,$vname,$units\n")
        end
        return SingleCustom{ST}(varID,lname,vname,units,"reanalysis-era5-single-levels")

    end

end

"""
    listSingles() -> varlist :: Array{ST}, fidlist :: Array{ST}

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
    isSingle(
        varID :: AbstractString;
        throw :: Bool = true,
        dolog :: Bool = false
    ) -> tf :: Bool

Extracts information of the Single-Level Variable with the ID `varID`.  If no Single-Level Variable with this ID exists, an error is thrown.

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
function isSingle(
    varID :: AbstractString;
    throw :: Bool = true,
    dolog :: Bool = false
)

    if dolog
        @info "$(modulelog()) - Checking if the SingleVariable ID \"$varID\" is in use"
    else
        @debug "$(modulelog()) - Checking if the SingleVariable ID \"$varID\" is in use"
    end

    vlist,_ = listSingles()

    if sum(vlist.==varID) == 0
        if throw
            error("$(modulelog()) - \"$(varID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(varID)\" is not a valid SingleVariable identifier, use the function SingleVariable() or SingleCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        if dolog
            @info "$(modulelog()) - The SingleVariable ID \"$varID\" is already in use"
        end
        return true
    end

end

"""
    rmSingle( varID :: AbstractString ) -> nothing

Remove the Single-Level Variable with the ID `varID` from the lists.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Single-Level Variable that is to be removed
"""
function rmSingle(varID::AbstractString)

    if isSingle(varID,throw=false)
        disable_logging(Logging.Warn)
        rmERA5Variable(SingleVariable(varID))
        disable_logging(Logging.Debug)
        @info "$(modulelog()) - Successfully removed the Single-Level variable defined by \"$(varID)\""
    else
        @warn "$(modulelog()) - No Single-Level variable defined by \"$(varID)\" exists, please make sure you specified the correct variable ID"
    end

    return nothing

end

"""
    resetSingles( allfiles :: Bool ) -> nothing

Reset the list of Single-Level variables.

Arguments
=========

- `allfiles` : If false, only get rid of all the SingleCustom variables, but if true, then the SingleVariable list will be reset back to the default for ERA5Reanalysis.jl
"""
function resetSingles(;allfiles=false)

    if allfiles
        @info "$(modulelog()) - Resetting both the master and custom lists of ERA5 SingleVariables back to the default"
        flist = ["singlevariable.txt","singlecustom.txt"]
    else
        @info "$(modulelog()) - Resetting the custom lists of ERA5 variables back to the default"
        flist = ["singlecustom.txt"]
    end

    for fname in flist
        copyera5variables(fname,overwrite=true)
    end

    return nothing

end

function tableSingles()

    jfol = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis"); mkpath(jfol);
    fvar = ["SingleVariable","SingleCustom"]
    fmat = []
    
    for fname in fvar
        fid  = joinpath(jfol,"$(lowercase(fname)).txt")
        try
            vmat = readdlm(fid,',',comments=true,comment_char='#')
            nvar = size(vmat,1); ff = fill(fname,nvar)
            vmat = cat(ff,vmat[:,[1,3,4,2]],dims=2)
            fmat = cat(fmat,vmat,dims=1)
        catch
        end
    end

    head = ["Variable Type","ID","Name","Units","ERA5 Long-Name"];

    pretty_table(
        fmat,head,
        alignment=[:c,:c,:l,:c,:l],
        crop = :none, tf = tf_compact
    );

end