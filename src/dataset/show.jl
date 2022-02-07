function show(io::IO, emod::ERA5Hourly)
    print(
		io,
		"The ERA5Hourly Module has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Date Begin     (dtbeg) : ", emod.dtbeg, '\n',
		"    Date End       (dtend) : ", emod.dtend, '\n',
		"    Back Extension (dtext) : ", emod.dtext, '\n',
		"    Data Directory (eroot) : ", emod.eroot, '\n',
		"    Mask Directory (emask) : ", emod.emask, '\n',
	)
end

function show(io::IO, emod::ERA5Monthly)
    print(
		io,
		"The ERA5Monthly Module has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Date Begin     (dtbeg) : ", emod.dtbeg, '\n',
		"    Date End       (dtend) : ", emod.dtend, '\n',
		"    Back Extension (dtext) : ", emod.dtext, '\n',
		"    Data Directory (eroot) : ", emod.eroot, '\n',
		"    Mask Directory (emask) : ", emod.emask, '\n',
		"    Hour-of-Day?   (hours) : ", emod.hours, '\n',
	)
end