using Test
using MagneticReadHead
using Revise: includet
# Note: The patching used to be done with Mocking.jl
# However, that had some weird interactions between modules
# and includes
# So now the patching is done directly.
# Luckily we only have to patch some basic stuff intended only for this

"""
    make_readline_patch(text_queue)

Patches `MagneticReadHead.better_readline(io)`, such that each time it is
called it will return succecutive elements from the `text_queue`.
And will error if it is called more than it has canned responses for.
"""
function make_readline_patch(text_queue)
    @eval MagneticReadHead text_state=nothing
    @eval MagneticReadHead function better_readline(io)
        global text_state
        ret = (text_state==nothing ?
            iterate($text_queue) :
            iterate($text_queue, text_state)
        )
        ret == nothing && error("Out of programmed responses")
        text, text_state = ret
        println(text)
        sleep(0.1)
        return text
    end
end


"""
    make_recording_breakpoint_hit_patch()

Patchs the `breakpoint_hit(meth, statement_ind, variables)` method in MagneticReadHead
so that it will record what breakpoints were hit.
this function returns a reference to that record `Vector`.
"""
function make_recording_breakpoint_hit_patch()
    record = []
    @eval MagneticReadHead function breakpoint_hit(meth, statement_ind, variables)
        push!($record, (
            f=MagneticReadHead.functiontypeof(meth).instance,
            method=meth,
            statement_ind=statement_ind,
            variables=variables
        ))
    end
    return record
end

"""
    reset_patched_functions()

Patchs `breakpoint_hit` and `better_readline` back to their original state.
"""
function reset_patched_functions!()
    @eval MagneticReadHead function breakpoint_hit(meth, statement_ind)
        return nothing
    end

    @eval MagneticReadHead function better_readline(io)
        # This is not technically the same as the better_readline defined in utils
        # but we will only be doing automated tests so that doesn't matter.
        return readline(io)
    end
end

includet("demo.jl")
