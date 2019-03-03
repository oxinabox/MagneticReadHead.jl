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
        if meth == nothing
            @info "Method not found, thus not removed."
        else
            Base.delete_method(meth)
        end
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

##############################################################################################################
# Stepping Mode
#
# Universal Breakpoint -- break on every call

function engage_stepping_mode!(metadata)
    metadata.stepping_mode=true
    set_breakpoint_for_every_call()

    metadata.do_at_next_break_start = function()
        disengage_stepping_mode!(metadata)
        metadata.do_at_next_break_start = () -> nothing # Remove myself
        return nothing
    end
end

function disengage_stepping_mode!(metadata)
    metadata.stepping_mode==false && return
    metadata.stepping_mode=false
    rm_breakpoint_for_every_call()
end

function set_breakpoint_for_every_call()
    @eval function Cassette.overdub(ctx::MagneticCtx, fi, zargs...)
        if fi isa Core.Builtin || ctx.metadata.stepping_mode == false #HACK: double check incase cassette is 256ing
            do_not_break_action(ctx, fi, zargs...) # Do not mess with Intrinsics
        else
            break_action(ctx, fi, zargs...)
        end
    end
end

function rm_breakpoint_for_every_call()
    @uneval function Cassette.overdub(ctx::MagneticCtx, fi, zargs...)
    end
end
