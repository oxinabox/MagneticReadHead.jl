struct Rule{V}
    v::V
    statement_ind::Int
end
# No matter if a Function or a Method, default to break at start
Rule(v) = Rule(v, 0)

##############################################################################
# instrumenting rules
match(rule::Rule{Method}, method) = method == rule.v
match(rule::Rule{Module}, method) = moduleof(method) == rule.v
function match(rule::Rule{F}, method) where F
    # This one is for functions
    return functiontypeof(method) <: F
end

#breakon rules
function match(rule::Rule, method, statement_ind)
    return match(rule, method) && rule.statement_ind == statement_ind
end


## The overall rule object
"""
    BreakpointRules

Holds information about breakpoints,
to allow the descision of which methods to instrument with potential breakpoints,
and to decide which potential breakpoints in instrumented code to actually break on.
(When not already in stepping mode)
"""
mutable struct BreakpointRules
    no_instrument_rules::Vector{Rule}
    breakon_rules::Vector{Rule}
end
BreakpointRules() = BreakpointRules(Rule[], Rule[])


"""
    should_instrument(rules, method)

Returns true if according to the rules, this method should be instrumented
with potential breakpoints.
The default is to instrument everything.
"""
function should_instrument(rules::BreakpointRules, method)
    # If we are going to break on it, then definately instrument it
    for rule in rules.breakon_rules
        match(rule, method) && return true
    end
    # otherwise:
    # if we have a rule saying not to instrument it then don't
    for rule in rules.no_instrument_rules
        match(rule, method) && return false
    end
    # otherwise: no rules of relevence found, so we instrument it.
    return true
end

# This is a Core.Builtin, it has no methods, do not try and instrument it
should_instrument(::BreakpointRules, ::Nothing) = false

"""
    should_breakon(rules, method, statement_ind)

Returns true if according to the rules, this IR statement index within this method
should be broken on.
I.e. if this point in the code has a breakpoint set.
"""
function should_breakon(rules::BreakpointRules, method, statement_ind)
    return any(rules.breakon_rules) do rule
        match(rule, method, statement_ind)
    end
end
