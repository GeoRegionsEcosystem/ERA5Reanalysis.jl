function show(io::IO, evar::SingleVariable)
    print(
		io,
		"The Single-Level Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID       (ID) : ", evar.ID,        '\n',
		"    Long Name       (long) : ", evar.long,      '\n',
		"    Variable Name   (name) : ", evar.name,      '\n',
		"    Variable Units (units) : ", evar.units,     '\n',
		"    Is Analysis (analysis) : ", evar.analysis,  '\n',
		"    Is Forecast (forecast) : ", evar.forecast,  '\n',
		"    Invariant? (invariant) : ", evar.invariant, '\n',
		"    NetCDF ID       (ncID) : ", evar.ncID,      '\n',
		"    MARS ID         (mars) : ", evar.mars,      '\n',
		"    DRKZ ID         (dkrz) : ", evar.dkrz,      '\n',
	)
end

function show(io::IO, evar::SingleCustom)
    print(
		io,
		"The Single-Level Custom Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID  (ID/ncID) : ", evar.ID,        '\n',
		"    Long Name       (long) : ", evar.long,      '\n',
		"    Variable Name   (name) : ", evar.name,      '\n',
		"    Variable Units (units) : ", evar.units,     '\n',
	)
end

function show(io::IO, evar::PressureVariable)
    print(
		io,
		"The Pressure-Level Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID       (ID) : ", evar.ID,        '\n',
		"    Long Name       (long) : ", evar.long,      '\n',
		"    Variable Name   (name) : ", evar.name,      '\n',
		"    Variable Units (units) : ", evar.units,     '\n',
		"    Pressure Level   (hPa) : ", evar.hPa,       '\n',
		"    Is Analysis (analysis) : ", evar.analysis,  '\n',
		"    Is Forecast (forecast) : ", evar.forecast,  '\n',
		"    Invariant? (invariant) : ", evar.invariant, '\n',
		"    NetCDF ID       (ncID) : ", evar.ncID,      '\n',
		"    MARS ID         (mars) : ", evar.mars,      '\n',
		"    DRKZ ID         (dkrz) : ", evar.dkrz,      '\n',
	)
end

function show(io::IO, evar::PressureCustom)
    print(
		io,
		"The Pressure-Level Custom Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID  (ID/ncID) : ", evar.ID,        '\n',
		"    Long Name       (long) : ", evar.long,      '\n',
		"    Variable Name   (name) : ", evar.name,      '\n',
		"    Variable Units (units) : ", evar.units,     '\n',
		"    Pressure Level   (hPa) : ", evar.hPa,       '\n',
	)
end