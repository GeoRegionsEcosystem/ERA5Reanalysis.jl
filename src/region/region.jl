"""
    ERA5LonLat

This is a wrapper for the [GeoRegion](https://github.com/GeoRegionsEcosystem/GeoRegions.jl) Type used in the handling of the Longitude/Latitude Gridded ERA5 datasets.
"""
struct ERA5LonLat{ST<:AbstractString, FT<:Real} <: ERA5Region
    geo :: GeoRegion
     ID :: ST
      N :: FT
      S :: FT
      E :: FT
      W :: FT
    resolution :: FT
    string     :: ST
    isglb :: Bool
    is360 :: Bool
end

"""
    ERA5Native

This is a wrapper for the [GeoRegion](https://github.com/GeoRegionsEcosystem/GeoRegions.jl) Type used in the handling of the Native Spectral Gridded ERA5 datasets.
"""
struct ERA5Native{ST<:AbstractString, FT<:Real} <: ERA5Region
    geo :: GeoRegion
     ID :: ST
      N :: FT
      S :: FT
      E :: FT
      W :: FT
    resolution :: FT
    string     :: ST
    isglb :: Bool
    is360 :: Bool
end

"""
    ERA5Region(
        geo :: GeoRegion;
        resolution :: Real = 0,
        ST = String,
        FT = Float64
    ) -> ereg :: ERA5Region

Argument
========

- `geo`  : A `GeoRegion` structure type

Keyword Argument
================

- `resolution` : The spatial resolution that ERA5 reanalysis data will be downloaded/analyzed, and 360 must be a multiple of `resolution`
"""
function ERA5Region(
    geo :: GeoRegion;
    resolution :: Real = 0,
    native :: Bool = false,
    ST = String,
    FT = Float64
)

    @info "$(modulelog()) - Creating an ERA5Region based on the GeoRegion \"$(geo.ID)\""
    resolution = regionstep(geo.ID,resolution)
    if geo.ID == "GLB"; isglb = true; else; isglb = false end
    if mod(geo.E,360) == mod(geo.W,360); is360 = true; else; is360 = false end

    if is360
        W = geo.W
        E = geo.E
    else
        W =  ceil(geo.W / resolution) * resolution
        E = floor(geo.E / resolution) * resolution
    end
    if (E - W ) > 360; E = 360; W = 0; end
    S =  ceil(geo.S / resolution) * resolution
    N = floor(geo.N / resolution) * resolution

    if !native
        return ERA5LonLat{ST,FT}(
            geo, geo.ID, N, S, E, W, resolution,
            "$(geo.ID)x$(@sprintf("%.2f",resolution))", isglb, is360, native
        )
    else
        return ERA5Native{ST,FT}(
            geo, geo.ID, N, S, E, W, 0,
            "$(geo.ID)xT639", isglb, is360, native
        )
    end

end

"""
    ERA5Region(
        ID :: AbstractString;
        resolution :: Real = 0,
        ST = String,
        FT = Float64
    ) -> ereg :: ERA5Region

Argument
========

- `ID` : The ID used to specify the `GeoRegion`

Keyword Argument
================

- `resolution` : The spatial resolution that ERA5 reanalysis data will be downloaded/analyzed, and 360 must be a multiple of `resolution`
"""
function ERA5Region(
    ID :: AbstractString;
    path :: AbstractString = homedir(),
    resolution :: Real = 0,
    native :: Bool = false,
    ST = String,
    FT = Float64
)

    @info "$(modulelog()) - Creating an ERA5Region based on the GeoRegion \"$(ID)\""
    resolution = regionstep(ID,resolution)
    if ID == "GLB"; isglb = true; else; isglb = false end

    return ERA5Region(
        GeoRegion(ID,path=path),resolution=resolution,native=native,
        ST=ST,FT=FT
    )

end

function regionstep(
    ID :: AbstractString,
    resolution  :: Real = 0
)

    @debug "$(modulelog()) - Determining spacing between grid points in the GeoRegion ..."
    if resolution == 0
        @info "$(modulelog()) - No grid resolution specified, defaulting to the module default (1.0º for global GeoRegion, 0.25º for all others)"
        if ID == "GLB";
              resolution = 1.0;
        else; resolution = 0.25;
        end
    else
        if !checkegrid(resolution)
            error("$(modulelog()) - The grid resolution $(resolution)º is not valid as it does not divide 360º without remainder")
        end
    end

    return resolution

end

function checkegrid(resolution::Real)

    if rem(360,resolution) == 0
          return true
    else; return false
    end

end

function show(io::IO, ereg::ERA5LonLat)
    geo = ereg.geo
    shape = geo.geometry.shape

    print(
        io,
        "The ERA5Region wrapper on the Longitude/Latitude Grid for the \"$(ereg.ID)\" GeoRegion has the following properties:\n",
        "    Region ID             (ID) : ", ereg.ID, '\n',
        "    Name            (geo.name) : ", geo.name,  '\n',
        "    Resolution    (resolution) : ", ereg.resolution,  '\n',
        "    Folder ID         (string) : ", ereg.string, '\n',
        "    Bounds     (geo.[N,S,E,W]) : ", geo.N, ", ", geo.S, ", ", geo.E, ", ", geo.W, '\n',
		"    Rotation           (geo.θ) : ", geo.θ, 	'\n',
		"    File Path       (geo.path) : ", geo.path, '\n',
        "    Shape (geo.geometry.shape) : ", typeof(shape), "($(length(shape)))", '\n',
    )

end

function show(io::IO, ereg::ERA5Native)
    geo = ereg.geo
    shape = geo.geometry.shape

    print(
        io,
        "The ERA5Region wrapper on the Native Spectral Grid for the \"$(ereg.ID)\" GeoRegion has the following properties:\n",
        "    Region ID             (ID) : ", ereg.ID, '\n',
        "    Name            (geo.name) : ", geo.name,  '\n',
        "    Folder ID         (string) : ", ereg.string, '\n',
        "    Bounds     (geo.[N,S,E,W]) : ", geo.N, ", ", geo.S, ", ", geo.E, ", ", geo.W, '\n',
		"    Rotation           (geo.θ) : ", geo.θ, 	'\n',
		"    File Path       (geo.path) : ", geo.path, '\n',
        "    Shape (geo.geometry.shape) : ", typeof(shape), "($(length(shape)))", '\n',
    )

end