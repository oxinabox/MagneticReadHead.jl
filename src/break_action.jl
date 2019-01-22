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
    @mock breadcrumbs(f, args)
    
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



function break_action(ctx, f, args...)
    # This is effectively Cassette.overdub
    # It is called by all breakpoint overdubs
    
    ctx.metadata.do_at_next_break_start()  # Do anything we have queued
    
    eval_module = ctx.metadata.eval_module

    start_code_word = iron_repl(f, args, eval_module)
    if start_code_word == :StepIn
        engage_stepping_mode!(ctx)
    elseif start_code_word == :Abort
        throw(UserAbortedException())
    end
    
    ans = Base.invokelatest(Cassette.recurse, ctx, f, args...)
    
    if start_code_word == :StepNext
        engage_stepping_mode!(ctx)
    end

    return ans
end

function do_not_break_action(ctx, f, args...)
    ctx.metadata.do_at_next_break_start()  # Do anything we have queued
   
    if f isa Core.IntrinsicFunction
       f(args...)
    else
       Base.invokelatest(Cassette.recurse, ctx, f, args...)
    end
 end
