using MagneticReadHead
using Test

test_files = [
    "test_inner_repl.jl",
    "test_utils.jl",
    "test_breakpoints.jl",
    "test_behavour.jl",
]

@testset "MagneticReadHead" begin
    @testset "$file" for file in test_files
        include(file)
    end
end

