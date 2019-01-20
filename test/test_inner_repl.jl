using MagneticReadHead
using Test

foo(x,y) = 2
foo(a) = 1

@testset "argnames" begin

    @test MagneticReadHead.argnames(foo, (1,2)) == Dict([:x=>1, :y=>2])
    @test MagneticReadHead.argnames(foo, (3.0,)) == Dict([:a=>3.0])
end

@testset "subnames" begin
    name2arg =Dict([:x=>1, :y=>2])
    @test MagneticReadHead.subnames(name2arg, :x) == 1
    @test MagneticReadHead.subnames(name2arg, 15) == 15

    @test MagneticReadHead.subnames(name2arg, :(f(x)+y)) ==:(f(1)+2) 

end

