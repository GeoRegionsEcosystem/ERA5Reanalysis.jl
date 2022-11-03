function show(io::IO, emod::ERA5Hourly)
    print(
		io,
		"The ERA5Hourly Module has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Date Begin     (start) : ", emod.start, '\n',
		"    Date End        (stop) : ", emod.stop,  '\n',
		"    Back Extension (dtext) : ", emod.dtext, '\n',
		"    Data Directory  (path) : ", emod.path,  '\n',
		"    Mask Directory (emask) : ", emod.emask, '\n',
	)
end

function show(io::IO, emod::ERA5Daily)
    print(
		io,
		"The ERA5Daily Module has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Date Begin     (start) : ", emod.start, '\n',
		"    Date End        (stop) : ", emod.stop,  '\n',
		"    Back Extension (dtext) : ", emod.dtext, '\n',
		"    Data Directory  (path) : ", emod.path,  '\n',
		"    Mask Directory (emask) : ", emod.emask, '\n',
	)
end

function show(io::IO, emod::ERA5Monthly)
    print(
		io,
		"The ERA5Monthly Module has the following properties:\n",
		"    Dataset ID     (e5dID) : ", emod.e5dID, '\n',
		"    Date Begin     (start) : ", emod.start, '\n',
		"    Date End        (stop) : ", emod.stop, '\n',
		"    Back Extension (dtext) : ", emod.dtext, '\n',
		"    Data Directory  (path) : ", emod.path, '\n',
		"    Mask Directory (emask) : ", emod.emask, '\n',
		"    Hour-of-Day?   (hours) : ", emod.hours, '\n',
	)
end