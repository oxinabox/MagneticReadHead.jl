Cassette.@context HandEvalCtx

@enum SteppingMode StepIn StepNext StepContinue StepOut
#==
# On the way in
@inline function child_stepping_mode!(ctx::HandEvalCtx)
    cur_mode = ctx.metadata.stepping_mode
    ctx.metadata.stepping_mode = cur_mode === StepIn ? StepNext : StepContinue
    @show "c", cur_mode
end

# On the way out
function parent_stepping_mode!(ctx::HandEvalCtx)
    cur_mode = ctx.metadata.stepping_mode

    ctx.metadata.stepping_mode = cur_mode === StepContinue ? StepContinue : StepNext
    @show "p", cur_mode
end
==#

mutable struct HandEvalMeta
    eval_module::Module
    stepping_mode::SteppingMode
    breakpoint_rules::BreakpointRules
end

# TODO: Workout how and if we are actually going to do this in a nonglobal way
const GLOBAL_BREAKPOINT_RULES = BreakpointRules()

function HandEvalMeta(eval_module, stepping_mode)
    return HandEvalMeta(
        eval_module,
        stepping_mode,
        GLOBAL_BREAKPOINT_RULES
    )
end

function HandEvalCtx(eval_module, stepping_mode=StepContinue)
    ctx = HandEvalCtx(;metadata=HandEvalMeta(eval_module, stepping_mode), pass=handeval_pass)
    return Cassette.disablehooks(ctx)
end

function Cassette.overdub(::typeof(HandEvalCtx()), args...)
    error("HandEvalCtx without any had an overdub called on it. This should never happen as HandEvalCtx should never be constructed without giving them their metadata.")
end


function Cassette.overdub(ctx::HandEvalCtx, f, args...)
    # This is basically the epicenter of all the logic
    # We control the flow of stepping modes
    # and which methods are instrumented or not.
    cur_mode = ctx.metadata.stepping_mode

    should_recurse =
        cur_mode === StepIn ||
        should_instrument(ctx.metadata.breakpoint_rules, f)

    if should_recurse
        if Cassette.canrecurse(ctx, f, args...)
            # Determine stepping mode for child
            ctx.metadata.stepping_mode = cur_mode === StepIn ? StepNext : StepContinue
            # Both StepOut and StepContinue means child should StepContinue
            try
                return Cassette.recurse(ctx, f, args...)
            finally
                # Determine stepping mode for parent
                child_instruction = ctx.metadata.stepping_mode
                @show child_instruction, cur_mode
                ctx.metadata.stepping_mode =
                    child_instruction !== StepContinue ? StepNext :
                        cur_mode === StepOut ?  StepOut :
                        cur_mode === StepNext ?  StepNext : StepContinue

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
            @assert f isa Core.Builtin
            #@warn "Not able to enter into method" f args
            return Cassette.fallback(ctx, f, args...)
        end
    else  # !should_recurse
        return f(args...)
    end
end
