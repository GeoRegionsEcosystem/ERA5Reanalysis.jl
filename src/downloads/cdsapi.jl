"""
    retrieve(
        dset  :: AbstractString,
        dkeys :: AbstractDict,
        fnc   :: AbstractString,
        ckeys :: AbstractDict = cdskey()
    )
Retrieves dsets from the Climate Data Store, with options specified in a Julia Dictionary and saves it into a specified file.
Arguments:
    * `dset::AbstractString` : string specifies the name of the dset within the Climate Data Store that the `retrieve` function is attempting to retrieve data from
    * `dkeys::AbstractDict` : dictionary that contains the keywords that specify the properties (e.g. date, resolution, grid) of the data being retrieved
    * `fnc::AbstractString` : string that contains the path and name of the file that the data is to be saved into
    * `ckeys::AbstractDict` : dictionary that contains API Key information read from the .cdsapirc file in the home directory (optional)
"""
function retrieve(
    dset  :: AbstractString,
    dkeys :: AbstractDict,
    fnc   :: AbstractString,
    ckeys :: AbstractDict = cdskey();
    pause :: Real = 120.
)

    @info "$(now()) - CDSAPI - Sending request to https://cds.climate.copernicus.eu/api/retrieve/v1/processes/$dset/execute ..."
    response = HTTP.request(
        "POST", ckeys["url"] * "/retrieve/v1/processes/$dset/execute",
        ["PRIVATE-TOKEN" => ckeys["key"]],
        body = JSON3.write(Dict("inputs" => dkeys)),
        verbose = 0,
        retry = true, retries = 19
    )
    resp_dict = JSON3.read(String(response.body))
    location  = Dict(response.headers)["location"]
    data = Dict("status" => "queued")

    @info "$(now()) - CDSAPI - Request is queued"; flush(stderr)
    sleep_seconds = 1.
    while data["status"] == "queued"
        data = parserequest(ckeys,resp_dict)
        sleep_seconds = min(1.5 * sleep_seconds,5)
        sleep(sleep_seconds)
    end

    @info "$(now()) - CDSAPI - Request is running"; flush(stderr)
    sleep_seconds = 1.
    while data["status"] != "successful"

        data = parserequest(ckeys,resp_dict)
        sleep_seconds = min(1.5 * sleep_seconds,5)
        sleep(sleep_seconds)

        if data["status"] == "failed"
            @error "$(now()) - CDSAPI - Request failed"
        end

    end

    if data["status"] == "successful"

        response = HTTP.request(
            "GET", location * "/results",
            ["PRIVATE-TOKEN" => ckeys["key"]]
        )
        data  = JSON3.read(String(response.body))["asset"]["value"]
        fsize = data["file:size"]
        url   = data["href"]

        @info """$(now()) - CDSAPI - Downloading $(uppercase(dset)) data ...
          URL:         $(url)
          Destination: $(fnc)
        """
        flush(stderr)

        dt1 = now()
        HTTP.download(url,fnc,update_period=Inf)
        dt2 = now()
        @info "$(now()) - CDSAPI - Downloaded $(@sprintf("%.1f",fsize/1024^2)) MB in $(@sprintf("%.1f",Dates.value(dt2-dt1)/1000)) seconds (Rate: $(@sprintf("%.1f",fsize/1024^2/Dates.value(dt2-dt1)*1000)) MB/s)"

        # tries = 0
        # while isinteger(tries) && (tries < 10)
        #     try
        #         dt1 = now()
        #         HTTP.download(url,fnc,update_period=Inf)
        #         dt2 = now()
        #         tries += 0.5
        #         @info "$(now()) - CDSAPI - Downloaded $(@sprintf("%.1f",fsize/1024^2)) MB in $(@sprintf("%.1f",Dates.value(dt2-dt1)/1000)) seconds (Rate: $(@sprintf("%.1f",fsize/1024^2/Dates.value(dt2-dt1)*1000)) MB/s)"
        #     catch
        #         tries += 1
        #         @info "$(now()) - CDSAPI - Failed to download on Attempt $(tries) of 10"
        #     end
        #     flush(stderr)
        # end

        # if tries == 10
        #     @warn "$(now()) - CDSAPI - Failed to download data, skipping to next request"
        # end

    end

    flush(stderr)

    return

end

"""
    cdskey() -> Dict{Any,Any}
Retrieves the CDS API ckeys from the `~/.cdsapirc` file in the home directory
"""
function cdskey(path :: AbstractString = homedir())

    ckeys = Dict(); cdsapirc = joinpath(path,".cdsapirc")

    @info "$(now()) - CDSAPI - Loading CDSAPI credentials from $(cdsapirc) ..."
    open(cdsapirc) do f
        for line in readlines(f)
            key,val = strip.(split(line,':',limit=2))
            ckeys[key] = val
        end
    end

    return ckeys

end

"""
    parserequest(
        ckeys :: AbstractDict,
        resp  :: AbstractDict,
        api   :: AbstractString
    ) -> Dict{Any,Any}
Get info on HTTP request, and parse the information and update the dictionary

Arguments
---------
* `ckeys` : Dictionary that contains the CDSAPI information held in `~/.cdsapirc`
* `resp` : Dictionary that contains the HTTP response
* `api`  : String that contains the API used for Climate Data Store authentication
"""
function parserequest(
    ckeys :: AbstractDict,
    resp  :: AbstractDict,
)

    data = HTTP.request(
        "GET", ckeys["url"] * "/retrieve/v1/jobs/" * string(resp["jobID"]),
        ["PRIVATE-TOKEN" => ckeys["key"]]
    )
    data = JSON3.read(String(data.body))

    return data

end

"""
    addCDSAPIkey(
        key :: AbstractString;
        url :: AbstractString = "https://cds.climate.copernicus.eu/api/v2",
        filename  :: AbstractString = ".cdsapirc",
        overwrite :: Bool = false
    ) -> nothing

Adds the user's CDSAPI key to a file in the `homedir()` (by default specified as `.cdsapirc`)

Arguments
---------
* `key` : The user's CDSAPI key

Keyword Arguments
-----------------
* `url` : The user's CDSAPI key
* `filename`  : The name of the file the url and key are saved to in the `homedir()`
* `overwrite` : If `true` and if `filename` already exists, then overwrite
"""
function addCDSAPIkey(
    key  :: AbstractString;
    url  :: AbstractString = "https://cds.climate.copernicus.eu/api",
    path :: AbstractString = homedir(),
    filename  :: AbstractString = ".cdsapirc",
    overwrite :: Bool = false
)

    fID = joinpath(path,filename)
    if !isfile(fID) || overwrite

        @info "$(now()) - CDSAPI - Adding key to $fID ..."
        open(fID,"w") do f

            write(f,"url: $url\nkey: $key")

        end

    else

        @info "$(now()) - CDSAPI - Existing .cdsapirc file detected at $fID, since overwrite options is not selected, leaving file be ...  ..."

    end

    return nothing

end