noact(ctx) = nothing

const actions = OrderedDict([
   :CC => (desc="Continue",  before_break=noact,                 after_break=noact),
   :SI => (desc="Step In",   before_break=engage_stepping_mode!, after_break=noact),
   :SN => (desc="Step Next", before_break=noact,                 after_break=engage_stepping_mode!),
   :XX => (desc="Abort",     before_break=ctx->throw(UserAbortedException()), after_break=noact),
])

function print_commands()
   printstyled("Commands: "; color=:green)
   format_command((txt, cmd)) = "$txt ($(cmd.desc))"
   println(join(format_command.(collect(actions)), ", "))
end
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
    print_commands()

    local code_ast
    while true
        code_ast = get_user_input()
        if haskey(actions, code_ast)
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
    actions[start_code_word].before_break(ctx)

    ans = Base.invokelatest(Cassette.recurse, ctx, f, args...)
    
    actions[start_code_word].after_break(ctx)

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
