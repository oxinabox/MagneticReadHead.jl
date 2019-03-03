noact(metadata) = nothing

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
   printstyled(string(meth); color=:light_blue)
   printstyled("  ($statement_ind)"; color=:blue)
   println()
end

function iron_repl(metadata::HandEvalMeta, meth, statement_ind)
    @mock breadcrumbs(meth, statement_ind)
    
    printstyled("Vars: "; color=:light_yellow)
    println(join(keys(metadata.variables), ", "))
    print_commands()
    
    run_repl(metadata.variables, metadata.eval_module)
end
##############################


function break_action(metadata, meth, statement_ind)
    # This is effectively Cassette.overdub
    # It is called by all breakpoint overdubs
    if !(metadata.stepping_mode isa StepNext)
        # Only break on StepNext
        return
    end

    code_word = iron_repl(metadata, meth, statement_ind)
    actions[code_word].act(metadata)
end
