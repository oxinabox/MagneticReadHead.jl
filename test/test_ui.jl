#==
In this file of User Interaction Tests:

 - All tests go in their own module so that breakpoints can't leak
 - They can not leak because the examples functions we break on are
   reincluded anew in each module, thus giving them distinct identity.
 
 - The setup_ui_test_module.jl file defines things that each test module needs
==#

module CanHaveNoBreakpoints
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        make_readline_patch([])
        record = make_recording_breakpoint_hit_patch()

        @iron_debug eg1()
        @test record == []
    end
end

module CanHave1Breakpoint
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        make_readline_patch(["CC"])
        record = make_recording_breakpoint_hit_patch()

        set_breakpoint!(eg2)
        @iron_debug eg1()
        @test first(record).f == eg2
    end
end

module CanHave2Breakpoints
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        make_readline_patch(["CC", "CC"])
        record = make_recording_breakpoint_hit_patch()

        set_breakpoint!(eg2)
        set_breakpoint!(eg3)
        @iron_debug eg1()
        @test first.(record) == [eg2, eg3]
    end
end

#########################################################
 # Stepping Mode

module CanHave1BreakpointThenStepInThenContinue
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        make_readline_patch(["SI", "CC"])
        record = make_recording_breakpoint_hit_patch()

        set_breakpoint!(eg2)
        @iron_debug eg1()
        @test first.(record) == [eg2, eg21]
    end
end

 
###############################################
module CanInfluenceCallingEnviroment
    include("setup_ui_test_module.jl")

    @testset "$(@__MODULE__)" begin
        global zzz = 10
        make_readline_patch(["zzz = 20", "CC"])

        set_breakpoint!(eg2)
        @iron_debug eg1()
        @test zzz==20
    end
end


module Abort
    include("setup_ui_test_module.jl")
    
    @testset "$(@__MODULE__)" begin
        make_readline_patch(["XX"])

        set_breakpoint!(eg2)
        @test nothing==@iron_debug eg1()
    end
end


include("setup_ui_test_module.jl")
reset_patched_functions!()
println("\tUser interaction tests complete")
