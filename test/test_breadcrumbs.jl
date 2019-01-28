using MagneticReadHead
using Test
@testset "breadcrumbs" begin
    iob = IOBuffer()
    MagneticReadHead.breadcrumbs(iob, "demo.jl", 4)
    @test String(take!(iob)) ==
        " \n \n➧function eg1()\n     z = eg2(2)\n     eg_last(z)\n"
end
