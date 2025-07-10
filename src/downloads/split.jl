function split(
    e5ds :: ERA5CDStore,
    evar :: PressureVariable,
    ereg :: ERA5Region,
    elsd :: LandSeaTopo,
    ggrd :: RegionGrid,
    dt   :: Date,
    pvec :: Vector{Int},
    fnc  :: AbstractString,
    tmpd :: Array{Float32,3}
)

    ds = NCDataset(fnc)
    nt = ds.dim["valid_time"]
    data = @view tmpd[:,:,1:nt]

    for ip in 1 : length(pvec)
        NCDatasets.load!(ds[evar.ID].var,data,:,:,ip,:)
        evarii = PressureVariable(evar.ID,hPa=pvec[ip])
        save(data,dt,e5ds,evarii,ereg,elsd)
        extractsplit!(data,e5ds,evarii,ereg,elsd,ggrd,dt)
    end

    close(ds)

    rm(fnc,force=true)

end

function split(
    e5ds :: ERA5CDStore,
    evar :: Vector{SingleVariable{ST}},
    ereg :: ERA5Region,
    elsd :: LandSeaTopo,
    ggrd :: RegionGrid,
    dt   :: Date,
    fnc  :: AbstractString,
    tmpd :: Array{Float32,3}
) where ST <: AbstractString

    ds = NCDataset(fnc)
    nt = ds.dim["valid_time"]
    data = @view tmpd[:,:,1:nt]

    for evarii in evar
        NCDatasets.load!(ds[evarii.ID].var,data,:,:,:)
        save(data,dt,e5ds,evarii,ereg,elsd)
        extractsplit!(data,e5ds,evarii,ereg,elsd,ggrd,dt)
    end

    close(ds)

    rm(fnc,force=true)

end