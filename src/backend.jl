## DateString Aliasing
yrmo2dir(date::TimeType) = Dates.format(date,dateformat"yyyy/mm")
yrmo2str(date::TimeType) = Dates.format(date,dateformat"yyyymm")
yr2str(date::TimeType)   = Dates.format(date,dateformat"yyyy")
ymd2str(date::TimeType)  = Dates.format(date,dateformat"yyyymmdd")

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

function nanmean(
    data :: AbstractArray,
    dNaN :: AbstractArray,
    wgts :: AbstractArray,
)
    nNaN = length(dNaN)
    for iNaN in 1 : nNaN
        dNaN[iNaN] = !isnan(data[iNaN])
    end
    dataii = view(data,dNaN) .* view(wgts,dNaN)
    wgtsii = view(wgts,dNaN)
    if !isempty(dataii); return sum(dataii) / sum(wgtsii); else; return NaN; end
end

function nansum(
    data :: AbstractArray,
    dNaN :: AbstractArray
)
    nNaN = length(dNaN)
    for iNaN in 1 : nNaN
        dNaN[iNaN] = !isnan(data[iNaN])
    end
    dataii = @view data[dNaN]
    if !isempty(dataii); return sum(dataii); else; return NaN; end
end

ntimesteps(     :: ERA5Hourly)  = 31 * 24
ntimesteps(     :: ERA5Daily)   = 31
ntimesteps(e5ds :: ERA5Monthly) = if e5ds.hours; return 12 * 24; else; return 12 end

function unit2string(eunit :: Unitful.Units)

    # UnitfulParsableString.slashnotation(false)
    str = replace(replace(string(eunit),"*"=>" "),"^"=>"**")
    # UnitfulParsableString.slashnotation()

    return str

end

string2unit(ustr :: String) = uparse(replace(replace(ustr," "=>"*"),"**"=>"^"))