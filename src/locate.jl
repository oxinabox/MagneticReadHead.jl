"""
    pkgdata(mod)

Gets all the data Revise has on the given module.
"""
pkgdata(pkg_id::Base.PkgId) = Revise.pkgdatas[pkg_id]
pkgdata(mod::Module) = pkgdata(Base.PkgId(mod))

"""
    filemap(mod, file)

Retrieve all the data Revise has on the contents of given file
from the given module.
"""
function filemap(mod, file)
    mdata = pkgdata(mod)
    mfiles = joinpath.(mdata.path, keys(mdata.fileinfos))
    
    file = expanduser(file)
    if !isabspath(file)
        # We do not need it to be absolute
        # But we do want it to start with a "/"
        # So we can use `endswith` to check that it matchs one of the paths
        # that we know about, without worry of matching part of a filename
        file = "/" * file
    end
    matched_ind = findfirst(mfile->endswith(mfile, file) , mfiles)
    matched_ind ===  nothing && return nothing
     
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

"""
    containing_method([module], filename, linenum)

Returns the method within which that line number, in that file, occurs.
Returns `nothing` on no match.

If the module is not provided, then all modules loaded
will be searched for a file with that name that has a function over that line.

Filenames can be absolute, or partial.
E.g. `/home/user1/dev/MyMod/src/helpers/utils.jl`,
`helpers/utils.jl` or `utils.jl` are all acceptable.

However, if multiple files match the module (or lack of module),
and filename specification then only one will be  selected.
"""
function containing_method(mod, file, linenum)
    module_fmaps = filemap(mod, file)
    module_fmaps === nothing && return nothing
    for (inner_mod, fmaps) in module_fmaps
        for entry in fmaps.defmap
            def, info = entry
            lr = linerange((def, info))
            if linenum ∈ lr
                sigt, offset = info
                return sigt2meth(sigt[end])
            end
        end
    end
end

function containing_method(file, linenum)
    for pkg_id in keys(Revise.pkgdatas)
        meth = containing_method(pkg_id, file, linenum)
        meth !== nothing && return meth
    end
end

function sigt2meth(::Type{SIGT}) where SIGT
    params = SIGT.parameters
    func_t = params[1]
    func = func_t.instance

    args_t = Tuple{params[2:end]...}

    return only(methods(func, args_t))
end



##############
"""
    src_line2ir_statement_ind(irr, src_line)

Given a CodeIR, and line number from source code
determines the index of the last IR statement that occurs on that line.
"""
function src_line2ir_statement_ind(ir, src_line)
    linetable_ind = findlast(ir.linetable) do lineinfo
        lineinfo.line == src_line
    end
    statement_ind = findlast(isequal(linetable_ind), ir.codelocs)
    return statement_ind
end
