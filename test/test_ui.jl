include("setup_ui_test_module.jl")

clear_breakpoints!(); clear_nodebugs!()
#@testset "No breakpoints" begin
    make_readline_patch([])
    record = make_recording_breakpoint_hit_patch()

    @iron_debug eg1()
    @test record == []
#end

#@testset "1 breakpoint" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()
    set_breakpoint!(eg2)

    @show list_breakpoints()
    @iron_debug eg1()
    @test first(record).f == eg2
#end

clear_breakpoints!(); clear_nodebugs!()
#@testset "Two breakpoints" begin
    make_readline_patch(["CC", "CC"])
    record = make_recording_breakpoint_hit_patch()
    set_breakpoint!(eg2)
    set_breakpoint!(eg3)
    @iron_debug eg1()
    @test first.(record) == [eg2, eg3]
#end

###################################################
clear_breakpoints!(); clear_nodebugs!()
#@testset "No breakpoints, With no instrumenting of Base" begin
    make_readline_patch([])
    record = make_recording_breakpoint_hit_patch()
    set_nodebug!(Base)
    @iron_debug eg1()
    @test record == []
#end
###########################

clear_breakpoints!(); clear_nodebugs!()
#@testset "breakpoint by file and linenum" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()

    set_breakpoint!("demo.jl", 9)
    @test !isempty(list_breakpoints())
    @iron_debug eg1()
    @test first.(record) == [eg2]
#end


#########################################################
 # Stepping Mode

clear_breakpoints!(); clear_nodebugs!()
#@testset "step in" begin
    make_readline_patch(["SI", "CC"])
    record = make_recording_breakpoint_hit_patch()

    set_breakpoint!(eg2)
    @iron_debug eg1()
    @test first.(record) == [eg2, eg21]
#end

clear_breakpoints!(); clear_nodebugs!()
#@testset "step out" begin
    set_breakpoint!(eg2)
    make_readline_patch(["SO", "CC"])
    record = make_recording_breakpoint_hit_patch()

    @iron_debug eg1()
    @test first.(record) == [eg2, eg1]
#end


clear_breakpoints!(); clear_nodebugs!()
#@testset "step next" begin
    set_breakpoint!(eg2)
    make_readline_patch(["SN", "SN", "CC"])
    record = make_recording_breakpoint_hit_patch()

    @iron_debug eg1()
    @test first.(record) == [eg2, eg2, eg2]
#end


###############################################
clear_breakpoints!(); clear_nodebugs!()
#@testset "Influence calling enviroment" begin
    global zzz = 10
    make_readline_patch(["zzz = 20", "CC"])

    set_breakpoint!(eg2)
    @iron_debug eg1()
    @test zzz==20
#end


clear_breakpoints!(); clear_nodebugs!()
#@testset "Abort" begin
    make_readline_patch(["XX"])

    set_breakpoint!(eg2)
    @test nothing==@iron_debug eg1()
#end

########################################
# Variables
function var_demo1(x)
    local y
    z=2x
    y=z
    z=1
end

clear_breakpoints!(); clear_nodebugs!()
#@testset "Variables stepping" begin
    set_breakpoint!(var_demo1)
    make_readline_patch(["SN", "SN", "SN", "CC"])
    record = make_recording_breakpoint_hit_patch()
    @iron_debug var_demo1(5)

    @test record[1].variables == LittleDict(:x=>5)
    @test record[2].variables == LittleDict(:x=>5, :z=>10)
    @test record[3].variables == LittleDict(:x=>5, :z=>10, :y=>10)
    @test record[4].variables == LittleDict(:x=>5, :y=>10, :z=>1)
#end

#######
# Done
reset_patched_functions!()
println("\tUser interaction tests complete")
