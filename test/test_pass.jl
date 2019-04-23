
using MagneticReadHead
using MagneticReadHead: HandEvalCtx, handeval_pass
using Cassette
using Test

using InteractiveUtils

# This test we are keeping around just to demonstrate how to
# check on when things go wrong
@testset "_totuple" begin
    ctx = HandEvalCtx(@__MODULE__)
    ir = @code_lowered Cassette.recurse(ctx, Base._totuple, Tuple, 20)
    #@show ir
    #@show ir.codelocs
    errors = Core.Compiler.validate_code(ir)
    @test errors == []
    res = Cassette.recurse(ctx, Base._totuple, Tuple, 20)
    @test res == (20,)
end

@testset "Normal things should not error" begin
    normal_codes = (
        (fn = sum, args=([1,2,3,4],)),
        (fn = identity, args=(302,)),
        (fn = fill!, args=([1.0, 2.0], 0.0)),
        (fn = Base._totuple, args=(Tuple, 41)),
    )
    for code in normal_codes
        ctx = HandEvalCtx(@__MODULE__)
        expected = code.fn(code.args...)
        direct_recurse = Cassette.recurse(ctx, code.fn, code.args...)
        @test expected == direct_recurse
        indirect_recurse = Cassette.recurse(ctx, () -> code.fn(code.args...))
        @test expected == indirect_recurse
    end
end

@testset "basic mutating function" begin
    function boopa!(x,y)
        x[1]=y
        return x
    end
    ctx = HandEvalCtx(@__MODULE__)
    res = Cassette.recurse(ctx, boopa!, [1,2], 3)
    @test res == [3,2]
    @testset "function calling a basic mutating function" begin
        ctx = HandEvalCtx(@__MODULE__)
        res = Cassette.recurse(ctx, ()->boopa!([1,2],3))
        @test res == [3,2]
    end
end


