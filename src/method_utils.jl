"""
    moduleof

Returns the module associated with a method.
Note: this is not the module where it was defined (m.module)
but rather the module for which it's function was defined.
"""
moduleof(m::Method) = moduleof(functiontypeof(m))
moduleof(sig::DataType) = sig.name.module
moduleof(sig::UnionAll) = moduleof(sig.body)

functiontypeof(m::Method) = parameter_typeof(m.sig)[1]
parameter_typeof(sig::UnionAll) = parameter_typeof(sig.body)
parameter_typeof(sig::DataType) = sig.parameters
