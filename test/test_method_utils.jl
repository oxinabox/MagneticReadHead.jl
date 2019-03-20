using Test
using MagneticReadHead: moduleof, functiontypeof, methodof

@testset "moduleof" begin
    for meth in methods(detect_ambiguities)
        @test moduleof(meth) == Test
    end
end


@testset "functiontypeof" begin
    for meth in methods(sum)
        @test functiontypeof(meth) <: typeof(sum)
    end
    for meth in methods(+)  # This includes some parametric types
        @test functiontypeof(meth) <: typeof(+)
    end
    for meth in methods(detect_ambiguities)
        @test functiontypeof(meth) <: typeof(detect_ambiguities)
    end
end

@testset "methodof" begin
    @testset "BuiltIns" begin
        @test methodof(Core.typeof) === nothing
        @test methodof(Core.typeof, 1) === nothing
    end

    @testset "Ensure no errors" begin
       @test methodof(+, 1, 1) isa Method
       @test methodof(+, 2, 2.0) isa Method
       @test methodof(+, 2.0, 2 + im) isa Method
       
       @test methodof(eps) isa Method
       @test methodof(eps, Float32) isa Method
    end

    @testset "local function no args" begin
        bar() = 1
        @test functiontypeof(methodof(bar)) == typeof(bar)
        @test moduleof(methodof(bar)) == @__MODULE__
    end


    @testset "local function 1 arg" begin
        foo(::Int) = 1
        @test functiontypeof(methodof(foo, 20)) == typeof(foo)
        @test moduleof(methodof(foo, 20)) == @__MODULE__
    end


end
