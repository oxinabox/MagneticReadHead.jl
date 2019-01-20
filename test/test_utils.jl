

using MagneticReadHead
using Test
@testset "only" begin
    @test MagneticReadHead.only([10]) == 10
    @test MagneticReadHead.only((15 for i in 1:1)) == 15

    @test_throws AssertionError MagneticReadHead.only([10,20])
    @test_throws AssertionError MagneticReadHead.only((i for i in 1:10))
end

