"""
ERA5RegionGrid

Structure that imports relevant GeoRegion and RegionGrid properties used in the handling of the ERA5 dataset.
"""
struct ERA5Region{ST<:AbstractString, FT<:Real}
    geoID :: ST
    name  :: ST
    gres  :: FT
    grid  :: Vector{FT}
    shape :: Vector{Point2{FT}}
    fstr  :: ST
    isglb :: Bool
end

function ERA5Region(
    geoID :: AbstractString,
    gres  :: Real = 0,
    ST = String,
    FT = Float64
)

    geo = GeoRegion(geoID)
    if iszero(gres); gres = regionstep(geoID,gres) end
    if geoID == "GLB"; isglb = true; else; isglb = false end

    if typeof(geo) <: PolyRegion
        shape = geo.shape
    else
        shape = Point2.(
            [geo.E,geo.E,geo.W,geo.W,geo.E],
            [geo.N,geo.S,geo.S,geo.N,geo.N]
        )
    end

    return ERA5Region{ST,FT}(
        geo.regID, geo.name, gres, [geo.N, geo.S, geo.E, geo.W], shape,
        "$(geo.regID)x$(@sprintf("%.2f",gres))", isglb
    )

end

function regionstep(
    geoID :: AbstractString,
    gres  :: Real = 0
)

    @debug "$(modulelog()) - Determining spacing between grid points in the GeoRegion ..."
    if gres == 0
        @info "$(modulelog()) - No grid resolution specified, defaulting to the module default (1.0º for global GeoRegion, 0.25º for all others)"
        if geoID == "GLB";
              gres = 1.0;
        else; gres = 0.25;
        end
    else
        if !checkegrid(gres)
            error("$(modulelog()) - The grid resolution $(gres)º is not valid as it does not divide 360º without remainder")
        end
    end

    return gres

end

function checkegrid(gres::Real)

    if rem(360,gres) == 0
          return true
    else; return false
    end

end

function show(io::IO, geo::ERA5Region)
    print(
		io,
		"The ERA5Region for the $(geo.geoID) GeoRegion has the following properties:\n",
		"    Region ID (regID) : ", geo.geoID, '\n',
		"    Name       (name) : ", geo.name,  '\n',
		"    Resolution (gres) : ", geo.gres,  '\n',
		"    Bounds  (N,S,E,W) : ", geo.grid,  '\n',
		"    Shape     (shape) : ", geo.shape, '\n'
	)
end