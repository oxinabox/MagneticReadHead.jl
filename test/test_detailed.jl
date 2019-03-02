using MagneticReadHead
using MagneticReadHead: HandEvalCtx, handeval_pass
using Cassette
using Test

@testset "Basic local variable capture" begin
    function foo(x)
        y = x+10
        z = x+20
        return (x,y,z)
    end
    
    ctx = HandEvalCtx()
    @test (10,20,30) == Cassette.recurse(ctx, foo, 10)
    vars = ctx.metadata.variables
    @testset "Assignments" begin
        @test vars[:y] == 20
        @test vars[:z] == 30
    end

    @testset "arguments" begin
        @test vars[:x] == 10
    end
    
    @test length(vars) == 3  # make sure nothing else recorded.
end

@testset "Basic local variable capture, no param" begin
    function foo2()
        y = 111
        z = y + 10
        return (y,z)
    end
  
    ctx = HandEvalCtx()
    @test (111,121) == Cassette.recurse(ctx, foo2)
    vars = ctx.metadata.variables
    @testset "Assignments" begin
        @test vars[:y] == 111
        @test vars[:z] == 121
    end
    
    @test length(vars) == 2  # make sure nothing else recorded.
end
