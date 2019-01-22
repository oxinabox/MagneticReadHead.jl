
#==
Note to test implementers:
 - For reasons, all user interaction test must go in this file
 - They can't be `include`ed AFIACT, or the mocks miss some-how.
 - All other tests should go in `run_non_ui_tests.jl`
   which is included in bottom of this file.

In this file of User Interaction Tests:

 - All tests go in their own module so that breakpoints can't leak
 - They can not leak because the examples functions we break on are
   reincluded anew in each module, thus giving them distinct identity.
 
 - Do not set breakpoiints inside the apply do block. This is an anon function.
   Which for some reason makes #256 style bugs more likely.

 - The setup_ui_test_module.jl file defines things that each test module needs
==#

module CanHaveNoBreakpoints
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        p_readline = make_readline_patch([])
        p_breadcrumbs, record = make_recording_breadcrumbs_patch()

        apply([p_readline, p_breadcrumbs]) do
            @iron_debug eg1()
        end
        @test record == []
    end
end



module CanHave1Breakpoint
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        p_readline = make_readline_patch(["Continue"])
        p_breadcrumbs, record = make_recording_breadcrumbs_patch()

        set_breakpoint(eg2)
        apply([p_readline, p_breadcrumbs]) do
            @iron_debug eg1()
        end
        @test first(record).f == eg2
    end
end

module CanHave2Breakpoints
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        p_readline = make_readline_patch(["Continue", "Continue"])
        p_breadcrumbs, record = make_recording_breadcrumbs_patch()

        set_breakpoint(eg2)
        set_breakpoint(eg3)
        apply([p_readline, p_breadcrumbs]) do
            @iron_debug eg1()
        end
        @test first.(record) == [eg2, eg3]
    end
end

#########################################################


module CanHave1BreakpointThenStepIntoThenContinue
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        p_readline = make_readline_patch(["StepIn", "Continue"])
        p_breadcrumbs, record = make_recording_breadcrumbs_patch()

        set_breakpoint(eg2)
        apply([p_readline, p_breadcrumbs]) do
            @iron_debug eg1()
        end
        @test first.(record) == [eg2, eg21]
    end
end

#

###############################################
module InfluenceCallingEnviroment
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        global zzz = 10

        patch = make_readline_patch(["zzz = 20", "Continue"])

        set_breakpoint(eg2)
        apply(patch) do
            @iron_debug eg1()
        end
    end
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


#########################################

println("\n**************************************************")
include("run_non_ui_tests.jl")
