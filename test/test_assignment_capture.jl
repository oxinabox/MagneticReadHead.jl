using MagneticReadHead
using Cassette

using MagneticReadHead: handeval_pass, HandEvalCtx

include("demo.jl")

ctx = HandEvalCtx(metadata=Dict(), pass=handeval_pass)
Cassette.recurse(ctx, eg1)

display(ctx.metadata)
