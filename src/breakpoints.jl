#TODO: think hard about API, eg maybe `set!(Breakpoint(foo,1))` might be nicest

for (name, list) in ((:breakpoint, :breakon_rules), (:nodebug, :no_instrument_rules))
    set! = Symbol(:set_, name, :!)
    @eval export $(set!)
    @eval $(set!)(args...) = $(set!)(GLOBAL_BREAKPOINT_RULES, args...)
    @eval function $(set!)(rules::BreakpointRules, args...)
        return push!(rules.$list, Rule(args...))
    end


    rm! = Symbol(:rm_, name, :!)
    @eval export $(rm!)
    @eval $(rm!)(args...) = $(rm!)(GLOBAL_BREAKPOINT_RULES, args...)
    @eval function $(rm!)(rules::BreakpointRules, args...)
        old_num_rules = length(rules.$list  )
        filter!(isequal(Rule(args...)), rules.$list )
        if length(rules.$list) == old_num_rules
            @info("No matching $($name) was found, so none removed")
        end
        return rules.$list
    end
    
    list_all = Symbol(:list_, name,:s)
    @eval export $(list_all)
    @eval $(list_all)()=$(list_all)(GLOBAL_BREAKPOINT_RULES)
    @eval $(list_all)(rules::BreakpointRules) = display(rules.$list)

    clear_all = Symbol(:clear_,name, :s!)
    @eval export $clear_all
    @eval $(clear_all)()=$(clear_all)(GLOBAL_BREAKPOINT_RULES)
    @eval $(clear_all)(rules::BreakpointRules) = empty!(rules.$list)
end
