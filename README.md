# MagneticReadHead ![https://www.tidyverse.org/lifecycle/#maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
[![Build Status](https://travis-ci.com/oxinabox/MagneticReadHead.jl.svg?branch=master)](https://travis-ci.com/oxinabox/MagneticReadHead.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/oxinabox/MagneticReadHead.jl?svg=true)](https://ci.appveyor.com/project/oxinabox/MagneticReadHead-jl)
[![Coveralls](https://coveralls.io/repos/github/oxinabox/MagneticReadHead.jl/badge.svg?branch=master)](https://coveralls.io/github/oxinabox/MagneticReadHead.jl?branch=master)


# Commands

`@run foo()`: run `foo()` inside the debugger.
When a breakpoint is hit, then you will be given an Iron REPL to work with-in,
allowing you to view/manipulate the arguments.
`@enter foo()` performs similarly, after immediately breaking on the first line.

Within this you can read (and write) variables,
 - Step-Next: to move to the next IR statement
 - Step-In: to debug in the next function call (assuming next is a function call)
 - Step-Out: to debug from the next statement the function that called the current function
 - Continue: proceed to next breakpoint
 - Abort: terminate running the debugger.

## Breakpoints

 - `set_breakpoint!([function|method])`: Set a breakpoint on call to the argument
 - `set_breakpoint!(filename, line number)`: Set a breakpoint on the given line in the given function
 - `set_uninstrumented!([function|module])`: Disable debugging in the given function/module
    - Not having debugging enabled for modules/functions you do not need to debug massively speeds up the running of your program.
    - However, debugging is fully disabled for those modules/functions, so if those functions would then call functions you do want to debug (say by using `map`) then that will also not be caught by the debugger.
 - `list_breakpoints()`, `list_uninstrumenteds()`: list all the breakpoints/uninstrumenteds
 - `rm_breakpoint!(arg...)`, `rm_uninstrumented!(args...)`: remove breakpoints/uninstrumenteds. Takes same arguments as `set_...`.
 - `clear_breakpoints!()`, `clear_uninstrumenteds!()`: remove all breakpoints/uninstrumenteds.


[![asciicast](https://asciinema.org/a/DxgPaaLQQYVV5xXCMuwF5Aa36.svg)](https://asciinema.org/a/DxgPaaLQQYVV5xXCMuwF5Aa36)
