Cassette.@context HandEvalCtx


function Cassette.overdub(ctx::HandEvalCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = Dict())
        
        try
            return Cassette.recurse(_ctx, f, args...)
        finally
            # save assignments from functions
            ctx.metadata[gensym(nameof(f))] = _ctx.metadata
        end
    else
        return Cassette.fallback(ctx, f, args...)
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
    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> i == 1 ? 2 : nothing,
        (stmt, i) -> [Expr(:(=), metadata_slot, getmetadata), stmt]
    )


    # Now the real part where we determine about assigments
    # What we want to do is:
    # After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`
    # Skip first line where we store Metadata
    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = i > 1 && is_assignment(stmt) ? 2 : nothing
    
    function newstmts(stmt, i)
        lhs = stmt.args[1]
        name = slotname(ir, lhs)
        record = Expr(
            :call,
            Expr(:nooverdub, GlobalRef(Base, :setindex!)),
            metadata_slot,
            lhs,
            QuoteNode(name)
        )
        
        return [stmt, record]
    end
    
    Cassette.insert_statements!(ir.code, ir.codelocs, stmtcount, newstmts)
    return ir
end


const handeval_pass = Cassette.@pass map_assignments


