

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

function containing_method(mod::Module, file, linenum)

end
