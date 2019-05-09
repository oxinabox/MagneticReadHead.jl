#==
Instumenting Debugger Pass:

The purpose of this pass is to modify the IR code to instert debug statements.
One is inserted before each other statement in the IR.
Rough pseudocode for a Debug statment:
```
if should_break(statement)  # i.e. this breakpoint is active
    variables = Base.@locals()
    call break_action(variables)  # launch the debugging REPL etc.
end
```
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
    call_expr(mod:Module, func::Symbol, args...)
This function returns the IR exprression for calling the names function `func` from module `mod`, with the
given args. It is maked with `nooverdub` which will stop Cassette recursing into it.
"""
call_expr(mod::Module, func::Symbol, args...) = Expr(:call, Expr(:nooverdub, GlobalRef(mod, func)), args...)


"""
    enter_debug_statements(stmt, method::Method, ind::Int, orig_ind::Int)

This returns the IR code for a debug statement (as decribed at the top of this file).
This basically means creating code that checks if we `should_break` at this statement,
and if so works out what variable are defined, then passing those to the `break_action` call which will
show the dubugging prompt.

 - stmt: the original IR statement being debugged (i.e. the statement that will run after the debugger closes)
 - method: the method being instrumented
 - ind: the actual index in the code IR this is being  inserted at. This is where the SSAValues start from
 - orig_ind: the index in the original code IR for where this is being inserted. (before other debug statements were inserted above)
"""
function enter_debug_statements(stmt, method::Method, ind::Int, orig_ind::Int)
    return [
        call_expr(MagneticReadHead, :should_break, Expr(:contextslot), method, orig_ind),  # ind
        Expr(:gotoifnot, Core.SSAValue(ind), ind + 4), # ind + 1
        Expr(:locals),  # ind + 2
        call_expr( # ind + 3
            MagneticReadHead, :break_action, Expr(:contextslot), method, orig_ind, Core.SSAValue(ind + 2)
        ),
        stmt, # ind + 4
    ]
end

"""
    instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
This is the transform for the debugger cassette pass.
it is the main method of this file, and calls all the ones defined earlier.
"""
function instrument!(::Type{<:HandEvalCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info

    extended_insert_statements!(
        ir.code, ir.codelocs,
        (stmt, i) -> stmt isa Expr ? 5 : nothing,
        (stmt, i, orig_i) -> enter_debug_statements(stmt, reflection.method, i, orig_i),
    )
    return ir
end

const handeval_pass = Cassette.@pass instrument!
