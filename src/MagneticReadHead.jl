module MagneticReadHead

using Base: invokelatest
using Cassette
using MacroTools
using OrderedCollections
using InteractiveUtils
using CodeTracking
# We don't use Revise, but if it isn't loaded CodeTracking has issues
using Revise: Revise

export @iron_debug 

include("utils.jl")
include("method_utils.jl")

include("breakpoint_rules.jl")
include("core_control.jl")
include("pass.jl")

include("inner_repl.jl")
include("break_action.jl")
include("locate.jl")
include("breakpoints.jl")

struct UserAbortedException <: Exception end


macro iron_debug(body)
    quote
        ctx = HandEvalCtx($(__module__), StepContinue())
        try
            return Cassette.recurse(ctx, ()->$(esc(body)))
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
