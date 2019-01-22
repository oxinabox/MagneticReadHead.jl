using MagneticReadHead
using Test
using Cassette

foo(x) = 1
foo(x,y) = 2


macro before_after_test(set_thing, unset_thing)
    quote
        overdubs_before_set = methods(Cassette.overdub) |> collect
        $(esc(set_thing))
        overdubs_after_set = methods(Cassette.overdub) |> collect
        $(esc(unset_thing))
        overdubs_after_rm = methods(Cassette.overdub) |> collect
    
        @test overdubs_before_set != overdubs_after_set
        @test overdubs_after_set != overdubs_after_rm
        @test overdubs_after_rm == overdubs_before_set
    end
end

@testset "Add and Remove" begin
        
    @testset "Universal Breakpoint" begin
        # Internal
        @before_after_test(
            MagneticReadHead.set_breakpoint_for_every_call(),
            MagneticReadHead.rm_breakpoint_for_every_call(),
        )
    end
         
    @testset "Function Breakpoint" begin
        @before_after_test(set_breakpoint(foo), rm_breakpoint(foo))
        @before_after_test(set_breakpoint(+), rm_breakpoint(+))
    end
    
end
