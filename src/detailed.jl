

#TODO make this a struct, but for now it is a named tuple for dev'ing


Cassette.@context HandEvalCtx


function Cassette.overdub(ctx::HandEvalCtx, f, args...)
end

hand_eval(f::Core.Builtin, args) = f(args...)


Cassette.@pass function map_assignments(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info
    
    # Setup
    callbackslotname = gensym("callback")
    push!(ir.slotnames, callbackslotname)
    push!(ir.slotflags, 0x00)
    metadata_slot = SlotNumber(length(ir.slotnames))
    getmetadata = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), Expr(:contextslot), QuoteNode(:metadata))

    # insert the initial `metadata slot` assignment into the IR.
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                (stmt, i) -> i == 1 ? 2 : nothing,
                                (stmt, i) -> [Expr(:(=), metadata_slot, getmetadata), stmt])

    
    # Now the real part where we determine about assigments
    # What we want to do is:
    # After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`
    slotname(slotnum::GlobalRef) = ir.slotnames[slotnum.id + 1]  #1 is #self

    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = 2is_assignment(stmt)
    
    function newstmts(stmt, i)
        if is_assignment(stmt)
            lhs = stmt.args[1]
            name = slotname(lhs)
            record = Expr(
                :(=),
                Expr(
                    :call,
                    Expr(:nooverdub, GlobalRef(Base, :setindex!)),
                    getmetadata,
                    lhs,
                    name
                )
            )
            
            return [stmt, record]
        else
            return [stmt]
        end
    end
    

end



