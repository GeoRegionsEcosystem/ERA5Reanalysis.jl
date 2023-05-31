function split(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    dt   :: Date,
    pvec :: Vector{Int},
    fnc  :: AbstractString,
    tmpd :: Array{Int16,3}
)

    ds = NCDataset(fnc)
    nt = ds.dim["time"]
    sc = ds[evar.varID].attrib["scale_factor"]
    of = ds[evar.varID].attrib["add_offset"]
    mv = ds[evar.varID].attrib["missing_value"]
    fv = ds[evar.varID].attrib["_FillValue"]
    dataint = @view tmpd[:,:,1:nt]

    for ip in 1 : length(pvec)
        NCDatasets.load!(ds[evar.varID].var,dataint,:,:,ip,:)

        if mv != -32767
            for ii in eachindex(dataint)
                dataii = dataint[ii]
                if dataii == mv
                    dataint[ii] = -32767
                end
            end
        end

        if fv != -32767
            for ii in eachindex(dataint)
                dataii = dataint[ii]
                if dataii == fv
                    dataint[ii] = -32767
                end
            end
        end

        p = pvec[ip]
        evarii = PressureVariable(evar.varID,hPa=p)
        save(dataint,dt,e5ds,evarii,ereg,lsd,sc,of)
    end

    close(ds)

    rm(fnc,force=true)

end

function split(
    e5ds :: ERA5CDStore,
    evar :: Vector{SingleVariable{ST}},
    ereg :: ERA5Region,
    lsd  :: LandSea,
    dt   :: Date,
    fnc  :: AbstractString,
    tmpd :: Array{Int16,3}
) where ST <: AbstractString

    ds = NCDataset(fnc)
    nt = ds.dim["time"]
    dataint = @view tmpd[:,:,1:nt]
    for evarii in evar
        sc = ds[evarii.varID].attrib["scale_factor"]
        of = ds[evarii.varID].attrib["add_offset"]
        mv = ds[evarii.varID].attrib["missing_value"]
        fv = ds[evarii.varID].attrib["_FillValue"]

        NCDatasets.load!(ds[evarii.varID].var,dataint,:,:,:)

        if mv != -32767
            for ii in eachindex(dataint)
                dataii = dataint[ii]
                if dataii == mv
                    dataint[ii] = -32767
                end
            end
        end

        if fv != -32767
            for ii in eachindex(dataint)
                dataii = dataint[ii]
                if dataii == fv
                    dataint[ii] = -32767
                end
            end
        end

        save(dataint,dt,e5ds,evarii,ereg,lsd,sc,of)

    end

    close(ds)

    rm(fnc,force=true)

end