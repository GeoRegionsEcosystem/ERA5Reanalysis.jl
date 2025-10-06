struct RegridGrid{FT1<:Real,FT2<:Real} <: RegionGrid
        lon :: Vector{FT1}
        lat :: Vector{FT1}
       ilon :: Vector{Int}
       ilat :: Vector{Int}
       mask :: Matrix{FT2}
    weights :: Matrix{FT2}
          X :: Matrix{FT2}
          Y :: Matrix{FT2}
          θ :: FT2
end

function RegridGrid(
    geo  :: GeoRegion,
    elon :: Vector{FT1},
    elat :: Vector{FT1};
    resolution :: Real,
    rotation   :: Real = 0,
    sigdigits  :: Int = 10,
    FT2 = Float64
) where FT1 <: Real

    isinteger(360/resolution) ? nothing : error("$(modulelog()) - The `resolution` keyword must be able to divide 360")

    lon = 0  :  resolution :  360; lon = (lon[1:(end-1)].+lon[2:end])./2
    lat = 90 : -resolution : -90;  lat = (lat[1:(end-1)].+lat[2:end])./2
    ggrd = RegionGrid(geo,lon,lat)
    nlon = length(ggrd.lon)
    nlat = length(ggrd.lat)
    npnt = length(data)

    x = zeros(nlon,nlat)
    y = zeros(nlon,nlat)
    z = zeros(nlon,nlat)
	d = zeros(nlon,nlat)
    for ilat = 1 : nlat, ilon = 1 : nlon
        x[ilon,ilat] = cosd(ggrd.lon[ilon]) .* cosd(ggrd.lat[ilat])
        y[ilon,ilat] = sind(ggrd.lon[ilon]) .* cosd(ggrd.lat[ilat])
        z[ilon,ilat] = sind(ggrd.lat[ilat])
    end

    ex = zeros(npnt)
    ey = zeros(npnt)
    ez = zeros(npnt)
    for ipnt = 1 : npnt
        ex[ipnt] = cosd(elon[ipnt]) .* cosd(elat[ipnt])
        ey[ipnt] = sind(elon[ipnt]) .* cosd(elat[ipnt])
        ez[ipnt] = sind(elat[ipnt])
    end

    ind_lon = zeros(Int,npnt)
    ind_lat = zeros(Int,npnt)
    for ipnt = 1 : npnt
		for ilat = 1 : nlat, ilon = 1 : nlon
			d[ilon,ilat] = abs(
	            (ex[ipnt] .- x[ilon,ilat]).^2 .+ 
	            (ey[ipnt] .- y[ilon,ilat]).^2 .+ 
	            (ez[ipnt] .- z[ilon,ilat]).^2
	        )
		end
		indx = argmin(d)
        ind_lon[ipnt] = indx[1]
        ind_lat[ipnt] = indx[2]
    end

	return RegridGrid{FT1,FT2}(
        ggrd.lon, ggrd.lat, ind_lon, ind_lat,
        ggrd.mask, ggrd.weights, ggrd.X, ggrd.Y, ggrd.θ
    )

end

function native2lonlat(
    data :: Vector{<:Real},
    rgrd :: RegridGrid
)

    nlon = length(rgrd.lon)
    nlat = length(rgrd.lat)

    ndata = zeros(nlon,nlat) * NaN
    for ilat = 1 : nlat, ilon = 1 : nlon
		ii = (rgrd.ilon.==ilon).&(rgrd.ilat.==ilat)
		if !isnothing(ii) && !iszero(sum(ii))
        	ndata[ilon,ilat] = mean(@views data[ii])
		end
    end

    return ndata

end

function native2lonlat!(
    ndata :: Matrix{<:Real},
    odata :: Vector{<:Real},
    rgrd  :: RegridGrid
)

    for ilat = 1 : length(rgrd.lat), ilon = 1 : length(rgrd.lon)
		ii = (rgrd.ilon.==ilon).&(rgrd.ilat.==ilat)
		if !isnothing(ii) && !iszero(sum(ii))
        	ndata[ilon,ilat] = mean(@views odata[ii])
		end
    end

    return

end