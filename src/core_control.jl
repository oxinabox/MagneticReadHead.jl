Cassette.@context HandEvalCtx

@enum SteppingMode StepIn StepNext StepContinue StepOut

const GLOBAL_BREAKPOINT_RULES = BreakpointRules()
const GLOBAL_STEPPING_MODE = Ref(StepContinue)


"""
    new_debug_ctx()::HandEvalCtx
creates a debug context, with the pass set
and extranious hooks disabled.
"""
function new_debug_ctx()
    ctx = HandEvalCtx(;pass=handeval_pass)
    return Cassette.disablehooks(ctx)
end

@inline function Cassette.overdub(ctx::HandEvalCtx, f, args...)
    # This is basically the epicenter of all the logic
    # We control the flow of stepping modes
    # and which methods are instrumented or not.
    cur_mode = GLOBAL_STEPPING_MODE[]

    should_recurse =
        cur_mode === StepIn ||
        should_instrument(GLOBAL_BREAKPOINT_RULES, f)

    if should_recurse
        if Cassette.canrecurse(ctx, f, args...)
            # Both StepOut and StepContinue means child should StepContinue
            GLOBAL_STEPPING_MODE[] = cur_mode === StepIn ? StepNext : StepContinue
            # Determine stepping mode for child
            try
                return Cassette.recurse(ctx, f, args...)
            finally
                # Determine stepping mode for parent
                child_instruction = GLOBAL_STEPPING_MODE[]
                GLOBAL_STEPPING_MODE[] =
                    child_instruction !== StepContinue ? StepNext :
                        cur_mode === StepIn ? StepContinue : cur_mode

                # if child said StepOut or StepNext or StepIn, then we shold break on next (StepNext)
                # if the child said StepContinue,
                    # if we were saying to StepIn can now StepContinue
                        # as we have completed what ever work we were doing
                    # if we were saying to StepContinue, then still want to continue
                        # (unless we hit a breakpoint where the child gave new instructions)
                    # But if we were StepOut then we still need to stepout til we return
                        # (and it gets turnd into a StepNext)
                    # and if we were StepNext then we made our child StepContinue,
                    # but we want to go StepNext ourself so have to restore that
            end
        else
            #@warn "Not able to enter into method" f args
            return Cassette.fallback(ctx, f, args...)
        end
    else  # !should_recurse
        return f(args...)
    end
end
