

"""
    only(xs)

Like `first(xs)`, but asserts that the iterator `xs` only had one element.
"""
function only(xs)
    val, state = iterate(xs)
    @assert iterate(xs, state) == nothing
    return val
end
