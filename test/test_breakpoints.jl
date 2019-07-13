using MagneticReadHead
using Test

@testset "Should be able to add and remove breakpoints" begin
    @test length(set_breakpoint!(Test)) == 1
    @test length(rm_breakpoint!(Test)) == 0

    @test length(set_uninstrumented!(Test)) == 1
    @test length(rm_uninstrumented!(Test)) == 0
end
