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
The reality is a bit more complicated, as we actually workouit what is defined at
compile time.
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
    @inbounds for i in 1:length(code)
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
    @inbounds for (src_i, addedstmts) in worklist
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
    solve_isdefined_map(ci, nargs)
Returns a vector which maps from statement index
to a list of slot_ids that are definately defined at that index
"""
solve_isdefined_map(reflection) = solve_isdefined_map(reflection.code_info, reflection.method.nargs)
function solve_isdefined_map(ci, nargs)
    @assert nargs >= 1  # must be at least one for #self
    cfg = Core.Compiler.compute_basic_blocks(ci.code)
    domtree = Core.Compiler.construct_domtree(cfg)

    isdefined_on = Vector{Vector{Int}}(undef, length(ci.code))
    function proc_block!(cur_block_ii, defined_slots)
        block = cfg.blocks[cur_block_ii]
        domnode = Core.Compiler.getindex(domtree.nodes, cur_block_ii)
        for stmt_ii in block.stmts.start : block.stmts.stop
            # We want to know what has been defined before we run this statement
            # i.e. what can occur on RHS of assigment or in a call
            isdefined_on[stmt_ii] = defined_slots

            # Now update `defined_slots` for future statements
            stmt = ci.code[stmt_ii]
            if isexpr(stmt, :(=)) && stmt.args[1] isa Core.SlotNumber
                id = stmt.args[1].id
                if id ∉ defined_slots
                    defined_slots = copy(defined_slots)
                    defined_slots = push!(defined_slots, id)
                end
            end
        end
        Core.Compiler.foreach(domnode.children) do block_ii
            proc_block!(block_ii, defined_slots)
        end
    end

    # Initial defined slots start from 2 rather than 1 too skip #self#
    proc_block!(1, collect(2:nargs))
    return isdefined_on
end

"""
    call_expr([mod], func, args...)

This function returns the IR expression for calling the given function, with the
given args. It is maked with `nooverdub` which will stop Cassette recursing into it.
"""
call_expr(mod::Module, func::Symbol, args...) = call_expr(GlobalRef(mod, func), args...)
call_expr(f, args...) = Expr(:call, Expr(:nooverdub, f), args...)


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
@inline function enter_debug_statements(
    slotnames, isdefined_map, method::Method,
    stmt, ind::Int, orig_ind::Int
    )

    stmt_count = 6
    defined_slotids = isdefined_map[orig_ind]
    statements = Vector{Any}(undef, stmt_count)
    statements[1] = call_expr(MagneticReadHead, :should_break, method, orig_ind)
    statements[2] = Expr(:gotoifnot, Core.SSAValue(ind), ind + stmt_count - 1)  # go to last statement (i.e. the original stmt)
    statements[3] = Tuple(slotnames[defined_slotids])
    statements[4] = call_expr(Core, :tuple, Core.SlotNumber.(defined_slotids)...)
    names_ssa = Core.SSAValue(ind+2)
    values_ssa = Core.SSAValue(ind+3)
    statements[5] = call_expr(
        MagneticReadHead, :break_action,
        method,
        orig_ind,
        names_ssa, values_ssa
    )
    statements[6] = stmt  # last put in the original statement -- this is where we jump to
    #Core.println(statements)
    return statements
end


"""
    instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
This is the transform for the debugger cassette pass.
it is the main method of this file, and calls all the ones defined earlier.
"""
@inline function instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info

    isdefined_map = solve_isdefined_map(reflection)
    extended_insert_statements!(
        ir.code, ir.codelocs,
        (stmt, ii) -> begin
            # We instrument every new line, before the line.
            # So the first statement of the line is the one we replace
            stmt isa Expr || return nothing
            ii>1 && @inbounds(ir.codelocs[ii]==ir.codelocs[ii-1]) && return nothing
            return 6
        end,
        (stmt, i, orig_i) -> enter_debug_statements(
            ir.slotnames, isdefined_map, reflection.method,
            stmt, i, orig_i
        );
    )
    return ir
end

const handeval_pass = Cassette.@pass instrument!
