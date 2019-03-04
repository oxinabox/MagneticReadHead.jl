moduleof(m::Method) = m.module
functiontypeof(m::Method) = m.sig.parameters[1]
