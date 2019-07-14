#==
Instumenting Debugger Pass:

The purpose of this pass is to modify the IR code to instert debug statements.
One is inserted before each other statement in the IR.
Rough pseudocode for a Debug statment:
```
if should_break  # i.e. this breakpoint is active
    variables = filter(isdefined, slots)
    call break_action(variables)  # launch the debugging REPL etc.
end
```
The reality is a bit more complicated, as you can't ask if a variable is defined
before it is declared. But that is the principle.
==#


"""
    extended_insert_statements!(code, codelocs, stmtcount, newstmts)

Like `Cassette.insert_statements` but the `newstmts` function takes
3 arguments:
 - `statement`: the IR statement it will be replacing
 - `dest_i`: the first index that this will be inserted into, after renumbering to insert prior replacements.
     - in the `newst,ts` function `dest_i` should be used to calculate SSAValues and goto addresses
 - `src_i`: the index of the original IR statement that this will be replacing
     - You may wish to use this in the `newstmts` function if the code actually depends on which
       statement number of original IR is being replaced.
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
Given an `Cassette.Reflection` returns a vector the same length as slotnames,
which each entry is the ir statment index for where the coresponding variable was delcared
"""
function created_on(reflection)
    # This is a simplification of
    # https://github.com/JuliaLang/julia/blob/236df47251c203c71abd0604f2f19bf1f9c639fd/base/compiler/ssair/slot2ssa.jl#L47
    
    ir = reflection.code_info
    created_stmt_ind = fill(typemax(Int), length(ir.slotnames))
    
    # #self# and all the arguments are created at start
    nargs = reflection.method.nargs
    if nargs > length(created_stmt_ind)
        error("More arguments than slots")
    end
    for id in 1 : nargs
        created_stmt_ind[id] = 0
    end
    
    # Scan for assignments or for uses
    for (ii, stmt) in enumerate(ir.code)
        if isexpr(stmt, :(=)) && stmt.args[1] isa Core.SlotNumber
            id = stmt.args[1].id
            created_stmt_ind[id] = min(created_stmt_ind[id], ii)
        elseif isexpr(stmt, :call)
            for arg in stmt.args
                if arg isa Core.SlotNumber
                    id = arg.id
                    created_stmt_ind[id] = min(created_stmt_ind[id], ii)
                end
            end
         end
    end
    return created_stmt_ind
end

"""
    call_expr(mod:Module, func::Symbol, args...)
This function returns the IR expression for calling the names function `func` from module `mod`, with the
given args. It is maked with `nooverdub` which will stop Cassette recursing into it.
"""
call_expr(mod::Module, func::Symbol, args...) = Expr(:call, Expr(:nooverdub, GlobalRef(mod, func)), args...)


"""
    enter_debug_statements(slotnames, slot_created_ons, method::Method, ind::Int, orig_ind::Int)

This returns the IR code for a debug statement (as decribed at the top of this file).
This basically means creating code that checks if we `should_break` at this statement,
and if so works out what variable are defined, then passing those to the `break_action` call which will
show the debugging prompt.

 - slotnames: the names of the slots from the CodeInfo
 - slot_created_on: a vector saying where the variables were declared (as returned by `created_on`
 - method: the method being instruments
 - ind: the actual index in the code IR this is being  inserted at. This is where the SSAValues start from
 - orig_ind: the index in the original code IR for where this is being inserted. (before other debug statements were inserted above)
"""
function enter_debug_statements(
    slotnames, slot_created_ons, method::Method,
    stmt, ind::Int, orig_ind::Int
    )
    
    statements = [
        call_expr(MagneticReadHead, :should_break, method, orig_ind),
        Expr(:REPLACE_THIS_WITH_GOTOIFNOT_AT_END),
        call_expr(Base, :getindex, GlobalRef(Core, :Symbol)),
        call_expr(Base, :getindex, GlobalRef(Core, :Any)),
    ]
    stop_cond_ssa = Core.SSAValue(ind)
    # Skip the placeholder
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
        MagneticReadHead, :break_action,
        method,
        orig_ind,
        names_ssa, values_ssa)
    )
    # We now know how many statements we added so can set how far we are going to jump in the inital condition.
    statements[2] = Expr(:gotoifnot, stop_cond_ssa, ind + length(statements))
    push!(statements, stmt)  # last put im the original statement -- this is where we jump to
    return statements
end

"""
    enter_debug_statements_count(slot_created_ons, orig_ind)
returns the length of the corresponding `enter_debug_statements` call.
"""
function enter_debug_statements_count(slot_created_ons, orig_ind)
    # this function intentionally mirrors structure of enter_debug_statements
    # for ease of updating to match it
    n_statements = 4

    for slot_created_on in slot_created_ons
        if orig_ind > slot_created_on
            n_statements  += 4
        end
    end
    n_statements += 2
    return n_statements
end

"""
    instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
This is the transform for the debugger cassette pass.
it is the main method of this file, and calls all the ones defined earlier.
"""
function instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info

    slot_created_ons = created_on(reflection)
    extended_insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> stmt isa Expr ? enter_debug_statements_count(slot_created_ons, i) : nothing,
        (stmt, i, orig_i) -> enter_debug_statements(
            ir.slotnames, slot_created_ons, reflection.method,
            stmt, i, orig_i
        );
    )
    return ir
end

const handeval_pass = Cassette.@pass instrument!
