module MagneticReadHead

using Cassette
using MacroTools
using Revise: get_method, sigex2sigts, get_signature


export set_breakpoint, rm_breakpoint, @iron_debug


include("utils.jl")
include("inner_repl.jl")
include("break_action.jl")
include("breakpoints.jl")

macro iron_debug(body)
    quote
        ctx = MagneticCtx()
        Cassette.recurse(ctx, ()->$(esc(body)))
    end
end


end # module
