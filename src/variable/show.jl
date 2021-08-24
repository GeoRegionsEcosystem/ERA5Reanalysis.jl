function show(io::IO, evar::SingleLevel)
    print(
		io,
		"The Single-Level Variable $(evar.varID) has the following properties:\n",
		"    Variable ID    (varID) : ", evar.varID, '\n',
		"    Long Name      (lname) : ", evar.lname, '\n',
		"    Variable Name  (vname) : ", evar.vname, '\n',
		"    Variable Units (units) : ", evar.units, '\n',
	)
end

function show(io::IO, evar::PressureLevel)
    print(
		io,
		"The Pressure-Level Variable $(evar.varID) has the following properties:\n",
		"    Variable ID    (varID) : ", evar.varID, '\n',
		"    Long Name      (lname) : ", evar.lname, '\n',
		"    Variable Name  (vname) : ", evar.vname, '\n',
		"    Variable Units (units) : ", evar.units, '\n',
		"    Pressure Level (plvl)  : ", evar.plvl,  '\n',
	)
end