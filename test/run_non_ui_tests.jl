using MagneticReadHead
using Test

test_files = [
    "test_inner_repl.jl",
    "test_utils.jl",
]

@testset "MagneticReadHead" begin
    @testset "$file" for file in test_files
        include(file)
    end
end


#include("test_user_interaction.jl")
