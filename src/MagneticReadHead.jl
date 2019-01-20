module MagneticReadHead

using Cassette
using MacroTools


export set_breakpoint, demo


Cassette.@context MagneticCtx;

# TODO Debug sessions
# This is basically the same problem as Mocking Patch Env
# But sessions should be user facing,
# Breakpoints should be attached to sessions (and sessions should wrap Context)
# Stating a new session should drop all breakpoints

function argnames(f, args)
    meth = first(methods(f, typeof.(args)))
    names = Base.method_argnames(meth)[2:end] # first is self

    return Dict(zip(names, args))
end

subnames(name2arg, x::Any) = x # fallback, for literals
subnames(name2arg, name::Symbol) = get(name2arg, name, name)
function subnames(name2arg, code::Expr)
    MacroTools.postwalk(code) do name
        # TODO Make this handle the name being on the LHS of assigment right
        get(name2arg, name, name)  # If we have a value for it swap it in. 
    end
end

function get_user_input(io=stdin)
    printstyled("iron>"; color=:light_red)
    
    ast = nothing
    line = ""
    while true
        # Very cut down REPL input code
        # https://github.com/JuliaLang/julia/blob/b8c0ec8a0a2d12533edea72749b37e6089a9d163/stdlib/REPL/src/REPL.jl#L237
        line *= readline(io)
        ast = Base.parse_input_line(line)
        ast isa Expr && ast.head == :incomplete || break
    end
    return ast
end


function break_action(f, args...)
    @info "Hit breakpoint." f

    name2arg = argnames(f, args)
    
    println("What do?")
    printstyled("Args: "; color=:light_yellow)
    println(join(keys(name2arg), ", "))
    println("Enter `Continue` to move on`")
    
    local code_ast
    while true
        code_ast = get_user_input()
        code_ast == :Continue && break
        code_ast = subnames(name2arg, code_ast)
        try
            res = eval(code_ast)
            res === nothing && continue
            display(res)
        catch err
            printstyled("ERROR: ", color=:red)
            showerror(stdout, err)
            println()
        end
    end
end

#################

function set_breakpoint(f::F) where F
    if length(methods(f)) == 0
        @warn "A breakpoint has been set on a function that currently has no methods. It seems unlikely that this was intended" func=f
    end
    
    @eval function Cassette.prehook(ctx::MagneticCtx, fi::$(F), zargs...)
        break_action(fi, zargs...)
        Cassette.recurse(ctx, fi, zargs...)
    end
end

macro debug(body)
    quote
        ctx = MagneticCtx()
        Cassette.recurse(ctx(), ()->$(esc(body)))
    end
end


end # module
