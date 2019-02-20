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

# What we want to do is:
# After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`
function instrument_assignments!(ir, metadata_slot)
    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = is_assignment(stmt) ? 2 : nothing
    function newstmts(stmt, i)
        lhs = stmt.args[1]
        record = record_slot_value(ir, metadata_slot, lhs)
        return [stmt, record]
    end
    Cassette.insert_statements!(ir.code, ir.codelocs, stmtcount, newstmts)
end

function instrument_arguments!(ir, method, metadata_slot)
    # start from 2 to skip #self
    arg_names = Base.method_argnames(method)[2:end]
    arg_slots = 1 .+ (1:length(arg_names))
    @assert(
        ir.slotnames[arg_slots] == arg_names,
        "$(ir.slotnames[arg_slots]) != $(arg_names)"
    )

    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        # Only add to line 1 as doing this at the begining
        # add 1 because we need to put the original line 1 back in
        (stmt, i) -> i == 1 ? length(arg_slots) + 1 : nothing,

        (stmt, i) -> [
            map(arg_slots) do slotnum
                slot = Core.SlotNumber(slotnum)
                record_slot_value(ir, metadata_slot, slot)
            end;
            stmt
        ]
    )
end

"""
     create_slot!(ir, namebase="")
Adds a slot to the IR with a name based on `namebase`.
It will be added at the end
returns the new slot number
"""
function create_slot!(ir, namebase="")
    slot_name = gensym(namebase)
    push!(ir.slotnames, slot_name)
    push!(ir.slotflags, 0x00)
    slot = Core.SlotNumber(length(ir.slotnames))
    return slot
end

"""
    put_metadata_in_its_slot!(ir, metadata_slot)

Attaches the cassette metadata object to the slot given.
This will be added as the very first statement to the ir.
"""
function put_metadata_in_its_slot!(ir, metadata_slot)
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
end


function instrument_variables!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir::Core.CodeInfo = reflection.code_info
    # Create a slot that we will put the metadata in, make it the last one
    metadata_slot = create_slot!(ir, "metadata")

    # Now the real part where we determine about assigments
    instrument_assignments!(ir, metadata_slot)
       
    
    # record all the initial values so we get the parameters
    instrument_arguments!(ir, reflection.method, metadata_slot)

    # insert the initial `metadata slot` assignment into the IR.
    # Do this last so it doesn't get caught in our assignment catching
    put_metadata_in_its_slot!(ir, metadata_slot)
   
    return ir
end


const handeval_pass = Cassette.@pass instrument_variables!


