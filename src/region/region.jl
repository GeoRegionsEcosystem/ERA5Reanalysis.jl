"""
ERA5RegionGrid

Structure that imports relevant GeoRegion and RegionGrid properties used in the handling of the ERA5 dataset.
"""
struct ERA5RegionGrid{ST<:AbstractString, FT<:Real}
    geoID :: ST
    name  :: ST
    isglb :: Bool
    grid  :: Vector{FT}
    gres  :: FT
    lon   :: Vector{FT}
    lat   :: Vector{FT}
    size  :: Vector{Int}
    fstr  :: ST
end

function ERA5RegionGrid(geoID::AbstractString)

    geo  = GeoRegion(geoID)
    gres = regionstep(geoID)
    lon  = convert(Array,geo.W:step:geo.E);
    lat  = convert(Array,geo.N:-step:geo.S);

    if (mod(E,360) == mod(W,360)) && (E!=W); pop!(lon); end
    nlon = size(lon,1)
    nlat = size(lat,1)

    if geoID == "GLB"; isglb = true; else; isglb = false end

    return ERA5RegionGrid{ST,FT}(
        geo.regID, geo.name, isglb, [geo.N, geo.S, geo.E, geo.W], gres,
        lon, lat, [nlon, nlat],
        "$(geo.regID)x$(@sprintf("%.2f",ereg["step"]))"
    )

end

function regionstep(geoID::AbstractString,step::Real=0)

    @debug "$(now()) - Determining spacing between grid points in the GeoRegion ..."
    if step == 0
        if geoID == "GLB";
              step = 1.0;
        else; step = 0.25;
        end
    else
        if !checkegrid(step)
            error("$(now()) - The grid resolution specified is not valid.")
        end
    end

    return step

end