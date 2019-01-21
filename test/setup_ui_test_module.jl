using Mocking
Mocking.enable(force=true)

using Test
using MagneticReadHead

function make_readline_patch(text_queue)
    text_state=nothing
    return @patch function readline(io)
        text, text_state = (text_state==nothing ?
            iterate(text_queue) :
            iterate(text_queue, text_state)
        )
        println(text)
        sleep(0.1)
        return text
    end
end

include("demo.jl")


