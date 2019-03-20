using MagneticReadHead: should_instrument, should_breakon, Rule, BreakpointRules
using Test

@testset "breakon rules" begin
    # Helper for defining rules during tests
    borule(args...) = BreakpointRules(Rule[], [Rule(args...)])
    
    @testset "module" begin
        # I don't really think this is useful, but it does work
        rules = borule(Iterators)
        @test should_breakon(rules, first(methods(Iterators.drop)), 0)
        @test !should_breakon(rules, first(methods(Iterators.drop)), 2)
        @test should_breakon(rules, first(methods(Iterators.flatten)), 0)
        @test !should_breakon(borule(Iterators), first(methods(Iterators.flatten)), 1)
    end

    @testset "Function" begin
        rules = borule(eps)
        for meth in methods(eps)
            @test should_breakon(rules, meth, 0)
            @test !should_breakon(rules, meth, 1)
            @test !should_breakon(rules, meth, 2)
        end
    end
    
    @testset "Method" begin
        meths  = collect(methods(pwd))
        rules = borule(meths[1])
        @test should_breakon(rules, meths[1], 0)
        @test !should_breakon(rules, meths[1], 1)
        for meth in meths[2:end]
            @test !should_breakon(rules, meth, 0)
        end
    end

    @testset "Method + statement number" begin
        # Not going to test ever other permutation of x + statement number
        # This is the one that matters, method + statement number
        # is what a line number breakpoint will become
        meths  = collect(methods(pwd))
        rules = borule(meths[1], 2)
        @test !should_breakon(rules, meths[1], 0)
        @test !should_breakon(rules, meths[1], 1)
        @test should_breakon(rules, meths[1], 2)
        @test !should_breakon(rules, meths[1], 3)

        for meth in meths[2:end]
            @test !should_breakon(rules, meth, 0)
            @test !should_breakon(rules, meth, 2)
        end
    end




end

@testset "default" begin
    rules = BreakpointRules()

    # should instrument everything
    @test should_instrument(rules, first(methods(+)))
    @test should_instrument(rules, first(methods(sum)))
    @test should_instrument(rules, first(methods(Iterators.flatten)))
    @test should_instrument(rules, first(methods(Iterators.drop)))

    @test !should_breakon(rules, first(methods(+)), 0)
    @test !should_breakon(rules, first(methods(+)), 2)
    @test !should_breakon(rules, first(methods(sum)), 0)
    @test !should_breakon(rules, first(methods(sum)), 3)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 0)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 4)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 0)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end

@testset "not instrumenting some modules" begin
    rules = BreakpointRules(
        [Rule(Iterators)],
        []
    )
    @test should_instrument(rules, first(methods(+)))
    @test should_instrument(rules, first(methods(sum)))
    @test !should_instrument(rules, first(methods(Iterators.flatten)))
    @test !should_instrument(rules, first(methods(Iterators.drop)))


    @test !should_breakon(rules, first(methods(+)), 0)
    @test !should_breakon(rules, first(methods(+)), 2)
    @test !should_breakon(rules, first(methods(sum)), 0)
    @test !should_breakon(rules, first(methods(sum)), 3)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 0)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 4)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 0)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end


@testset  "not instrumenting parent module should still instrument child module" begin
    #TODO: Decide if this is the correct behavour
    rules = BreakpointRules(
        [Rule(Base)],
        []
    )
    @test !should_instrument(rules, first(methods(+)))
    @test !should_instrument(rules, first(methods(sum)))
    @test should_instrument(rules, first(methods(Iterators.flatten)))
    @test should_instrument(rules, first(methods(Iterators.drop)))


    @test !should_breakon(rules, first(methods(+)), 0)
    @test !should_breakon(rules, first(methods(+)), 2)
    @test !should_breakon(rules, first(methods(sum)), 0)
    @test !should_breakon(rules, first(methods(sum)), 3)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 0)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 4)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 0)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end

@testset "not instrumenting modules but breaking on it" begin
    rules = BreakpointRules(
        [Rule(Iterators)],
        [Rule(Iterators.drop)]
    )
    @test should_instrument(rules, first(methods(+)))
    @test should_instrument(rules, first(methods(sum)))
    @test !should_instrument(rules, first(methods(Iterators.flatten)))
    @test should_instrument(rules, first(methods(Iterators.drop)))
    

    @test !should_breakon(rules, first(methods(+)), 0)
    @test !should_breakon(rules, first(methods(+)), 2)
    @test !should_breakon(rules, first(methods(sum)), 0)
    @test !should_breakon(rules, first(methods(sum)), 3)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 0)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 4)
    @test should_breakon(rules, first(methods(Iterators.drop)), 0)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end


