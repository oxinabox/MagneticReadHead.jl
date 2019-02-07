using MagneticReadHead
using MagneticReadHead: HandEvalCtx, handeval_pass
using Cassette
using Test

@testset "Basic local variablable capture" begin
    function foo(x)
        y = x+10
        z = x+20
        return (x,y,z)
    end
    
    ctx = HandEvalCtx(metadata=Dict(), pass=handeval_pass)
    #@test (10,20,30) == Cassette.recurse(ctx, ()->foo(1))
    ret = Cassette.recurse(ctx, foo, 10)
    
    @show ctx.metadata
    @show ret
    #==
    @testset "Assignments" begin
        @test ctx.metadata[:y] == 20
        @test ctx.metadata[:z] == 30
    end

    @testset "arguments" begin
        @test_broken ctx.metadata[:x] == 10
    end
    ==#
end
