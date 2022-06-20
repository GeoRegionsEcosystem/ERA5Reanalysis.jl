function download(
    e5ds :: ERA5Dataset,
    evar :: SingleVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false
)

    downloadcheckevar(evar)

    if ispy
          pythonprint(e5ds,evar,ereg)
    else; cdsretrieve(e5ds,evar,ereg)
    end

end

function download(
    e5ds :: ERA5Dataset,
    evar :: PressureVariable,
    ereg :: ERA5Region;
    ispy :: Bool = false,
    pall :: Bool = false,
    ptop :: Int = 0,
    pbot :: Int = 0
)

    downloadcheckevar(evar)

    if ispy
        pythonprint(e5ds,evar,ereg)
    else
        pvec = downloadcheckplvl(pall,ptop,pbot)
        if pall
            cdsretrieve(e5ds,evar,ereg,pvec)
        else
            cdsretrieve(e5ds,evar,ereg)
        end
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

function downloadcheckplvl(
    pall :: Bool,
    ptop :: Int,
    pbot :: Int
)

    if pall 

        @info "$(modulelog()) - Selected option to download pressure-level data as a whole batch instead of level-by-level"
        if iszero(ptop)
            @warn "$(modulelog()) - Top pressure-level not specified, setting to 1 hPa"
            ptop = 1
        end
        if iszero(pbot)
            @warn "$(modulelog()) - Bottom pressure-level not specified, setting to 1000 hPa"
            pbot = 1000
        end
        
        if ptop < 1; ptop = 1; elseif ptop > 1000; ptop = 1000 end
        if pbot < 1; pbot = 1; elseif pbot > 1000; pbot = 1000 end
        if ptop > pbot; error("$(modulelog()) - Bottom pressure-level is higher than top pressure-level") end

        pvec = era5Pressures()
        pvec = pvec[pvec.>=ptop]
        pvec = pvec[pvec.<=pbot]

    else
        @info "$(modulelog()) - Selected option to download pressure-level data level-by-level"
        pvec = []
    end

    return pvec

end