
#==
Note to test implementers:
 - All tests go in their own module so that breakpoints can't leak
 - They can not leak because the examples functions we break on are
   reincluded anew in each module, thus giving them distinct identity.
 
 - Do not set breakpoiints inside the apply do block. This is an anon function.
   Which for some reason makes #256 style bugs more likely.

 - The setup_ui_test_module.jl file defines things that each test module needs
==#


module BasicUI
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        patch = make_readline_patch(["Continue"])

        set_breakpoint(eg2)
        apply(patch) do
            @test 6 == @iron_debug eg1()
        end
    end
end

module InfluenceCallingEnviroment
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        global zzz = 10

        patch = make_readline_patch(["zzz = 20", "Continue"])

        set_breakpoint(eg2)
        apply(patch) do
            @show zzz
            @iron_debug eg1()
            @test zzz == 20
        end
        @show zzz
    end
    @show zzz
end


module Abort
    include("setup_ui_test_module.jl")
    
    @testset "$(@__MODULE__)" begin
        patch = make_readline_patch(["Abort"])

        set_breakpoint(eg2)
        apply(patch) do
            @test nothing==@iron_debug eg1()
        end
    end
end
