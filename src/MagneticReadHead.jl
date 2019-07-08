module MagneticReadHead

using Base: invokelatest
using Cassette
using MacroTools
using InteractiveUtils
using CodeTracking
# We don't use Revise, but if it isn't loaded CodeTracking has issues
using Revise: Revise
using OrderedCollections

export @run, @enter


include("utils.jl")
include("method_utils.jl")

include("breakpoint_rules.jl")

include("core_control.jl")
@nospecialize
include("pass.jl")
@specialize

include("inner_repl.jl")
include("break_action.jl")
include("locate.jl")
include("breakpoints.jl")

struct UserAbortedException <: Exception end

function iron_debug(debugbody, ctx)
    try
        return Cassette.recurse(ctx, debugbody)
    catch err
        err isa UserAbortedException || rethrow()
        nothing
    finally
        # Disable any stepping left-over
        ctx.metadata.stepping_mode =  StepContinue
    end
end

"""
    @run the_code
Run until the_code until a breakpoint is hit.
"""
macro run(body)
    quote
        ctx = HandEvalCtx($(__module__), StepContinue)
        iron_debug(ctx) do
            $(esc(body))
        end
    end
end



"""
    @enter the_code
Begin debugging and break on the start of the_code.
"""
macro enter(body)
     quote
        ctx = HandEvalCtx($(__module__), StepContinue)
        iron_debug(ctx) do
            ctx.metadata.stepping_mode = StepIn
            $(esc(body))
        end
    end
end

end # module
