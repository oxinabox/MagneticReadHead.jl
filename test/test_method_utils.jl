using Test
using InteractiveUtils
using MagneticReadHead: moduleof, functiontypeof


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


    for meth in methods(Vector)  # this is a UnionAll
        @test moduleof(meth) == Core
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
