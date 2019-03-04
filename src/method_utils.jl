moduleof(m::Method) = m.module
functiontypeof(m::Method) = m.sig.parameters[1]

# Last method will always be closest to the types we provided
methodof(f, args...) = methods(f, Tuple{typeof.(args)...}).ms[end]
methodof(::Core.Builtin, args...) = nothing  # No methods for `Builtin`s

#TODO: Methods are actually pretty slow to construct. 1-2μs and 8-15 allocations
# when we construct them ourself we are only really using them has a container for
# function, args types and module.
# We could define out own `LightMethod`, which exposes also overloads the above
# functions, while still keeping them working on real methods. And then just use that

