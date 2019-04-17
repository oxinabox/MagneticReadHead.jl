Cassette.@context HandEvalCtx

abstract type SteppingMode end
struct StepIn <: SteppingMode end
struct StepNext <: SteppingMode end
struct StepContinue <: SteppingMode end
struct StepOut <: SteppingMode end


# On the way in
child_stepping_mode(ctx::HandEvalCtx) =  child_stepping_mode(ctx.metadata.stepping_mode)
child_stepping_mode(::StepContinue) = StepContinue()
child_stepping_mode(::StepNext) = StepContinue()  # contine over the function call
child_stepping_mode(::StepIn) = StepNext()     # step within the function call
child_stepping_mode(::StepOut) = StepContinue()  # Nothing is wanted not here not there

# On the way out
parent_stepping_mode(ctx::HandEvalCtx) =  parent_stepping_mode(ctx.metadata.stepping_mode)
parent_stepping_mode(::StepContinue) = StepContinue()
parent_stepping_mode(::StepNext) = StepNext()  # Continue to next statement, which happens to be in parent
parent_stepping_mode(::StepIn) = StepNext()  # can't go in, out will have to do
parent_stepping_mode(::StepOut) = StepNext()   # This is what they want


mutable struct HandEvalMeta
    variables::LittleDict{Symbol, Any}
    eval_module::Module
    stepping_mode::SteppingMode
    breakpoint_rules::BreakpointRules
end

# TODO: Workout how we are actually going to do this in a nonglobal way
const GLOBAL_BREAKPOINT_RULES = BreakpointRules()

function HandEvalMeta(eval_module, stepping_mode)
    return HandEvalMeta(
        LittleDict{Symbol,Any}(),
        eval_module,
        stepping_mode,
        GLOBAL_BREAKPOINT_RULES
    )
end

function HandEvalCtx(eval_module, stepping_mode=StepContinue())
    ctx = HandEvalCtx(;metadata=HandEvalMeta(eval_module, stepping_mode), pass=handeval_pass)
    return Cassette.disablehooks(ctx)
end

function Cassette.overdub(::typeof(HandEvalCtx()), args...)
    error("HandEvalCtx without any had an overdub called on it. This should never happen as HandEvalCtx should never be constructed without giving them their metadata.")
end


function Cassette.overdub(ctx::HandEvalCtx, @nospecialize(f), @nospecialize(args...))
    # This is basically the epicenter of all the logic
    # We control the flow of stepping modes
    # and which methods are instrumented or not.
    method = methodof(f, args...)
    should_recurse =
        ctx.metadata.stepping_mode isa StepIn ||
        should_instrument(ctx.metadata.breakpoint_rules, method)

    if should_recurse
        if Cassette.canrecurse(ctx, f, args...)
            _ctx = HandEvalCtx(ctx.metadata.eval_module, child_stepping_mode(ctx))
            try
                return Cassette.recurse(_ctx, f, args...)
            finally
                ctx.metadata.stepping_mode = parent_stepping_mode(_ctx)
            end
        else
            @warn "Not able to enter into method." f method
            return Cassette.fallback(ctx, f, args...)
        end
    else  # !should_recurse
        return f(args...)
    end
end
