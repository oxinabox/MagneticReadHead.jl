module MagneticReadHead

using Base: invokelatest
using Cassette
using MacroTools
using Mocking
using OrderedCollections
using Revise: get_method, sigex2sigts, get_signature

export set_breakpoint, rm_breakpoint, @iron_debug

include("utils.jl")

include("core_control.jl")
include("pass.jl")

include("inner_repl.jl")
include("breakpoints.jl")
include("break_action.jl")

struct UserAbortedException <: Exception end

mutable struct MagneticMetadata
    eval_module::Module
    do_at_next_break_start::Any
    stepping_mode::Bool
end
MagneticMetadata(eval_module) = MagneticMetadata(eval_module, ()->nothing, false)

macro iron_debug(body)
    quote
        ctx = Cassette.disablehooks(MagneticCtx(;metadata=MagneticMetadata($(__module__))))
        try
            Cassette.recurse(ctx, ()->$(esc(body)))
        catch err
            @show err
            err isa UserAbortedException || rethrow()
            nothing
        finally
            disengage_stepping_mode!(ctx)
        end

    end
end

end # module
