using MagneticReadHead
using MagneticReadHead: HandEvalCtx, handeval_pass
using Cassette
using Test

@testset "Basic local variablable capture" begin
    function foo(x)
        y = x+1
        z = x+2
        return (x,y,z)
    end
    
    ctx = HandEvalCtx(metadata=Dict(), pass=handeval_pass)
    @test (1,2,3) == Cassette.recurse(ctx, ()->foo(1))
    
    @show ctx.metadata
    @testset "Assignments" begin
        @test ctx.metadata[:y] == 2
        @test ctx.metadata[:z] == 3
    end

    @testset "arguments" begin
        @test_broken ctx.metadata[:x] == 1
    end
end
