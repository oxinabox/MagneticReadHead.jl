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

function iron_debug(body, _module, mode)
    ctx = HandEvalCtx(_module, mode)
    try
        return Cassette.recurse(ctx, body)
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
    :(iron_debug(()->$(esc(body)), $(__module__), StepContinue))
end

"""
    @enter the_code
Begin debugging and break on the start of the_code.
"""
macro enter(body)
    :(iron_debug(()->$(esc(body)), $(__module__), StepNext))
end

end # module
