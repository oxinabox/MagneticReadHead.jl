using Revise
using MagneticReadHead
using Test

using MagneticReadHead: filemap, pkgdata, containing_method

@show Revise.pkgdatas #BLACKMAGIC: Remove this line and the tests fail

@testset "pkgdata" begin
    @test pkgdata(MagneticReadHead) !==nothing
end

@testset "filemap" begin
    @test filemap(MagneticReadHead, "utils.jl") !==nothing
    @test filemap(MagneticReadHead, "src/utils.jl") == filemap(MagneticReadHead, "utils.jl")

    @test filemap(MagneticReadHead, "NOT_REAL") ===nothing
end


@testset "containing_method" begin
    
    meth = containing_method(MagneticReadHead, "src/locate.jl", 30)
    for ln in (29, 30, 31)
        @test meth == containing_method(MagneticReadHead, "src/locate.jl", ln)
        @test meth == containing_method(MagneticReadHead, "locate.jl", ln)
        @test meth == containing_method("locate.jl", ln)
        @test_broken meth ==
            containing_method(MagneticReadHead, "../src/locate.jl", ln)
        cd(@__DIR__) do
            @test meth == containing_method(
                MagneticReadHead,
                realpath("../src/locate.jl"),
                ln
            )
        end
    end



end
