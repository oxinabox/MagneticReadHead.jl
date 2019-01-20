module MagneticReadHead

using Cassette
using MacroTools
using OrderedCollections
using Revise: get_method, sigex2sigts, get_signature


export set_breakpoint, rm_breakpoint, @iron_debug


include("utils.jl")
include("inner_repl.jl")
include("break_action.jl")
include("breakpoints.jl")


mutable struct MagneticMetadata
    do_at_next_break_start::Any
end
MagneticMetadata() = MagneticMetadata(()->nothing)

macro iron_debug(body)
    quote
        ctx = Cassette.disablehooks(MagneticCtx(;metadata=MagneticMetadata()))
        Cassette.recurse(ctx, ()->$(esc(body)))
    end
end

end # module
