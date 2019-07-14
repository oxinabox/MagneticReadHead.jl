
using MagneticReadHead
using MagneticReadHead: new_debug_ctx
using Cassette
using Test

using InteractiveUtils

# This test we are keeping around just to demonstrate how to
# check on when things go wrong
@testset "_totuple" begin
    ctx = new_debug_ctx()
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
        ctx = new_debug_ctx()
        expected = code.fn(code.args...)
        direct_recurse = Cassette.recurse(ctx, code.fn, code.args...)
        @test expected == direct_recurse
        indirect_recurse = Cassette.recurse(ctx, () -> code.fn(code.args...))
        @test expected == indirect_recurse
    end
end

function boopa!(x,y)
    x[1]=y
    return x
end

@testset "basic mutating function" begin
    ctx = new_debug_ctx()
    res = Cassette.recurse(ctx, boopa!, [1,2], 3)
    @test res == [3,2]

    @testset "function calling a basic mutating function" begin
        ctx = new_debug_ctx()
        res = Cassette.recurse(ctx, ()->boopa!([1,2],4))
        @test res == [4,2]
    end
end


@testset "let blocks in branches" begin
    # this is the breaking case that means we need to check when variables come into scope

    function danger11(x)
        if x==1
            y=1
            return x
        elseif x==2
            let
                m=2
                x+=m
            end
            return 2x
        end
        return x
    end

    ctx = new_debug_ctx()
    res = Cassette.recurse(ctx, danger11, 1)
    @test res == 1
end

@testset "Closures that modify outer content" begin
    function danger19()
        y=2
        function inner()
            h=y
            y=12
            return h
        end
        inner()
    end

    ctx = new_debug_ctx()
    res = Cassette.recurse(ctx, danger19)
    @test res == 2
end
