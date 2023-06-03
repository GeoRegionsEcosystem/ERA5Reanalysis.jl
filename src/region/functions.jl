"""
    isinERA5Region(
        point :: Point2{<:Real},
        e5geo :: ERA5Region;
        tlon  :: Real = 0,
        tlat  :: Real = 0,
        throw :: Bool = true
    ) -> Bool

Check if a geographical point `Point` is within an ERA5Region defined by `e5geo`.

Arguments
=========

- `point` : A geographical point of Type `Point2`.  Pass `Point2(plon,plat)`, where `plon` and `plat` are the longitude and latitudes of the point.
- `e5geo` : The ERA5Region struct container

Keyword Arguments
=================

- `tlon`  : Threshold for the longitude bound
- `tlat`  : Threshold for the latitude bound
- `throw` : If `true`, then if `Point` is not within `geo`, an error is thrown and the program stops running.
"""
function isinERA5Region(
    point :: Point2{<:Real},
    e5geo :: ERA5Region;
    tlon  :: Real = 0,
    tlat  :: Real = 0,
    throw :: Bool = true
)

    return isinGeoRegion(point,e5geo.geo,tlon=tlon,tlat=tlat,throw=throw)

end

"""
    isinERA5Region(
        geo    :: GeoRegion,
        e5geo  :: ERA5Region;
        domask :: Bool = false,
        throw  :: Bool = true
    ) -> Bool

Check if a child GeoRegion defined by `geo` is within a ERA5Region `e5geo`.

Arguments
=========

- `geo`   : A GeoRegion that we postulate to be a "child", or a subset of the ERA5Region defined by `e5geo`
- `e5geo` : An ERA5Region that we postulate to be a "parent", or containing the GeoRegion defined by `geo`

Keyword Arguments
=================

- `throw`  : If `true`, then if `geo` is not within `e5geo`, an error is thrown and the program stops running
- `domask` : If `throw` is `false` and `domask` is `true`, return a mask (with bounds defined by the `geo` GeoRegion) showing the region where `geo` and `e5geo` do not overlap
"""
function isinERA5Region(
    geo    :: GeoRegion,
    e5geo  :: ERA5Region;
    domask :: Bool = false,
    throw  :: Bool = true
)

    return isinGeoRegion(geo,e5geo.geo,domask=domask,throw=throw)

end

"""
    RegionGrid(
        e5geo :: ERA5Region{ST,FT},
        lon   :: Vector{<:Real},
        lat   :: Vector{<:Real}
    ) -> GeoRegion.RegionGrid

Creates a RegionGrid containing information and mask information required to extract regional data for the ERA5Region from the raw data.

Arguments
=========

- `e5geo` : A ERA5Region struct type
- `lon`   : A vector containing the longitude points
- `lat`   : A vector containing the latitude points
"""
function RegionGrid(
    e5geo :: ERA5Region,
    lon   :: Vector{<:Real},
    lat   :: Vector{<:Real}
)

    return RegionGrid(e5geo.geo,lon,lat)

end

"""
    RegionGrid(
        e5geo :: ERA5Region{ST,FT},
        lon   :: Array{<:Real},
        lat   :: Array{<:Real}
    ) -> GeoRegion.RegionGrid

Creates a RegionGrid containing information and mask information required to extract regional data for the ERA5Region from the raw data.

Arguments
=========

- `e5geo` : A ERA5Region struct type
- `lon`   : An array containing the longitude points
- `lat`   : An array containing the latitude points
"""
function RegionGrid(
    e5geo :: ERA5Region,
    lon   :: Array{<:Real,2},
    lat   :: Array{<:Real,2}
)

    return RegionGrid(e5geo.geo,lon,lat)

end