"""
    argnames(f, args)

For a function `f` with the arguments `args`
returns a dict mapping the names of the arguments to their values.
"""
function argnames(f, args)
    meth = only(methods(f, typeof.(args)))
    names = Base.method_argnames(meth)[2:end] # first is self
    
    if length(names) < length(args)
        main_args = args[1:length(names)-1]
        var_args = args[length(names):end]
        args = [main_args..., var_args]
    end
    @assert length(names) == length(args)
    return OrderedDict(zip(names, args))
end

"""
    subnames(name2arg, ast)

Subsitute the values from the dict `name2arg`
into the ast,
where ever the keys (names) occur.
"""
subnames(name2arg, x::Any) = x # fallback, for literals
subnames(name2arg, name::Symbol) = get(name2arg, name, name)
function subnames(name2arg, code::Expr)
    MacroTools.postwalk(code) do name
        # TODO Make this handle the name being on the LHS of assigment right
        get(name2arg, name, name)  # If we have a value for it swap it in. 
    end
end


###############

function get_user_input(io=stdin)
    printstyled("iron>"; color=:light_red)
    
    ast = nothing
    line = ""
    while true
        # Very cut down REPL input code
        # https://github.com/JuliaLang/julia/blob/b8c0ec8a0a2d12533edea72749b37e6089a9d163/stdlib/REPL/src/REPL.jl#L237
        line *= @mock readline(io)
        length(line) == 0 && break
        ast = Base.parse_input_line(line)
        ast isa Expr && ast.head == :incomplete || break
    end
    return ast
end


function eval_and_display(code_ast, eval_module)
    try
        res = eval_module.eval(code_ast)
        if res != nothing
            display(res)
        end
    catch err
        printstyled("ERROR: ", color=:red)
        showerror(stdout, err)
        println()
    end
end


