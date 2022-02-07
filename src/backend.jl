## DateString Aliasing
yrmo2dir(date::TimeType) = Dates.format(date,dateformat"yyyy/mm")
yrmo2str(date::TimeType) = Dates.format(date,dateformat"yyyymm")
yr2str(date::TimeType)   = Dates.format(date,dateformat"yyyy")
ymd2str(date::TimeType)  = Dates.format(date,dateformat"yyyymmdd")

function ncoffsetscale(data::AbstractArray{<:Real})

    dmax = data[1]
    dmin = data[1]
    for ii = 1 : length(data)
        dataii = data[ii]
        if !isnan(dataii)
            if dataii > dmax; dmax = dataii end
            if dataii < dmin; dmin = dataii end
        end
    end

    scale = (dmax-dmin) / 65533;
    offset = (dmax+dmin-scale) / 2;

    return scale,offset

end

function real2int16!(
    outarray :: AbstractArray{Int16},
    inarray  :: AbstractArray{<:Real},
    scale    :: Real,
    offset   :: Real
)

    for ii = 1 : length(inarray)

        idata = (inarray[ii] - offset) / scale
        if isnan(idata)
              outarray[ii] = -32767
        else; outarray[ii] = round(Int16,idata)
        end

    end

    return

end

function extractregionlsm!(
	outarray :: Array{<:Real,2},
	inarray  :: Array{<:Real,2},
	ginfo	 :: RectGrid
)

	iglon = ginfo.ilon; nglon = length(iglon)
	iglat = ginfo.ilat; nglat = length(iglat)
	for ilat = 1 : nglat, ilon = 1 : nglon
		outarray[ilon,ilat] = inarray[iglat[ilat],iglon[ilon]]
	end

end

function extractregionlsm!(
	outarray :: Array{<:Real,2},
	inarray  :: Array{<:Real,2},
	ginfo	 :: PolyGrid
)

	iglon = ginfo.ilon; nglon = length(iglon)
	iglat = ginfo.ilat; nglat = length(iglat)
	for ilat = 1 : nglat, ilon = 1 : nglon
		outarray[ilon,ilat] = inarray[iglat[ilat],iglon[ilon]] * ginfo.mask[ilon,ilat]
	end

end
