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
    ID      :: ST
    long    :: ST
    name    :: ST
    units   :: ST
    hPa     :: Int
    dataset :: ST
end

"""
    PressureCustom <: PressureLevel

Subtype for custom user-defined Pressure-Level variables which can only be calculated and not downloaded from the Climate Data Store.
"""
struct PressureCustom{ST<:AbstractString} <: PressureLevel
    ID      :: ST
    long    :: ST
    name    :: ST
    units   :: ST
    hPa     :: Int
    dataset :: ST
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
    hPa   :: Int = 0,
    throw :: Bool = true
)

    isPressure(ID)

    @info "$(modulelog()) - Retrieving information for the PressureVariable defined by the ID \"$ID\""
    vlist,flist = listPressures();    ind = findall(ID.==vlist)[1]
    vtype = replace(flist[ind],".txt"=>"")
    fname = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis",flist[ind])
    vlist = listera5variables(fname); ind = findall(ID.==vlist)[1]

    IDinfo = readdlm(fname,',',comments=true,comment_char='#')[ind,:]
    ID,long,name,units = IDinfo[[1,2,3,4]]

    prelist = era5Pressures()
    if iszero(sum(prelist.==hPa)) && !iszero(hPa)
        if throw
            error("$(modulelog()) - Pressure level specified in \"hPa\" argument is invalid, please check and see if you requested correctly")
        else
            @warn "$(modulelog()) - Pressure level specified in \"hPa\" argument does not exist, snapping to nearest pressure level"
            ipre = argmin(abs.(prelist.-hPa))
            hPa  = prelist[ipre]
        end
    end

    if vtype == "pressurevariable"
        @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the PressureVariable type"
        return PressureVariable{ST}(
            ID,long,name * " ($(hPa) hPa)",units,hPa,
            "reanalysis-era5-pressure-levels"
        )
    else
        @info "$(modulelog()) - The ERA5Variable defined by \"$ID\" is of the PressureCustom type"
        return PressureCustom{ST}(
            ID,long,name * " ($(hPa) hPa)",units,hPa,
            "reanalysis-era5-pressure-levels"
        )
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
    throw :: Bool = true
)

    if isPressure(ID,throw=false)
        error("$(modulelog()) - The PressureVariable \"$(ID)\" has already been defined, please use another identifier.")
    else
        @info "$(modulelog()) - Adding the PressureVariable \"$(ID)\" to the list."
    end

    open(joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis","pressurecustom.txt"),"a") do io
        write(io,"$ID,$long,$name,$units\n")
    end

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

    return PressureCustom{ST}(ID,long,name,units,hPa,"reanalysis-era5-pressure-levels")

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
function isPressure(
    ID :: AbstractString;
    throw :: Bool = true,
    dolog :: Bool = false
)

    if dolog
        @info "$(modulelog()) - Checking if the PressureVariable ID \"$ID\" is in use"
    else
        @debug "$(modulelog()) - Checking if the PressureVariable ID \"$ID\" is in use"
    end

    vlist,_ = listPressures()

    if sum(vlist.==ID) == 0
        if throw
            error("$(modulelog()) - \"$(ID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list.")
        else
            @warn "$(modulelog()) - \"$(ID)\" is not a valid PressureVariable identifier, use the function PressureCustom() to add this ERA5Variable to the list."
            return false
        end
    else
        if dolog
            @info "$(modulelog()) - The PressureVariable ID \"$ID\" is already in use"
        end
        return true
    end

end

"""
    rmPressure( ID :: AbstractString ) -> nothing

Remove the Pressure-Level Variable with the ID `ID` from the lists.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Pressure-Level Variable that is to be removed
"""
function rmPressure(ID::AbstractString)

    if isPressure(ID,throw=false)
        disable_logging(Logging.Warn)
        rmERA5Variable(PressureVariable(ID))
        disable_logging(Logging.Debug)
        @info "$(modulelog()) - Successfully removed the Pressure-Level variable defined by \"$(ID)\""
    else
        @warn "$(modulelog()) - No Pressure-Level variable defined by \"$(ID)\" exists, please make sure you specified the correct variable ID"
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

function tablePressures(;custom::Bool=false)

    jfol = joinpath(DEPOT_PATH[1],"files","ERA5Reanalysis"); mkpath(jfol);
    if custom
        fvar = ["PressureCustom"]
    else
        fvar = ["PressureVariable","PressureCustom"]
    end
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

    if isempty(fmat)
        fmat  = Array{String,2}(undef,1,5)
        fmat .= "N/A"
    end

    pretty_table(
        fmat,header=head,
        alignment=[:c,:c,:l,:c,:l],
        crop = :none, tf = tf_compact
    );

end