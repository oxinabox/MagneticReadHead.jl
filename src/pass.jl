# For ease of editting we have this here
# It should be set to just redistpatch
function handeval_break_action(metadata, meth, stmt_number)
    break_action(metadata, meth, stmt_number)
end


slotname(ir::Core.CodeInfo, slotnum::Integer) = ir.slotnames[slotnum]
slotname(ir::Core.CodeInfo, slotnum) = slotname(ir, slotnum.id)

# inserts insert `ctx.metadata[:x] = x`
function record_slot_value(ir, variable_record_slot, slotnum)
    name = slotname(ir, slotnum)
    return Expr(
        :call,
        Expr(:nooverdub, GlobalRef(Base, :setindex!)),
        variable_record_slot,
        slotnum,
        QuoteNode(name)
    )
end

# What we want to do is:
# After every assigment: `x = foo`, insert `ctx.metadata[:x] = x`
function instrument_assignments!(ir, variable_record_slot)
    is_assignment(stmt) = Base.Meta.isexpr(stmt, :(=))
    stmtcount(stmt, i) = is_assignment(stmt) ? 2 : nothing
    function newstmts(stmt, i)
        lhs = stmt.args[1]
        record = record_slot_value(ir, variable_record_slot, lhs)
        return [stmt, record]
    end
    Cassette.insert_statements!(ir.code, ir.codelocs, stmtcount, newstmts)
end

function instrument_arguments!(ir, method, variable_record_slot)
    # start from 2 to skip #self
    arg_names = Base.method_argnames(method)[2:end]
    arg_slots = 1 .+ (1:length(arg_names))
    @assert(
        ir.slotnames[arg_slots] == arg_names,
        "$(ir.slotnames[arg_slots]) != $(arg_names)"
    )

    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> i == 1 ? length(arg_slots) + 1 : nothing,

        (stmt, i) -> [
            map(arg_slots) do slotnum
                slot = Core.SlotNumber(slotnum)
                record_slot_value(ir, variable_record_slot, slot)
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
    setup_metadata_slots!(ir, metadata_slot, variable_record_slot)

Attaches the cassette metadata object and it's variable field to the slot given.
This will be added as the very first statement to the ir.
"""
function setup_metadata_slots!(ir, metadata_slot, variable_record_slot)
    statements = [
        # Get Cassette to fill in the MetaData slot
        Expr(:(=), metadata_slot, Expr(
            :call,
            Expr(:nooverdub, GlobalRef(Core, :getfield)),
            Expr(:contextslot),
            QuoteNode(:metadata)
        )),

        # Extract it's variables dict field
        Expr(:(=), variable_record_slot, Expr(
            :call,
            Expr(:nooverdub, GlobalRef(Core, :getfield)),
            metadata_slot,
            QuoteNode(:variables)
        ))
    ]

    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> i == 1 ? length(statements) + 1 : nothing,
        (stmt, i) -> [statements; stmt]
    )
end

"""
    insert_break_actions!(ir, metadata_slot)

Add calls to the break action between every statement.
"""
function insert_break_actions!(reflection, metadata_slot)
    ir = reflection.code_info
    break_state(i) = Expr(:call,
        Expr(:nooverdub, GlobalRef(MagneticReadHead, :handeval_break_action)),
        metadata_slot,
        reflection.method,
        i
    )
    
    Cassette.insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> 2,
        (stmt, i) -> [break_state(i-1); stmt]
    )
end

function instrument_handeval!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info
    # Create slots to store metadata and it's variable record field
    # put them a the end.
    metadata_slot = create_slot!(ir, "metadata")
    variable_record_slot = create_slot!(ir, "variable_record")

    insert_break_actions!(reflection, metadata_slot)

    # Now the real part where we determine about assigments
    instrument_assignments!(ir, variable_record_slot)
    
    # record all the initial values so we get the parameters
    instrument_arguments!(ir, reflection.method, variable_record_slot)

    # insert the initial metadata and variable record slot
    # assignments into the IR.
    # Do this last so it doesn't get caught in our assignment catching
    setup_metadata_slots!(ir, metadata_slot, variable_record_slot)
    
    return ir
end


const handeval_pass = Cassette.@pass instrument_handeval!
