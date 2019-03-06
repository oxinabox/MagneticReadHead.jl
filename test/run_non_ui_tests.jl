using MagneticReadHead
using Test

test_files = [
    "test_inner_repl.jl",
    "test_utils.jl",
    "test_method_utils.jl",
    "test_breakpoint_rules.jl",
    "test_behavour.jl",
    "test_variable_capture.jl",
]

@testset "MagneticReadHead" begin
    @testset "$file" for file in test_files
        include(file)
    end
end

