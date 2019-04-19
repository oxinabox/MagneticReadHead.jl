using Test
using InteractiveUtils
using MagneticReadHead: moduleof, functiontypeof, DispatchAttempt, accepts


# Define an extra method of eps in this module, so we can test methods of
Base.eps(::typeof(moduleof)) = "dummy"

@testset "moduleof" begin
    for meth in methods(detect_ambiguities)
        @test moduleof(meth) == Test
    end

    # We define a verion of eps in this module
    # but we expect that it is still counted as being in `Base`
    for meth in methods(eps)
        @test moduleof(meth) == Base
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

@testset "DispatchAttempt" begin
    @testset "BuiltIns" begin
        meth_not = @which(!true)
        @test accepts(meth_not, DispatchAttempt(Core.typeof, tuple())) === false
        @test accepts(meth_not, DispatchAttempt(Core.typeof, (1,))) === false
    end


    @testset "accepts" begin
        function method_accepts(meth, f, args...)
            da = DispatchAttempt(f, args)
            return accepts(meth, da)
        end
        function check_accepts(f, args...)
            default_meth = @which f(args...)
            return method_accepts(default_meth, f, args...)
        end

        @test check_accepts(+, 1, 1)
        @test check_accepts(+, 2, 2.0)
        @test check_accepts(+, 2.0, 2 + im)
        @test !method_accepts((@which 1+1), +, 'a', 'b')  # wrong method
        @test !method_accepts((@which 1+1), *, 'a', 'b')  # wrong method

        @test check_accepts(eps)  # No argument
        @test check_accepts(eps, Float32)  #DataType as argument
        @test !method_accepts((@which eps(Float32)), Int64) # wrong method

        @testset "Constructor" begin
            @test check_accepts(Int, true)
            @test check_accepts(Int, 'c')
            @test !method_accepts((@which Int(true)), 'c') # wrong method
        end

        @testset "Closure" begin
            bar = 24
            foo(x::Int) = x*bar
            @test check_accepts(foo, 5)
            @test !method_accepts((@which foo(5)), foo, 'c')
        end
    end

    
end
