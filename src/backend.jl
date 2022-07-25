## DateString Aliasing
yrmo2dir(date::TimeType) = Dates.format(date,dateformat"yyyy/mm")
yrmo2str(date::TimeType) = Dates.format(date,dateformat"yyyymm")
yr2str(date::TimeType)   = Dates.format(date,dateformat"yyyy")
ymd2str(date::TimeType)  = Dates.format(date,dateformat"yyyymmdd")

function ncoffsetscale(data::AbstractArray{<:Real})

    dmax = data[findfirst(!isnan,data)]
    dmin = data[findfirst(!isnan,data)]
    for ii in eachindex(iarray)
        dataii = data[ii]
        if !isnan(dataii)
            if dataii > dmax; dmax = dataii end
            if dataii < dmin; dmin = dataii end
        end
    end

    scale = (dmax-dmin) / 65531;
    offset = (dmax+dmin-scale) / 2;

    return scale,offset

end

function int2real!(
    oarray :: AbstractArray{FT},
    iarray :: AbstractArray{Int16};
    scale  :: Real,
    offset :: Real,
    fvalue :: Int16,
    mvalue :: Int16
) where FT <: Real

    for ii in eachindex(iarray)

        if (iarray[ii] == fvalue) || (iarray[ii] == mvalue)
              oarray[ii] = FT(NaN)
        else; oarray[ii] = iarray[ii] * scale + offset
        end

    end

    return

end

function real2int16!(
    oarray :: AbstractArray{Int16},
    iarray :: AbstractArray{<:Real},
    scale  :: Real,
    offset :: Real
)

    for ii in eachindex(iarray)

        idata = (iarray[ii] - offset) / scale
        if isnan(idata)
              oarray[ii] = -32767
        else; oarray[ii] = round(Int16,idata)
        end

    end

    return

end

function real2int16(
    iarray :: AbstractArray{<:Real},
    scale  :: Real,
    offset :: Real
)

    oarray = zeros(Int16,size(iarray))
    for ii in eachindex(iarray)

        idata = (iarray[ii] - offset) / scale
        if isnan(idata)
              oarray[ii] = -32767
        else; oarray[ii] = round(Int16,idata)
        end

    end

    return oarray

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

function nanmean(
    data :: AbstractArray,
    dNaN :: AbstractArray
)
    nNaN = length(dNaN)
    for iNaN in 1 : nNaN
        dNaN[iNaN] = !isnan(data[iNaN])
    end
    dataii = @view data[dNaN]
    if !isempty(dataii); return mean(dataii); else; return NaN; end
end