
# Function breakpoint -- break on all methods of a function
function set_breakpoint(f::F) where F
    if length(methods(f)) == 0
        @warn "A breakpoint has been set on a function that currently has no methods. It seems unlikely that this was intended" func=f
    end
    
    @eval function Cassette.overdub(ctx::MagneticCtx, fi::$(F), zargs...)
        break_action(ctx, fi, zargs...)
    end
end

# Universal Breakpoint -- break on every call
function set_breakpoint() where F
    @eval function Cassette.overdub(ctx::MagneticCtx, fi::Any, zargs...)
        break_action(ctx, fi, zargs...)
    end
end

