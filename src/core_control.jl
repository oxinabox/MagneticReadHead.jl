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
    variables::Dict{Symbol, Any}
    eval_module::Module
    stepping_mode::SteppingMode
end

function HandEvalMeta(stepping_mode)
    return HandEvalMeta(Dict{Symbol,Any}(), Main, stepping_mode)
end

function HandEvalCtx(stepping_mode=StepIn())
    return HandEvalCtx(;metadata=HandEvalMeta(stepping_mode), pass=handeval_pass)
end


function Cassette.overdub(ctx::HandEvalCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        @show ctx  |> typeof
        _ctx = HandEvalCtx(child_stepping_mode(ctx))
        try
            return Cassette.recurse(_ctx, f, args...)
        finally
            @show _ctx  |> typeof
            ctx.metadata.stepping_mode = parent_stepping_mode(_ctx)
        end
    else
        return Cassette.fallback(ctx, f, args...)
    end
end

