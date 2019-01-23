



Cassette.@context HandEvalCtx


#function Cassette.overdub(ctx::HandEvalCtx, f, args...)
#end

function Cassette.overdub(ctx::HandEvalCtx, f, callback, args...)
    if Cassette.canrecurse(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = callback)
        return Cassette.recurse(_ctx, f, args...) # return result, callback
    else
        return Cassette.fallback(ctx, f, args...), callback
    end
end




slotname(ir::Core.CodeInfo, slotnum) = ir.slotnames[slotnum.id]  #1 is #self

function map_assignments(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir::Core.CodeInfo = reflection.code_info
    # Setup
    push!(ir.slotnames, gensym("mdata"))
    push!(ir.slotflags, 0x00)
    metadata_slot = Core.SlotNumber(length(ir.slotnames))
    getmetadata = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), Expr(:contextslot), QuoteNode(:metadata))

    # insert the initial `metadata slot` assignment into the IR.
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                (stmt, i) -> i == 1 ? 2 : nothing,
                                (stmt, i) -> [Expr(:(=), metadata_slot, getmetadata), stmt])

    
    # Now the real part where we determine about assigments
    # What we want to do is:
    # After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`

    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = is_assignment(stmt) ? 2 : nothing
    
    function newstmts(stmt, i)
        lhs = stmt.args[1]
        name = slotname(ir, lhs)
        @show name
        record = Expr(
            :(=),
            Expr(
                :call,
                Expr(:nooverdub, GlobalRef(Base, :setindex!)),
                metadata_slot,
                lhs,
                name
            )
        )
        
        return [stmt, record]
    end
    
    Cassette.insert_statements!(ir.code, ir.codelocs, stmtcount, newstmts)
    return ir
end


const handeval_pass = Cassette.@pass map_assignments


