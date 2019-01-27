



"""
    pkgdata(mod)

Gets all the data Revise has on the given module.
"""
pkgdata(mod::Module) = Revise.pkgdatas[Base.PkgId(mod)]
# TODO check how this works for submodules, might need to root module it first.

"""
    filemap(mod, file)

Retrieve all the data Revise has on the contents of given file
from the given module.
"""
function filemap(mod::Module, file)
    mdata = pkgdata(mod)
    mfiles = joinpath.(mdata.path, keys(mdata.fileinfos))
    
    if !isabspath(file)
        # We do not need it to be absolute
        # But we do want it to start with a "/"
        # So we can use `endswith` to check that it matchs one of the paths
        # that we know about, without worry of matching part of a filename
        file = "/" * file
    end
    matched_ind = findfirst(mfile->endswith(mfile, file) , mfiles)
    matched_ind ===  nothing &&  error("Could not locate $file in $mod")
     
    internal_file = collect(keys(mdata.fileinfos))[matched_ind]
    Revise.maybe_parse_from_cache!(mdata, internal_file)  # Ensure fileinfo filled
    finfo = collect(values(mdata.fileinfos))[matched_ind]
    return finfo.fm
end



function linerange((def, (sig, offset))::Tuple{Any, Tuple{Any, Int}})
    return Rebugger.linerange(def, offset)
end


# This is not a function so just return an empty range
linerange((def, none)::Tuple{Any, Nothing}) = 1:0


function containing_method(mod::Module, file, linenum)
    module_fmaps = filemap(mod, file)
    for (inner_mod, fmaps) in module_fmaps
        for entry in fmaps.defmap
            def, info = entry
            lr = linerange((def, info))
            if linenum ∈ lr
                sigt, offset = info
                return sigt2methsig(sigt)
            end
        end
    end
end
