"""
    source_paths(mod, file)

Returns list of all source files in the module with matching (partial) filename,
the filename does not have to be relative to the base directory.
It can be any partial path.
if no matching path is found then an empty list is returned
"""
function source_paths(mod, file)
    mdata = pkgfiles(mod)
    if mdata === nothing
        is_stdlib = CodeTracking.PkgId(mod).uuid === nothing
        is_stdlib && Revise.track(mod) # need to track stdlibs explictly

        Revise.revise()   # Or maybe a Revise was pending
        mdata = pkgfiles(mod)
        if mdata === nothing
            error(
                "According to CodeTracking.jl $mod is not loaded. " *
                "Revise.jl might be malfuncting."
            )
        end
    end
    mfiles = joinpath.(mdata.basedir, mdata.files)
    
    file = expanduser(file)
    if isfile(file)
        # This was something point to a real file that exists at a location
        # not just filename **somewhere**
        # It may have been a relative path, if so that is hard to deal with
        # So we will make it absolute.
        file=abspath(file)
    end
    
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

    ret = map(sigt2meth, sigs)
    return ret
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
    params = parameter_typeof(SIGT)
    func_t = params[1]
    func = func_t.instance

    args_t = Tuple{params[2:end]...}
    
    meths = methods(func, args_t)
    if length(meths) > 1
        @info "Multiple possible methods. Falling back to first" func args_t meths
    end
    return first(meths)
end



##############
"""
    src_line2ir_statement_ind(method|ir, src_line)

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

function src_line2ir_statement_ind(meth::Method, src_line)
    ir = Base.uncompressed_ast(meth)
    return src_line2ir_statement_ind(ir, src_line)
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

######################################################

"""
    loc_for_file(file)
Returns a vector of lines of code for the file.
This special cases the name `"REPL[\\d]"`, as being REPL history
and so returns that REPL history cell instead.
If for some reason the file can not be found,
this returns a vector with a single line and a message explaining as such.
"""
function loc_for_file(file::AbstractString)
    if isfile(file)
        return readlines(file)
    elseif startswith(file, "REPL[") && isdefined(Base, :active_repl)
        # extract the number from "REPL[123]"
        hist_idx = parse(Int,string(file)[6:end-1])
        hist = Base.active_repl.interface.modes[1].hist
        source_code = hist.history[hist.start_idx+hist_idx]
        return split(source_code, "\n")
    else
        return ["-- source for $file not found --"]
    end
end
