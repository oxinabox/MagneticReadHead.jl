
const actions = OrderedDict([
    :Continue => nothing,
    :StepIn => nothing,
    :StepNext => nothing
])

################################

function iron_repl(f, args)
    @info "Hit breakpoint." f
    name2arg = argnames(f, args)
    
    println("What do?")
    printstyled("Args: "; color=:light_yellow)
    println(join(keys(name2arg), ", "))
    printstyled("Commands: "; color=:green)
    println(join(keys(actions), ", "))
    
    local code_ast
    while true
        code_ast = get_user_input()
        if haskey(actions, code_ast)
            return code_ast # Send the codeword back
        end
        code_ast = subnames(name2arg, code_ast)
        eval_and_display(code_ast)
   end
end


function break_on_next_call(ctx)
    set_breakpoint() # Set all break-points
    ctx.metadata.do_at_next_break_start = ()->rm_breakpoint()
    return nothing
end



function break_action(ctx, f, args...)
    # This is effectively Cassette.overdub
    # It is called by all breakpoint overdubs
    
    ctx.metadata.do_at_next_break_start()  # Do anything we have queued
    ctx.metadata.do_at_next_break_start = ()->nothing  # whipe it


    start_code_word = iron_repl(f, args)
    if start_code_word == :StepIn
        break_on_next_call(ctx)
    end
    
    ans = Cassette.recurse(ctx, f, args...)
    
    if start_code_word == :StepNext
        break_on_next_call(ctx)
    end

    return ans
end
