

"""
    only(xs)

Like `first(xs)`, but asserts that the iterator `xs` only had one element.
"""
function only(xs)
    val, state = iterate(xs)
    @assert iterate(xs, state) == nothing
    return val
end



function better_readline(stream = stdin)
    #TODO doing this better still requires depending on the REPL.Terminals module
    if !isopen(stream)
        Base.reseteof(stream)
        @assert(isopen(stream))
    end
    if Sys.iswindows()
        # Apparently in windows it is already pretty nice
        return readline(stream)
    else
        #TODO: Put in raw mode, drop control characters etc
        return readline(stream)
    end
end
