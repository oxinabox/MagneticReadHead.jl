using MagneticReadHead
using Test

test_files = [
    "test_inner_repl.jl"
]

@testset "MagneticReadHead" begin
    @testset "$file" for file in test_files
        include(file)
    end
end
