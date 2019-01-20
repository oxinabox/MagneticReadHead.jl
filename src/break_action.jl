
function iron_repl(f, args)
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

function break_action(ctx, f, args...)
    # This is effectively Cassette.overdub
    # It is called by all breakpoint overdubs
    iron_repl(f, args)
    ans = Cassette.recurse(ctx, f, args...)
    return ans
end
