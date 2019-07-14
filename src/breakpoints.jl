struct LineNum
    v::Int
end

# POSSIBLE_BUG: I worry that to make kwarg functions work
# this code needs to be moved into the Rules themselves,
# and run at check-time against each statement_ind
function rules(path::AbstractString, line::LineNum)
    methods = containing_methods(path, line.v)
    statement_inds = src_line2ir_statement_ind.(methods, line.v)
    new_rules = Rule.(methods, statement_inds)
    if isempty(new_rules)
        @warn "No matching rules could be constructed)" methods statement_inds
    end
    return new_rules
end

rules(path::AbstractString, line::Integer) = rules(path, LineNum(line))
rules(args...) = (Rule(args...),)  # default to just constructing a Rule


#TODO: think hard about API, eg maybe `set!(Breakpoint(foo,1))` might be nicest

function set_breakpoint!(the_rules::BreakpointRules, args...)
    return append!(the_rules.breakon_rules, rules(args...))
end

function set_uninstrumented!(the_rules::BreakpointRules, arg::T) where T
    T !== Method || throw(ArgumentError("Disabling instrumentation per method, is not supported."))
    return push!(the_rules.no_instrument_rules, Rule(arg))
end

for (name, list) in ((:breakpoint, :breakon_rules), (:uninstrumented, :no_instrument_rules))
    set! = Symbol(:set_, name, :!)
    @eval export $(set!)
    @eval $(set!)(args...) = $(set!)(GLOBAL_BREAKPOINT_RULES, args...)
    # actual set definitions are above
    rm! = Symbol(:rm_, name, :!)
    @eval export $(rm!)
    @eval $(rm!)(args...) = $(rm!)(GLOBAL_BREAKPOINT_RULES, args...)
    @eval function $(rm!)(the_rules::BreakpointRules, args...)
        old_num_rules = length(the_rules.$list)
        to_remove = rules(args...)
        filter!(!in(to_remove), the_rules.$list)
        if length(the_rules.$list) == old_num_rules
            @info("No matching rule was found, so none removed")
        end
        return the_rules.$list
    end

    list_all = Symbol(:list_, name,:s)
    @eval export $(list_all)
    @eval $(list_all)()=$(list_all)(GLOBAL_BREAKPOINT_RULES)
    @eval $(list_all)(the_rules::BreakpointRules) = the_rules.$list

    clear_all = Symbol(:clear_,name, :s!)
    @eval export $clear_all
    @eval $(clear_all)()=$(clear_all)(GLOBAL_BREAKPOINT_RULES)
    @eval $(clear_all)(the_rules::BreakpointRules) = empty!(the_rules.$list)
end
