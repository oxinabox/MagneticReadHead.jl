using MagneticReadHead: should_instrument, should_breakon, Rule, BreakpointRules
using Test

@testset "breakon rules" begin
    # Helper for defining rules during tests
    borule(args...) = BreakpointRules(Rule[], [Rule(args...)])

    @testset "module" begin
        # I don't really think this is useful, but it does work
        rules = borule(Iterators)
        @test should_breakon(rules, first(methods(Iterators.drop)), 1)
        @test !should_breakon(rules, first(methods(Iterators.drop)), 3)
        @test should_breakon(rules, first(methods(Iterators.flatten)), 1)
        @test !should_breakon(borule(Iterators), first(methods(Iterators.flatten)), 2)
    end

    @testset "Function" begin
        rules = borule(eps)
        for meth in methods(eps)
            @test should_breakon(rules, meth, 1)
            @test !should_breakon(rules, meth, 2)
            @test !should_breakon(rules, meth, 3)
        end
    end

    @testset "Method" begin
        meths  = collect(methods(pwd))
        rules = borule(meths[1])
        @test should_breakon(rules, meths[1], 1)
        @test !should_breakon(rules, meths[1], 2)
        for meth in meths[2:end]
            @test !should_breakon(rules, meth, 1)
        end
    end

    @testset "Method + statement number" begin
        # Not going to test ever other permutation of x + statement number
        # This is the one that matters, method + statement number
        # is what a line number breakpoint will become
        meths  = collect(methods(pwd))
        rules = borule(meths[1], 3)
        @test !should_breakon(rules, meths[1], 1)
        @test !should_breakon(rules, meths[1], 2)
        @test should_breakon(rules, meths[1], 3)
        @test !should_breakon(rules, meths[1], 4)

        for meth in meths[2:end]
            @test !should_breakon(rules, meth, 1)
            @test !should_breakon(rules, meth, 3)
        end
    end
end

@testset "default" begin
    rules = BreakpointRules()

    # should instrument everything
    @test should_instrument(rules, +)
    @test should_instrument(rules, sum)
    @test should_instrument(rules, Iterators.flatten)
    @test should_instrument(rules, Iterators.drop)

    @test !should_breakon(rules, first(methods(+)), 1)
    @test !should_breakon(rules, first(methods(+)), 3)
    @test !should_breakon(rules, first(methods(sum)), 1)
    @test !should_breakon(rules, first(methods(sum)), 4)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 1)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 5)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 1)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end

@testset "not instrumenting some modules" begin
    rules = BreakpointRules(
        [Rule(Iterators)],
        []
    )
    @test should_instrument(rules, +)
    @test should_instrument(rules, sum)
    @test !should_instrument(rules, Iterators.flatten)
    @test !should_instrument(rules, Iterators.drop)


    @test !should_breakon(rules, first(methods(+)), 1)
    @test !should_breakon(rules, first(methods(+)), 3)
    @test !should_breakon(rules, first(methods(sum)), 1)
    @test !should_breakon(rules, first(methods(sum)), 4)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 1)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 5)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 1)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end


@testset  "not instrumenting parent module should still instrument child module" begin
    #TODO: Decide if this is the correct behavour
    rules = BreakpointRules(
        [Rule(Base)],
        []
    )
    @test !should_instrument(rules, +)
    @test !should_instrument(rules, sum)
    @test should_instrument(rules, Iterators.flatten)
    @test should_instrument(rules, Iterators.drop)

    @test !should_breakon(rules, first(methods(+)), 1)
    @test !should_breakon(rules, first(methods(+)), 3)
    @test !should_breakon(rules, first(methods(sum)), 1)
    @test !should_breakon(rules, first(methods(sum)), 4)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 1)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 5)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 1)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end

@testset "not instrumenting modules but breaking on it" begin
    rules = BreakpointRules(
        [Rule(Iterators)],
        [Rule(Iterators.drop)]
    )
    @test should_instrument(rules, +)
    @test should_instrument(rules, sum)
    @test !should_instrument(rules, Iterators.flatten)
    @test should_instrument(rules, Iterators.drop)

    @test !should_breakon(rules, first(methods(+)), 1)
    @test !should_breakon(rules, first(methods(+)), 3)
    @test !should_breakon(rules, first(methods(sum)), 1)
    @test !should_breakon(rules, first(methods(sum)), 4)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 1)
    @test !should_breakon(rules, first(methods(Iterators.flatten)), 5)
    @test should_breakon(rules, first(methods(Iterators.drop)), 1)
    @test !should_breakon(rules, first(methods(Iterators.drop)), 5)
end
