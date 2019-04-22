# For ease of editting we have this here
# It should be set to just redistpatch
function handeval_break_action(ctx, meth, stmt_number, slotnames, slotvalues)
    break_action(ctx, meth, stmt_number, slotnames, slotvalues)
end
function handeval_should_break(ctx, meth, stmt_number)
    should_break(ctx, meth, stmt_number)
end


"""
    extended_insert_statements!(code, codelocs, stmtcount, newstmts)

Like `Cassette.insert_statements` but the `newstmts` function takes
3 arguments:
 - `statement`: the IR statement it will be replacing
 - `dest_i`: the first index that this will be inserted into, after renumbering to insert prior replacements.
     - in the `newst,ts` function `dest_i` should be used to calculate SSAValues and goto addresses
 - `src_i`: the index of the original IR statement that this will be replacing
     - You may wish to use this in the `newstmts` function if the code actually depends on which
       statment number of original IR is being replaced.
"""
function extended_insert_statements!(code, codelocs, stmtcount, newstmts)
    ssachangemap = fill(0, length(code))
    labelchangemap = fill(0, length(code))
    worklist = Tuple{Int,Int}[]
    for i in 1:length(code)
        stmt = code[i]
        nstmts = stmtcount(stmt, i)
        if nstmts !== nothing
            addedstmts = nstmts - 1
            push!(worklist, (i, addedstmts))
            ssachangemap[i] = addedstmts
            if i < length(code)
                labelchangemap[i + 1] = addedstmts
            end
        end
    end
    Core.Compiler.renumber_ir_elements!(code, ssachangemap, labelchangemap)
    for (src_i, addedstmts) in worklist
        dest_i = src_i + ssachangemap[src_i] - addedstmts # correct the index for accumulated offsets
        stmts = newstmts(code[dest_i], dest_i, src_i)
        @assert(length(stmts) == (addedstmts + 1), "$(length(stmts)) == $(addedstmts + 1)")
        code[dest_i] = stmts[end]
        for j in 1:(length(stmts) - 1) # insert in reverse to maintain the provided ordering
            insert!(code, dest_i, stmts[end - j])
            insert!(codelocs, dest_i, codelocs[dest_i])
        end
    end
end

"""
    created_on
Given an `ir` returns a vector the same length as slotnames, with the index corresponds to that on which each was created
"""
function created_on(ir)
    created_stmt_ind = zeros(length(ir.slotnames))  # default to assuming everything created before start
    for (ii,stmt) in enumerate(ir.code)
        if stmt isa Core.NewvarNode
            @assert created_stmt_ind[stmt.slot.id] == 0
            created_stmt_ind[stmt.slot.id] = ii
        end
    end
    return created_stmt_ind
end

call_expr(mod::Module, func::Symbol, args...) = Expr(:call, Expr(:nooverdub, GlobalRef(mod, func)), args...)

function enter_debug_statements(slotnames, slot_created_ons, method::Method, ind::Int, orig_ind::Int)
    statements = [
        call_expr(MagneticReadHead, :handeval_should_break, Expr(:contextslot), method, orig_ind),
        Expr(:REPLACE_THIS_WITH_GOTOIFNOT_AT_END),
        Expr(:call, Expr(:nooverdub, GlobalRef(Base, :getindex)), GlobalRef(Core, :Symbol)),
        Expr(:call, Expr(:nooverdub, GlobalRef(Base, :getindex)), GlobalRef(Core, :Any)),
    ]
    stop_cond_ssa = Core.SSAValue(ind)
    # Skip the pplaceholder
    names_ssa = Core.SSAValue(ind + 2)
    values_ssa = Core.SSAValue(ind + 3)
    cur_ind = ind + 4
    # Now we store all of the slots that have values assigned to them
    for (slotind, (slotname, slot_created_on)) in enumerate(zip(slotnames, slot_created_ons))
        orig_ind > slot_created_on || continue
        slot = Core.SlotNumber(slotind)
        append!(statements, (
            Expr(:isdefined, slot),             # cur_ind
            Expr(:gotoifnot, Core.SSAValue(cur_ind), cur_ind + 4),    # cur_ind + 1
            call_expr(Base, :push!, names_ssa, QuoteNode(slotname)),  # cur_ind + 2
            call_expr(Base, :push!, values_ssa, slot)   # cur_ind + 3
        ))

        cur_ind += 4
    end

    push!(statements, call_expr(
        MagneticReadHead, :handeval_break_action,
        Expr(:contextslot),
        method,
        orig_ind,
        names_ssa, values_ssa)
    )

    statements[2] = Expr(:gotoifnot, stop_cond_ssa, ind + length(statements))
    return statements
end


function enter_debug_statements_count(slot_created_ons, orig_ind)
    # this function intentionally mirrors structure of enter_debug_statements
    # for ease of updating to match it
    n_statements = 4

    for slot_created_on in slot_created_ons
        if orig_ind > slot_created_on
            n_statements  += 4
        end
    end
    n_statements += 1
    return n_statements
end


function instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info

    slot_created_ons = created_on(ir)
    extended_insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> stmt isa Expr ?
            enter_debug_statements_count(slot_created_ons, i) + 1
            : nothing,
        (stmt, i, orig_i) -> [
                enter_debug_statements(
                    ir.slotnames,
                    slot_created_ons,
                    reflection.method,
                    i, orig_i
                );
                stmt
            ]
    )
    return ir
end

const handeval_pass = Cassette.@pass instrument!
