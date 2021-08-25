function show(io::IO, emod::ERA5Hourly)
    print(
		io,
		"The ERA5Hourly Dataset has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Data Directory (eroot) : ", emod.seroot, '\n',
		"    Date Begin     (dtbeg) : ", emod.dtbeg, '\n',
		"    Date End       (dtend) : ", emod.dtend, '\n',
	)
end

function show(io::IO, emod::ERA5Monthly)
    print(
		io,
		"The ERA5Monthly Dataset has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Data Directory (eroot) : ", emod.seroot, '\n',
		"    Date Begin     (dtbeg) : ", emod.dtbeg, '\n',
		"    Date End       (dtend) : ", emod.dtend, '\n',
	)
end

function show(io::IO, emod::ERA5MonthlyHour)
    print(
		io,
		"The ERA5MonthlyHour Dataset has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Data Directory (eroot) : ", emod.seroot, '\n',
		"    Date Begin     (dtbeg) : ", emod.dtbeg, '\n',
		"    Date End       (dtend) : ", emod.dtend, '\n',
		"    Hours-of-Day   (hours) : ", emod.hours, '\n',
	)
end