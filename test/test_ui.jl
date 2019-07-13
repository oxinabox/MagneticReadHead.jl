include("setup_ui_test_module.jl")

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "No breakpoints" begin
    make_readline_patch([])
    record = make_recording_breakpoint_hit_patch()

    @run eg1()
    @test record == []
#end

#@testset "1 breakpoint" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()
    set_breakpoint!(eg2)

    @show list_breakpoints()
    @run eg1()
    @test first(record).f == eg2
#end

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "Two breakpoints" begin
    make_readline_patch(["CC", "CC"])
    record = make_recording_breakpoint_hit_patch()
    set_breakpoint!(eg2)
    set_breakpoint!(eg3)
    @run eg1()
    @test first.(record) == [eg2, eg3]
#end

###################################################
clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "No breakpoints, With no instrumenting of Base" begin
    make_readline_patch([])
    record = make_recording_breakpoint_hit_patch()
    set_uninstrumented!(Base)
    @run eg1()
    @test record == []
#end
###########################

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "breakpoint by file and linenum" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()

    set_breakpoint!("demo.jl", 9)
    @test !isempty(list_breakpoints())
    @run eg1()
    @test first.(record) == [eg2]
#end


#########################################################
 # Stepping Mode

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "step in" begin
    make_readline_patch(["SI", "CC"])
    record = make_recording_breakpoint_hit_patch()

    set_breakpoint!(eg2)
    @run eg1()
    @test first.(record) == [eg2, eg21]
#end

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "step out" begin
    set_breakpoint!(eg2)
    make_readline_patch(["SO", "CC"])
    record = make_recording_breakpoint_hit_patch()

    @run eg1()
    @test first.(record) == [eg2, eg1]
#end


clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "step next" begin
    set_breakpoint!(eg2)
    make_readline_patch(["SN", "SN", "CC"])
    record = make_recording_breakpoint_hit_patch()

    @run eg1()
    @test first.(record) == [eg2, eg2, eg2]
#end

###############################################

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "@enter" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()

    @enter eg1()
    @test first.(record) == [eg1]
    @test isempty(list_breakpoints())
#end

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "@enter, too complex" begin
    make_readline_patch(["CC"])
    record = make_recording_breakpoint_hit_patch()

    @test_throws ErrorException (@enter (()->eg1())())
    @test isempty(list_breakpoints())
#end



###############################################
clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "Influence calling enviroment" begin
    global zzz = 10
    make_readline_patch(["zzz = 20", "CC"])

    set_breakpoint!(eg2)
    @run eg1()
    @test zzz==20
#end


clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "Abort" begin
    make_readline_patch(["XX"])

    set_breakpoint!(eg2)
    @test nothing==@run eg1()
#end

########################################
# Variables
function var_demo1(x)
    local y
    z=2x
    y=z
    z=1
end

clear_breakpoints!(); clear_uninstrumenteds!()
#@testset "Variables stepping" begin
    set_breakpoint!(var_demo1)
    make_readline_patch(["SN", "SN", "SN", "CC"])
    record = make_recording_breakpoint_hit_patch()
    @run var_demo1(5)

    @test record[1].variables == LittleDict(:x=>5)
    @test record[2].variables == LittleDict(:x=>5, :z=>10)
    @test record[3].variables == LittleDict(:x=>5, :z=>10, :y=>10)
    @test record[4].variables == LittleDict(:x=>5, :y=>10, :z=>1)
#end

#######
# Done
reset_patched_functions!()
println("\tUser interaction tests complete")
