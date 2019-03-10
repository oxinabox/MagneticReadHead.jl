using MagneticReadHead
using MagneticReadHead: HandEvalCtx, handeval_pass
using Cassette
using Test


@testset "identity" begin
    ctx = HandEvalCtx(@__MODULE__)
    res = Cassette.recurse(ctx, ()->identity(302))
    @test res == 302
end


@testset "basic mutating function" begin
    function boopa!(x,y)
        x[1]=y
        return x
    end
    ctx = HandEvalCtx(@__MODULE__)
    res = Cassette.recurse(ctx, boopa!,[1,2],3)
    @test res == [3,2]
    @testset "function calling a basic mutating function" begin
        ctx = HandEvalCtx(@__MODULE__)
        res = Cassette.recurse(ctx, ()->boopa!([1,2],3))
        @test res == [3,2]
    end
end

testset "Normal things should not error" begin
    normal_codes = (
        (fn = fill!, args=([1.0, 2.0], 0.0)),
        (fn = sum, args=([1,2,3,4],)),
    )
    for code in normal_codes
        ctx = HandEvalCtx(@__MODULE__)
        expected = code.fn(code.args...)
        direct_recurse = Cassette.recurse(ctx, code.fn, code.args...)
        @test expected = direct_recurse
        indirect_recurse = Cassette.recurse(ctx, () -> code.fn(code.args...))
        @test expected = indirect_recurse
    end
end

##########################


@testset "Basic local variable capture" begin
    function foo(x)
        y = x+10
        z = x+20
        return (x,y,z)
    end
    
    ctx = HandEvalCtx(@__MODULE__)
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
  
    ctx = HandEvalCtx(@__MODULE__)
    @test (111,121) == Cassette.recurse(ctx, foo2)
    vars = ctx.metadata.variables
    @testset "Assignments" begin
        @test vars[:y] == 111
        @test vars[:z] == 121
    end
    
    @test length(vars) == 2  # make sure nothing else recorded.
end

####################################################################

module lockout
    function foo(x)
        y = x+12
        z = x+22
        return (x,y,z)
    end
end

@testset "Basic local variable capture from another module" begin
   
    ctx = HandEvalCtx(@__MODULE__)
    @test (50,62,72) == Cassette.recurse(ctx, lockout.foo, 50)
    vars = ctx.metadata.variables
    @testset "Assignments" begin
        @test vars[:y] == 62
        @test vars[:z] == 72
    end

    @testset "arguments" begin
        @test vars[:x] == 50
    end
    
    @test length(vars) == 3  # make sure nothing else recorded.
end

###############################################################
