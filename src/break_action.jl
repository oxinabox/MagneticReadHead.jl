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

function breadcrumbs(file::AbstractString, line_num; nbefore=2, nafter=2)
   return breadcrumbs(stdout, file, line_num; nbefore=nbefore, nafter=nafter)
end

function breadcrumbs(io, file::AbstractString, line_num; nbefore=2, nafter=2)
   @assert(nbefore >= 0)
   @assert(nafter >= 0)
   
   all_lines = readlines(file)
   first_line_num = max(1, line_num - nbefore)
   last_line_num = min(length(all_lines), line_num + nafter)
   
   for ln in first_line_num:last_line_num
      line = all_lines[ln]
      if ln == line_num
         line = "➧" * line
         color = :cyan
      else
         line = " " * line
         color = :light_green
         if ln ∈ (first_line_num, last_line_num)
            color = :light_black
         end
      end
      printstyled(io, line, "\n"; color=color)
   end
end


# this function exists only for mocking so we can test it.
breakpoint_hit(f, args) = nothing

###########
function iron_repl(f, args, eval_module)
    @mock breakpoint_hit(f, args)
    breadcrumbs(f, args)
    
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
