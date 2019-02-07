Cassette.@context HandEvalCtx





#==
function Cassette.overdub(ctx::HandEvalCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = Dict())
        
        try
            return Cassette.recurse(_ctx, f, args...)
        finally
            #save assignments from functions
            ctx.metadata[gensym(nameof(f))] = _ctx.metadata
        end
    else
        return Cassette.fallback(ctx, f, args...)
    end
end

==#


#==
"""
    @call_ast

Helper to make things in function call form into IR experessions for those function calls.
Note that the arguments must be IR level experessions already.

Call is automatically maked with `nooverdub`.
"""
function call_ast(expr)
    @capture(expr, mod_.func_(args__)) ||
        error("Call  should be of form `module.func(args...)`")
    
    modu::Module = mod==:Base ? Base :
        mod==:Core ? Core :
        error("Module $mod, unrecognized, all modules must be hardcoded in @call_ast")
        
    ret = Expr(
        :call,
        Expr(:nooverdub, GlobalRef(modu, func)),
        args...
    )
    return ret
    #ireturn Expr(:quote, ret)
end
==#

slotname(ir::Core.CodeInfo, slotnum::Integer) = ir.slotnames[slotnum]
slotname(ir::Core.CodeInfo, slotnum) = slotname(ir, slotnum.id)

# inserts insert `ctx.metadata[:x] = x`
function record_slot_value(ir, metadata_slot, slotnum)
    name = slotname(ir, slotnum)
 
    #call_ast(:(Base.setindex!(dest_slot, lhs, QuoteNode(name))))
    return Expr(
        :call,
        Expr(:nooverdub, GlobalRef(Base, :setindex!)),
        metadata_slot,
        slotnum,
        QuoteNode(name)
    )
end




function map_assignments(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir::Core.CodeInfo = reflection.code_info
    # Setup
    metadata_slot_name = gensym("metadata")
    push!(ir.slotnames, metadata_slot_name)
    push!(ir.slotflags, 0x00)
    metadata_slot = Core.SlotNumber(length(ir.slotnames))
   

    # Now the real part where we determine about assigments
    # What we want to do is:
    # After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`
    # Skip first line where we store Metadata
    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = is_assignment(stmt) ? 2 : nothing
    function newstmts(stmt, i)
        lhs = stmt.args[1]
        record = record_slot_value(ir, metadata_slot, lhs)
        return [stmt, record]
    end
    Cassette.insert_statements!(ir.code, ir.codelocs, stmtcount, newstmts)

     
    
    # record all the initial values so we get the parameters
    Cassette.insert_statements!(
        ir.code, ir.codelocs,
         # do not insert #self or metadata_slot, so -2.
        (stmt, i) -> i == 1 ? 1 + length(ir.slotnames) - 2 : nothing,

        (stmt, i) -> [map(2:lastindex(ir.slotnames) - 1) do slotnum
                          slot = Core.SlotNumber(slotnum)
                          record_slot_value(ir, metadata_slot, slot)
                      end; stmt]
    )
    

    # insert the initial `metadata slot` assignment into the IR.
    # Do this last so it doesn't get caught in our assignment catching
    getmetadata = Expr(
        :call,
        Expr(
            :nooverdub,
            GlobalRef(Core, :getfield)
        ),
        Expr(:contextslot),
        QuoteNode(:metadata)
    )

    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> i == 1 ? 2 : nothing,
        (stmt, i) -> [Expr(:(=), metadata_slot, getmetadata), stmt]
    )

   return ir
end


const handeval_pass = Cassette.@pass map_assignments


