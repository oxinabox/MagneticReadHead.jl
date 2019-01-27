using Revise
using MagneticReadHead
using Test

using MagneticReadHead:
    filemap, pkgdata, containing_method, src_line2ir_statement_ind

@show Revise.pkgdatas #BLACKMAGIC: Remove this line and the tests fail

@testset "src_line2ir_statement_ind" begin
    ir1line = first(methods(()->1)) |> Base.uncompressed_ast
    @test src_line2ir_statement_ind(ir1line, (@__LINE__)-1) == 1
    @test src_line2ir_statement_ind(ir1line, 1000) == nothing

    ir1line2 = first(methods(()->(x=1;x*x))) |> Base.uncompressed_ast
    @test src_line2ir_statement_ind(ir1line2, (@__LINE__)-1) == 3
    

    ir2line = first(methods(()->(x=1;
                                  x*x))) |> Base.uncompressed_ast
    @test src_line2ir_statement_ind(ir2line, (@__LINE__)-1) == 3
end


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

