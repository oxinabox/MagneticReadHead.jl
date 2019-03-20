using MagneticReadHead
using Test

test_files = (
    "test_ui.jl",
    "test_behavour.jl",
    "test_breadcrumbs.jl",
    "test_breakpoint_rules.jl",
    "test_inner_repl.jl",
    "test_locate.jl",
    "test_method_utils.jl",
    "test_utils.jl",
    "test_pass.jl",
    "test_variable_capture.jl",
)

@testset "MagneticReadHead" begin
    @testset "$file" for file in test_files
        include(file)
    end
end

