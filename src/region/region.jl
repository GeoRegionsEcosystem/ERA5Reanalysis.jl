"""
    ERA5Region

Structure that imports relevant [GeoRegion](https://github.com/JuliaClimate/GeoRegions.jl) properties used in the handling of the gridded ERA5 datasets.

The `ERA5Region` Type contain the following fields:
- `geo` : The `GeoRegion` containing the geographical information
- `ID` : The ID used to specify the `GeoRegion`
- `resolution` : The resolution of the gridded data to be downloaded/analysed
- `string` : Specification of folder and file name, mostly for backend usage
- `isglb` : A Bool, true if spans the globe, false if no
- `is360` : True if it spans 360º longitude
"""
struct ERA5Region{ST<:AbstractString, FT<:Real}
    geo        :: GeoRegion
    ID         :: ST
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
    ST = String,
    FT = Float64
)

    @info "$(modulelog()) - Creating an ERA5Region based on the GeoRegion \"$(geo.ID)\""
    resolution = regionstep(geo.ID,resolution)
    if geo.ID == "GLB"; isglb = true; else; isglb = false end
    if mod(geo.bound[3],360) == mod(geo.bound[4],360); is360 = true; else; is360 = false end

    return ERA5Region{ST,FT}(
        geo, geo.ID, resolution,
        "$(geo.ID)x$(@sprintf("%.2f",resolution))", isglb, is360
    )

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
    ST = String,
    FT = Float64
)

    @info "$(modulelog()) - Creating an ERA5Region based on the GeoRegion \"$(ID)\""
    resolution = regionstep(ID,resolution)
    if ID == "GLB"; isglb = true; else; isglb = false end

    return ERA5Region(GeoRegion(ID,path=path),resolution=resolution,ST=ST,FT=FT)

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

function show(io::IO, ereg::ERA5Region)
    geo = ereg.geo

    if typeof(geo) <: PolyRegion
        print(
            io,
            "The ERA5Region wrapper for the \"$(ereg.ID)\" GeoRegion has the following properties:\n",
            "    Region ID          (ID) : ", ereg.ID, '\n',
            "    Name         (geo.name) : ", ereg.geo.name,  '\n',
            "    Resolution (resolution) : ", ereg.resolution,  '\n',
            "    Folder ID      (string) : ", ereg.string, '\n',
            "    Bounds  (geo.[N,S,E,W]) : ", geo.bound, '\n',
            "    Shape       (geo.shape) : ", geo.shape, '\n',
            "        (geo.[isglb,is360]) : ",(ereg.isglb,ereg.is360),"\n",
        )
    else
        print(
            io,
            "The ERA5Region wrapper for the \"$(ereg.ID)\" GeoRegion has the following properties:\n",
            "    Region ID          (ID) : ", ereg.ID, '\n',
            "    Name         (geo.name) : ", ereg.geo.name,  '\n',
            "    Resolution (resolution) : ", ereg.resolution,  '\n',
            "    Folder ID      (string) : ", ereg.string, '\n',
            "    Bounds  (geo.[N,S,E,W]) : ", geo.bound, '\n',
            "        (geo.[isglb,is360]) : ",(ereg.isglb,ereg.is360),"\n",
        )
    end

end