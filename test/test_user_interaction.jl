using Mocking
Mocking.enable(force=true)

function make_readline_patch(text_queue)
    text_state=nothing
    return @patch function readline(io)
        text, text_state = (text_state==nothing ?
            iterate(text_queue) :
            iterate(text_queue, text_state)
        )
        println(text)
        sleep(0.1)
        return text
    end
end

using Test
using MagneticReadHead

include("demo.jl")
#########################################################################

@testset "Basic" begin
    patch = make_readline_patch(["Continue"])

    apply(patch) do
        set_breakpoint(eg2)
        @test 6 == @iron_debug eg1()
    end
end


@testset "Can influence calling enviroment" begin
    global zzz = 10

    patch = make_readline_patch(["zzz = 20", "Continue"])

    apply(patch) do
        set_breakpoint(eg2)
        @iron_debug eg1()
        @test zzz == 20
    end
end


@testset "Abort" begin
    # I am dubious as to if this test is actually getting hit
    # I think may be running into a julia bug
    patch = make_readline_patch(["Abort"])

    apply(patch) do
        set_breakpoint(eg2)
        @test nothing==@iron_debug eg1()
    end
end

