function show(io::IO, evar::SingleLevel)
    print(
		io,
		"The Single-Level Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID       (ID) : ", evar.ID,    '\n',
		"    Long Name       (long) : ", evar.long,  '\n',
		"    Variable Name   (name) : ", evar.name,  '\n',
		"    Variable Units (units) : ", evar.units, '\n',
		"    DRKZ ID         (dkrz) : ", evar.dkrz,  '\n',
	)
end

function show(io::IO, evar::PressureLevel)
    print(
		io,
		"The Pressure-Level Variable \"$(evar.ID)\" has the following properties:\n",
		"    Variable ID       (ID) : ", evar.ID,    '\n',
		"    Long Name       (long) : ", evar.long,  '\n',
		"    Variable Name   (name) : ", evar.name,  '\n',
		"    Variable Units (units) : ", evar.units, '\n',
		"    Pressure Level   (hPa) : ", evar.hPa,   '\n',
		"    DRKZ ID         (dkrz) : ", evar.dkrz,  '\n',
	)
end