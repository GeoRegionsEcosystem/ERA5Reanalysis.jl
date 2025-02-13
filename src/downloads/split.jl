function split(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    lsd  :: LandSeaTopo,
    dt   :: Date,
    pvec :: Vector{Int},
    fnc  :: AbstractString,
    tmpd :: Array{Float32,3}
)

    ds = NCDataset(fnc)
    nt = ds.dim["valid_time"]
    dataint = @view tmpd[:,:,1:nt]

    for ip in 1 : length(pvec)
        NCDatasets.load!(ds[evar.ID].var,dataint,:,:,ip,:)
        evarii = PressureVariable(evar.ID,hPa=pvec[ip])
        save(dataint,dt,e5ds,evarii,ereg,lsd)
    end

    close(ds)

    rm(fnc,force=true)

end

function split(
    e5ds :: ERA5CDStore,
    evar :: Vector{SingleVariable{ST}},
    ereg :: ERA5Region,
    lsd  :: LandSeaTopo,
    dt   :: Date,
    fnc  :: AbstractString,
    tmpd :: Array{Float32,3}
) where ST <: AbstractString

    ds = NCDataset(fnc)
    nt = ds.dim["valid_time"]
    data = @view tmpd[:,:,1:nt]

    for evarii in evar
        NCDatasets.load!(ds[evarii.ID].var,data,:,:,:)
        save(data,dt,e5ds,evarii,ereg,lsd)
    end

    close(ds)

    rm(fnc,force=true)

end