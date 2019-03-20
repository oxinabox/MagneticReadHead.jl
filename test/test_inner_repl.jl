using MagneticReadHead
using Test
using OrderedCollections

foo(a) = 1
foo(x,y) = 2
foo(x,y, zs...) = 3

@testset "subnames" begin
    name2arg =Dict([:x=>1, :y=>2])
    @test MagneticReadHead.subnames(name2arg, :x) == 1
    @test MagneticReadHead.subnames(name2arg, 15) == 15

    @test MagneticReadHead.subnames(name2arg, :(f(x)+y)) ==:(f(1)+2) 

end

