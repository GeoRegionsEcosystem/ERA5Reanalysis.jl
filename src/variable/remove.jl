"""
    rmSingle( ID :: AbstractString ) -> nothing

Remove the Single-Level Variable with the ID `ID` from the lists.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Single-Level Variable that is to be removed
"""
function rmSingleID(
    ID :: AbstractString;
    throw :: Bool = false
)

    if isSingle(ID,throw=false)
        rm(SingleVariable(ID))
        @info "$(modulelog()) - Successfully removed the Single-Level variable defined by \"$(ID)\""
    else
        if throw
            error("$(modulelog()) - No Single-Level variable defined by \"$(ID)\" exists, please make sure you specified the correct variable ID")
        else
            @warn "$(modulelog()) - No Single-Level variable defined by \"$(ID)\" exists, please make sure you specified the correct variable ID"
        end
    end

    return nothing

end

"""
    rmPressure( ID :: AbstractString ) -> nothing

Remove the Pressure-Level Variable with the ID `ID` from the lists.

Arguments
=========

- `RegID` : The keyword ID that will be used to identify the Pressure-Level Variable that is to be removed
"""
function rmPressureID(ID::AbstractString)

    if isPressure(ID,throw=false)
        rm(PressureVariable(ID))
        @info "$(modulelog()) - Successfully removed the Pressure-Level variable defined by \"$(ID)\""
    else
        if throw
            error("$(modulelog()) - No Pressure-Level variable defined by \"$(ID)\" exists, please make sure you specified the correct variable ID")
        else
            @warn "$(modulelog()) - No Pressure-Level variable defined by \"$(ID)\" exists, please make sure you specified the correct variable ID"
        end
    end

    return nothing

end

function rm(
    :: Union{SingleVariable,PressureVariable};
    path :: AbstractString = pwd()
)

    error("$(modulelog()) - Variables of the types SingleVariable and PressureVariable cannot be removed")

    return nothing

end

function rm(
    evar :: SingleCustom;
    path :: AbstractString = pwd()
)

    flines = readlines(joinpath(path,"singlecustom.txt"))
    nlines = length(flines)

    open("tmp.txt","w") do io
        for iline = 1 : nlines
            if !occursin("$(evar.ID),",flines[iline])
                write(io,"$(flines[iline])\n")
            end
        end
    end

    mv("tmp.txt",fid,force=true)

    return nothing

end

function rm(
    evar :: PressureCustom;
    path :: AbstractString = pwd()
)

    flines = readlines(joinpath(path,"pressurecustom.txt"))
    nlines = length(flines)

    open("tmp.txt","w") do io
        for iline = 1 : nlines
            if !occursin("$(evar.ID),",flines[iline])
                write(io,"$(flines[iline])\n")
            end
        end
    end

    mv("tmp.txt",fid,force=true)

    return nothing

end