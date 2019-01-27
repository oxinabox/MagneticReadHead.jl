using Revise
using MagneticReadHead
using Test

using MagneticReadHead: filemap, pkgdata

@show Revise.pkgdatas #BLACKMAGIC: Remove this line and the tests fail

@testset "pkgdata" begin
    @test pkgdata(MagneticReadHead) !==nothing
end

@testset "filemap" begin
    @test filemap(MagneticReadHead, "utils.jl") !==nothing
    @test filemap(MagneticReadHead, "src/utils.jl") == filemap(MagneticReadHead, "utils.jl")

    @test_throws Exception filemap(MagneticReadHead, "NOT_REAL") !==nothing
end
