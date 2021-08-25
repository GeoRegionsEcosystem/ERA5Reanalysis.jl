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
    ckeys :: AbstractDict = cdskey()
)

    @info "$(now()) - CDSAPI - Welcome to the Climate Data Store"
    apikey = string("Basic ", base64encode(ckeys["key"]))

    @info "$(now()) - CDSAPI - Sending request to https://cds.climate.copernicus.eu/api/v2/resources/$(dset) ..."
    response = HTTP.request(
        "POST", ckeys["url"] * "/resources/$(dset)",
        ["Authorization" => apikey],
        body = JSON.json(dkeys),
        verbose = 0
    )
    resp_dict = JSON.parse(String(response.body))
    data = Dict("state" => "queued")

    @info "$(now()) - CDSAPI - Request is queued"
    while data["state"] == "queued"
        data = parserequest(ckeys,resp_dict,apikey)
    end

    @info "$(now()) - CDSAPI - Request is running"
    while data["state"] == "running"
        data = parserequest(ckeys,resp_dict,apikey)
    end

    if data["state"] == "completed"

        @info "$(now()) - CDSAPI - Request is completed"

        @info """$(now()) - CDSAPI - Downloading $(uppercase(dset)) data ...
          URL:         $(data["location"])
          Destination: $(fnc)
        """

        dt1 = now()
        HTTP.download(data["location"],fnc,update_period=Inf)
        dt2 = now()

        @info "$(now()) - CDSAPI - Downloaded $(@sprintf("%.1f",data["content_length"]/1e6)) MB in $(@sprintf("%.1f",Dates.value(dt2-dt1)/1000)) seconds (Rate: $(@sprintf("%.1f",data["content_length"]/1e3/Dates.value(dt2-dt1))) MB/s)"

    elseif data["state"] == "failed"

        @error "$(now()) - CDSAPI - Request failed"

    end

    return

end

"""
    cdskey() -> Dict{Any,Any}
Retrieves the CDS API ckeys from the `~/.cdsapirc` file in the home directory
"""
function cdskey()

    ckeys = Dict(); cdsapirc = joinpath(homedir(),".cdsapirc")

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
    api   :: AbstractString
)

    data = HTTP.request(
        "GET", ckeys["url"] * "/tasks/" * string(resp["request_id"]),
        ["Authorization" => api]
    )
    data = JSON.parse(String(data.body))

    return data

end