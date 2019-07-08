"""
    subnames(name2var, ast)

Subsitute the values from the dict `name2var`
into the ast,
where ever the keys (names) occur.
"""
subnames(name2var, x::Any) = x # fallback, for literals
subnames(name2var, name::Symbol) = get(name2var, name, name)
function subnames(name2var, code::Expr)
    MacroTools.postwalk(code) do name
        # TODO Make this handle the name being on the LHS of assigment right
        get(name2var, name, name)  # If we have a value for it swap it in.
    end
end


###############

function get_user_input(io=stdin)
    printstyled("debug> "; color=:light_red)

    ast = nothing
    line = ""
    while true
        # Very cut down REPL input code
        # https://github.com/JuliaLang/julia/blob/b8c0ec8a0a2d12533edea72749b37e6089a9d163/stdlib/REPL/src/REPL.jl#L237
        line *= better_readline(io)
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
    end
    println()
end


function run_repl(name2var, eval_module)
    local code_ast
    while true
        code_ast = get_user_input()
        if haskey(actions, code_ast)
            return code_ast # Send the codeword back
        end
        code_ast = subnames(name2var, code_ast)
        eval_and_display(code_ast, eval_module)
   end
end
