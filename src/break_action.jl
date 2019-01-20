const actions = (
    :Continue,
    :StepIn,
    :StepNext,
    :Abort)

################################

function breadcrumbs(f, args)
   meth = methods(f, typeof.(args)) |> only
   printstyled("\nBreakpoint Hit: "; color=:blue)
   printstyled(string(meth); color=:light_blue)
   println()
end

function iron_repl(f, args, eval_module)
    breadcrumbs(f, args)
    
    name2arg = argnames(f, args)
    
    printstyled("Args: "; color=:light_yellow)
    println(join(keys(name2arg), ", "))
    printstyled("Commands: "; color=:green)
    println(join(actions, ", "))
    
    local code_ast
    while true
        code_ast = get_user_input()
        if code_ast ∈ actions
            return code_ast # Send the codeword back
        end
        code_ast = subnames(name2arg, code_ast)
        eval_and_display(code_ast, eval_module)
   end
end

##############################

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
    
    eval_module = ctx.metadata.eval_module

    start_code_word = iron_repl(f, args, eval_module)
    if start_code_word == :StepIn
        break_on_next_call(ctx)
    elseif start_code_word == :Abort
        throw(UserAbortedException())
    end
    
    ans = Cassette.recurse(ctx, f, args...)
    
    if start_code_word == :StepNext
        break_on_next_call(ctx)
    end

    return ans
end
