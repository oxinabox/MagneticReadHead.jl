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

function iron_debug(debugbody)
    try
        ctx = new_debug_ctx()
        return Cassette.recurse(ctx, debugbody)
    catch err
        err isa UserAbortedException || rethrow()
        nothing
    finally
        # Disable any stepping left-over
        GLOBAL_STEPPING_MODE[] =  StepContinue
    end
end

"""
    @run the_code
Run until the_code until a breakpoint is hit.
"""
macro run(body)
    quote
        iron_debug() do
            $(esc(body))
        end
    end
end



"""
    @enter the_code
Begin debugging and break on the start of the_code.
"""
macro enter(body)
    if body isa Expr && body.head==:call && body.args[1] isa Symbol
        body = MacroTools.striplines(body)
        break_target = :(InteractiveUtils.which($(body.args[1]), Base.typesof($(body.args[2:end])...)))
        quote
            set_breakpoint!($(esc(break_target)))
            try
                iron_debug() do
                    $(esc(body))
                end
            finally
                rm_breakpoint!($(esc(break_target)))
            end
        end
    else
        quote
            error("Expression too complex to `@enter`. Please use `@run` with manual breakpoint set")
        end
    end
end

end # module
