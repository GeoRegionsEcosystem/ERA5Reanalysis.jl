function tableERA5Variables(;
    path :: AbstractString = homedir(),
    predefined :: Bool = true,
    custom     :: Bool = false,
    warn :: Bool = true,
    crop :: Bool = false
)

    fmat = []
    
    if custom
        for fname in ["SingleCustom","PressureCustom"]
            fid  = joinpath(path,"$(lowercase(fname)).txt")
            if isfile(fid)
                vmat = readdlm(fid,',',comments=true,comment_char='#')
                nvar = size(vmat,1); ff = fill(fname,nvar); mm = fill(missing,nvar)
                vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2]],mm,mm,dims=2)
                fmat = cat(fmat,vmat,dims=1)
            else
                if warn
                    @warn "$(modulelog()) - The custom file does \"$fname.txt\" does not exist in $path, use `setupERA5Variables()` to copy templates and empty custom lists to $path."
                end
            end
        end
    end
    
    if predefined
        for fname in ["SingleVariable","PressureVariable"]
            fid  = joinpath(eradir,"$(lowercase(fname)).txt")
            vmat = readdlm(fid,',',comments=true,comment_char='#')
            nvar = size(vmat,1); ff = fill(fname,nvar)
            vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2,5,6]],dims=2)
            fmat = cat(fmat,vmat,dims=1)
        end
    end

    fmat[iszero.(fmat[:,6]),6:7] .= missing

    head = ["ID","Variable Type","Name","Units","ERA5 Long-Name","DKRZ ID","DKRZ Invariant"]

    if isempty(fmat)
        fmat  = Array{String,2}(undef,1,7)
        fmat .= "N/A"
    end

    if !crop
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l,:c,:c],
            crop = :none, tf = tf_compact
        );
    else
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l,:c,:c],
            crop = :vertical, tf = tf_compact
        );
    end

    return nothing

end

function tableSingles(;
    path :: AbstractString = homedir(),
    predefined :: Bool = true,
    custom     :: Bool = false,
    warn :: Bool = true,
    crop :: Bool = false
)

    fmat = []
        
    if custom
        fid  = joinpath(path,"singlecustom.txt")
        if isfile(fid)
            vmat = readdlm(fid,',',comments=true,comment_char='#')
            nvar = size(vmat,1); ff = fill("SingleCustom",nvar); mm = fill(missing,nvar)
            vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2]],mm,mm,dims=2)
            fmat = cat(fmat,vmat,dims=1)
        else
            if warn
                @warn "$(modulelog()) - The custom file does \"singlecustom.txt\" does not exist in $path, use `setupERA5Variables()` to copy templates and empty custom lists to $path."
            end
        end
    end

    if predefined
        vmat = readdlm(
            joinpath(eradir,"singlevariable.txt"),
            ',',comments=true,comment_char='#'
        )
        nvar = size(vmat,1); ff = fill("SingleVariable",nvar)
        vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2,5,6]],dims=2)
        fmat = cat(fmat,vmat,dims=1)
    end

    fmat[iszero.(fmat[:,6]),6:7] .= missing

    head = ["ID","Variable Type","Name","Units","ERA5 Long-Name","DKRZ ID","DKRZ Invariant"]

    if isempty(fmat)
        fmat  = Array{String,2}(undef,1,7)
        fmat .= "N/A"
    end

    if !crop
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l,:c,:c],
            crop = :none, tf = tf_compact
        );
    else
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l,:c,:c],
            crop = :vertical, tf = tf_compact
        );
    end

    return nothing

end

function tablePressures(;
    path :: AbstractString = homedir(),
    predefined :: Bool = true,
    custom     :: Bool = false,
    warn :: Bool = true,
    crop :: Bool = false
)

    fmat = []
        
    if custom
        fid  = joinpath(path,"pressurecustom.txt")
        if isfile(fid)
            vmat = readdlm(fid,',',comments=true,comment_char='#')
            nvar = size(vmat,1); ff = fill("PressureCustom",nvar); mm = fill(missing,nvar)
            vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2]],mm,mm,dims=2)
            fmat = cat(fmat,vmat,dims=1)
        else
            if warn
                @warn "$(modulelog()) - The custom file does \"pressurecustom.txt\" does not exist in $path, use `setupERA5Variables()` to copy templates and empty custom lists to $path."
            end
        end
    end

    if predefined
        vmat = readdlm(
            joinpath(eradir,"pressurevariable.txt"),
            ',',comments=true,comment_char='#'
        )
        nvar = size(vmat,1); ff = fill("pressurevariable",nvar)
        vmat = cat(vmat[:,1],ff,vmat[:,[3,4,2,5,6]],dims=2)
        fmat = cat(fmat,vmat,dims=1)
    end

    head = ["ID","Variable Type","Name","Units","ERA5 Long-Name"];

    if isempty(fmat)
        fmat  = Array{String,2}(undef,1,5)
        fmat .= "N/A"
    end

    if !crop
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l],
            crop = :none, tf = tf_compact
        );
    else
        pretty_table(
            fmat,header=head,
            alignment=[:c,:c,:l,:c,:l],
            crop = :vertical, tf = tf_compact
        );
    end

    return nothing

end