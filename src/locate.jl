"""
    source_paths(mod, file)

Returns list of all source files in the module with matching (partial) filename,
the filename does not have to be relative to the base directory.
It can be any partial path.
if no matching path is found then an empty list is returned
"""
function source_paths(mod, file)
    mdata = pkgfiles(mod)
    mfiles = joinpath.(mdata.basedir, mdata.files)
    
    file = expanduser(file)
    if !isabspath(file)
        # We do not need it to be absolute
        # But we do want it to start with a "/" if it isn't
        # So we can use `endswith` to check that it matchs one of the paths
        # that we know about, without worry of matching part of a filename
        file = "/" * file
    end
    matched_inds = map(mfile->endswith(mfile, file), mfiles)
     
    return mfiles[matched_inds]
end


"""
    containing_methods([module], filename, linenum)

Returns the methods within which the provided line number
in the given file, occurs.
Returns an empty list on no match.

If the module is not provided, then all modules loaded
will be searched for a file with that name that has a function over that line.

Filenames can be absolute, or partial.
E.g. `/home/user1/dev/MyMod/src/helpers/utils.jl`,
`helpers/utils.jl` or `utils.jl` are all acceptable.

If it is ambigious, then all matching methods in all file will be returned.
"""
function containing_methods(mod, file, linenum)
    paths = source_paths(mod, file)
    isempty(paths) && return Method[]
    sigs = mapreduce(vcat, paths) do path
        signatures_at(path, linenum)
    end
    # TODO: workout  a way to round-forward as the signatures_at
    # only matches to
    # statement within the functions body, not from the line it is "declared"
    # or any intervening whitespace. It also doesn't match to the `end` line.
    
    return map(sigt2meth, sigs)
end

function containing_methods(file, linenum)
    #TODO: raise issue on CodeTracking.jl to expose public way
    # to get list of all loaded modules
    pkgids = keys(CodeTracking._pkgfiles)
    isempty(pkgids) && return Method[]
    mapreduce(vcat, pkgids) do pkgid
        containing_methods(pkgid, file, linenum)
    end
end

function sigt2meth(::Type{SIGT})::Method where SIGT
    params = SIGT.parameters
    func_t = params[1]
    func = func_t.instance

    args_t = Tuple{params[2:end]...}

    return only(methods(func, args_t))
end



##############
"""
    src_line2ir_statement_ind(ir, src_line)

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

"""
    ir_statement_ind2src_linenum(method|ir, statement_ind)

Given a CodeIR, and a statement index (code loc) within that method's IR
determines the line in the source code wher that occurs.
"""
function statement_ind2src_linenum(ir, statement_ind)
    # handle boundry cases
    statement_ind < 0 && throw(ArgumentError("Can not have negative statement index"))
    # We use 0 for "before first statement".
    statement_ind == 0 && return before_body_linenum(ir)

    code_loc = ir.codelocs[statement_ind]
    return ir.linetable[code_loc].line
end

function statement_ind2src_linenum(meth::Method, statement_ind)
    ir = Base.uncompressed_ast(meth)
    return statement_ind2src_linenum(ir, statement_ind)
end
    
"""
    before_body_linenum(ir)
Returns the line number of the line before the first line in the body of the ir.
"""
function before_body_linenum(ir)
    first_lineinfo = ir.linetable[first(ir.codelocs)]
    return first_lineinfo.line - 1
end
