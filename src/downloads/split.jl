function split(
    e5ds :: ERA5Dataset,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    lsd  :: LandSea,
    dt   :: Date,
    pvec :: Vector{Int},
    fnc  :: AbstractString,
    tmpd :: Array{Int16,3},
    tmpf :: Array{Float32,3}
)

    ds = NCDataset(fnc)
    nt = ds.dim["time"]
    sc = ds[evar.varID].attrib["scale_factor"]
    of = ds[evar.varID].attrib["add_offset"]
    mv = ds[evar.varID].attrib["missing_value"]
    fv = ds[evar.varID].attrib["_FillValue"]
    dataint = @view tmpd[:,:,1:nt]
    dataflt = @view tmpf[:,:,1:nt]

    for ip in 1 : length(pvec)
        NCDatasets.load!(ds[evar.varID].var,dataint,:,:,ip,:)
        int2real!(dataflt,dataint,scale=sc,offset=of,mvalue=mv,fvalue=fv)

        p = pvec[ip]
        evarii = PressureVariable(evar.varID,hPa=p)
        save(dataflt,dt,e5ds,evarii,ereg,lsd)
    end

    close(ds)

end