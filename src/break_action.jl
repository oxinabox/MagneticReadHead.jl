set_stepping_mode!(mode) = metadata->metadata.stepping_mode=mode()
const actions = OrderedDict([
   :CC => (desc="Continue",  act=set_stepping_mode!(StepContinue)),
   :SI => (desc="Step In",   act=set_stepping_mode!(StepIn)),
   :SN => (desc="Step Next", act=set_stepping_mode!(StepNext)),
   :SO => (desc="Step Out",  act=set_stepping_mode!(StepOut)),
   :XX => (desc="Abort",     act=metadata->throw(UserAbortedException())),
])

function print_commands()
   printstyled("Commands: "; color=:green)
   format_command((txt, cmd)) = "$txt ($(cmd.desc))"
   println(join(format_command.(collect(actions)), ", "))
end
################################

function breadcrumbs(meth, statement_ind)
   printstyled("\nBreakpoint Hit: "; color=:blue)
   printstyled(string(meth, "\n"); color=:light_blue)
   line_num = statement_ind2src_linenum(meth, statement_ind)
   breadcrumbs(string(meth.file), line_num)
   println()
end

function breadcrumbs(file::AbstractString, line_num; nbefore=2, nafter=2)
   return breadcrumbs(stdout, file, line_num; nbefore=nbefore, nafter=nafter)
end

function breadcrumbs(io, file::AbstractString, line_num; nbefore=2, nafter=2)
   @assert(nbefore >= 0)
   @assert(nafter >= 0)
   
   all_lines = loc_for_file(file)
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
breakpoint_hit(meth, statement_ind) = nothing

function iron_repl(metadata::HandEvalMeta, meth, statement_ind)
    breakpoint_hit(meth, statement_ind)
    breadcrumbs(meth, statement_ind)
    
    printstyled("Vars: "; color=:light_yellow)
    println(join(keys(metadata.variables), ", "))
    print_commands()
    
    run_repl(metadata.variables, metadata.eval_module)
end


"""
    break_action(metadata, meth, statement_ind)

This determines what we should do when we hit a potential point to break at.
We check if we should actually break here,
and if so open up a REPL.
if not, then we continue.
"""
function break_action(metadata, meth, statement_ind)
    if !(metadata.stepping_mode isa StepNext
         || should_breakon(metadata.breakpoint_rules, meth, statement_ind)
        )
        # Only break on StepNext and actual breakpoints
        return
    end

    code_word = iron_repl(metadata, meth, statement_ind)
    actions[code_word].act(metadata)
end
