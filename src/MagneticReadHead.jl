module MagneticReadHead

using Cassette
using MacroTools


export set_breakpoint, demo


Cassette.@context MagneticCtx;

include("utils.jl")
include("inner_repl.jl")
include("break_action.jl")
include("breakpoints.jl")

macro debug(body)
    quote
        ctx = MagneticCtx()
        Cassette.recurse(ctx(), ()->$(esc(body)))
    end
end


end # module
