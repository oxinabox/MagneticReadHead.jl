using MagneticReadHead
using Test
@testset "breadcrumbs" begin
    iob = IOBuffer()
    filename = joinpath(@__DIR__, "demo.jl")
    MagneticReadHead.breadcrumbs(iob, filename, 3)
    @test String(take!(iob)) ==
        " function eg1()\n     z = eg2(2)\n➧    eg_last(z)\n end\n \n"
end
