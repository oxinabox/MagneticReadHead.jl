module MagneticReadHead

using Base: invokelatest
using Cassette
using MacroTools
using Mocking
using OrderedCollections
using Revise: get_method, sigex2sigts, get_signature

export set_breakpoint, rm_breakpoint, @iron_debug

include("utils.jl")
include("method_utils.jl")

include("breakpoint_rules.jl")
include("core_control.jl")
include("pass.jl")

include("inner_repl.jl")
include("break_action.jl")

struct UserAbortedException <: Exception end


macro iron_debug(body)
    quote
        ctx = HandEvalCtx($(__module__), StepContinue())
        try
            Cassette.recurse(ctx, ()->$(esc(body)))
        catch err
            err isa UserAbortedException || rethrow()
            nothing
        finally
            # Disable any stepping left-over
            ctx.metadata.stepping_mode =  StepContinue()
        end

    end
end

end # module
