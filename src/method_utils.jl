"""
    moduleof

Returns the module associated with a method.
Note: this is not the module where it was defined (m.module)
but rather the module for which it's function was defined.
"""
moduleof(m::Method) = functiontypeof(m).name.module

functiontypeof(m::Method) = parameter_typeof(m.sig)[1]
parameter_typeof(sig::UnionAll) = parameter_typeof(sig.body)
parameter_typeof(sig::DataType) = sig.parameters

"""
    DispatchAttempt
This is a lightweight type that represents a attemopt to dispatch against a method.
It has two type params, `F` the function type,
and `A` a tuple type of arguments.
"""
struct DispatchAttempt{F,A}
    f::F
    args::A
end

"""
    _typeof
Like `typeof` but when applied to `DataType`s, returns `Type{T}`, rather than `DataType`
"""
_typeof(x)=typeof(x)
_typeof(::Type{T}) where T = Type{T}

"""
    accepts(meth::Method, ::DispatchAttempt{F,A}) where {F,A}
It can be compared against a `Method` to see if that method would
accept this dispatch.
It does not check if that is the highest priority method that would accept this dispatch
"""
function accepts(meth::Method, da::DispatchAttempt)
    dispatch_sig = Tuple{_typeof(da.f), map(_typeof, da.args)...}
    return dispatch_sig <: meth.sig
end

# Builtin's do not have methods
accepts(::Method, ::DispatchAttempt{<:Core.Builtin}) = false
