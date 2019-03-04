using Test
using MagneticReadHead: moduleof, functiontypeof

@testset "moduleof" begin
    for meth in methods(detect_ambiguities)
        @test moduleof(meth) == Test
    end
end


@testset "functiontypeof" begin
    for meth in methods(sum)
        @test functiontypeof(meth) <: typeof(sum)
    end
    for meth in methods(detect_ambiguities)
        @test functiontypeof(meth) <: typeof(detect_ambiguities)
    end
end
