function download(
    e5ds :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region;
    ispy :: Bool = false
)

    downloadcheckevar(evar)

    if ispy
          pythonprint(e5ds,evar,ereg)
    else; cdsretrieve(e5ds,evar,ereg)
    end

end

function downloadcheckevar(
    evar :: ERA5Variable
)

    if typeof(evar) <: Union{SingleVariable,PressureVariable}

        @info "$(modulelog()) - The ERA5Variable ID \"$(evar.varID)\" is a valid ERA5 Variable identifier and therefore can be used to download data from the Climate Data Store"

    else

        error("$(modulelog()) - The ERA5Variable ID \"$(evar.varID)\" is a custom ERA5 Variable identifier and therefore cannot be used to download data from the Climate Data Store, and can only be calculated/analyzed from preexisting valid ERA5 data")

    end

end