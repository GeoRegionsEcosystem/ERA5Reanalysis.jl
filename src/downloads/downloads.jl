function download(
    emod :: ERA5Dataset,
    evar :: ERA5Variable,
    ereg :: ERA5Region,
    ispy :: Bool = false
)

    downloadcheckevar(evar)

    if ispy
          pythonprint(emod,evar,ereg)
    else; cdsretrieve(emod,evar,ereg)
    end

end

function downloadcheckevar(
    evar :: ERA5Variable
)

    if evar <: Union{SingleVariable,PressureVariable}

        @info "$(modulelog()) - The ERA5Variable ID \"$(evar)\" is a valid ERA5 Variable identifier and therefore can be used to download data from the Climate Data Store"

    else

        error("$(modulelog()) - The ERA5Variable ID \"$(evar)\" is a custom ERA5 Variable identifier and therefore cannot be used to download data from the Climate Data Store, and can only be calculated/analyzed from preexisting valid ERA5 data")

    end

end