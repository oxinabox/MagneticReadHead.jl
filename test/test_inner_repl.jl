using MagneticReadHead
using Test
using OrderedCollections

foo(a) = 1
foo(x,y) = 2
foo(x,y, zs...) = 3

@testset "argnames" begin

    @test MagneticReadHead.argnames(foo, (3.0,)) == OrderedDict([:a=>3.0])
    @test MagneticReadHead.argnames(foo, (1,2)) == OrderedDict([:x=>1, :y=>2])
    @test MagneticReadHead.argnames(foo, (1,2,3,4,5)) ==
        OrderedDict([:x=>1, :y=>2, :zs=>(3,4,5)])
end

@testset "subnames" begin
    name2arg =Dict([:x=>1, :y=>2])
    @test MagneticReadHead.subnames(name2arg, :x) == 1
    @test MagneticReadHead.subnames(name2arg, 15) == 15

    @test MagneticReadHead.subnames(name2arg, :(f(x)+y)) ==:(f(1)+2) 

end

