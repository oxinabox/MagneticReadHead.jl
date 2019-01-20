
Cassette.@context MagneticCtx

#### Breakpoint declaration helpers

"""
    @uneval(expr)

Deletes a method that was declared via `@eval`
"""
macro uneval(expr)
    quote
        sig = get_signature($(Expr(:quote, expr)))
        sigt = only(sigex2sigts(@__MODULE__, sig))
        meth = get_method(sigt)
        Base.delete_method(meth)
    end
end

##### Breakpoint Definitions


# Function breakpoint -- break on all methods of a function
function set_breakpoint(f::F) where F
    if length(methods(f)) == 0
        @warn "A breakpoint has been set on a function that currently has no methods. It seems unlikely that this was intended" func=f
    end
    
    @eval function Cassette.overdub(ctx::MagneticCtx, fi::$(F), zargs...)
        break_action(ctx, fi, zargs...)
    end
end

function rm_breakpoint(f::F) where F
    @uneval function Cassette.overdub(ctx::MagneticCtx, fi::$(F), zargs...)
    end
end


# Universal Breakpoint -- break on every call
# TODO: Change this to be more general than just Base.Callable
function set_breakpoint()
    @eval function Cassette.overdub(ctx::MagneticCtx, fi::Base.Callable, zargs...)
        break_action(ctx, fi, zargs...)
    end
end

function rm_breakpoint()
    @uneval function Cassette.overdub(ctx::MagneticCtx, fi::Base.Callable, zargs...)
    end
end
