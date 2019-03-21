# MagneticReadHead ![https://www.tidyverse.org/lifecycle/#maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
[![Build Status](https://travis-ci.com/oxinabox/MagneticReadHead.jl.svg?branch=master)](https://travis-ci.com/oxinabox/MagneticReadHead.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/oxinabox/MagneticReadHead.jl?svg=true)](https://ci.appveyor.com/project/oxinabox/MagneticReadHead-jl)
[![Coveralls](https://coveralls.io/repos/github/oxinabox/MagneticReadHead.jl/badge.svg?branch=master)](https://coveralls.io/github/oxinabox/MagneticReadHead.jl?branch=master)


# Commands

`@iron_debug foo()`: run `foo()` inside the debugger.
When a breakpoint is hit, then you will be given an Iron REPL to work with-in,
allowing you to view/manipulate the arguments.

Within this you can read (and write) variables,
 - Step-Next: to move to the next IR statement
 - Step-In: to debug in the next function call (assuming next is a function call)
 - Step-Out: to debug from the next statement the function that called the current function
 - Continue: proceed to next breakpoint
 - Abort: terminate running the debugger.

## Breakpoints

 - `set_breakpoint!([function|method])`: Set a breakpoint on call to the argument
 - `set_breakpoint!(filename, line number)`: Set a breakpoint on the given line in the given function
 - `set_nodebug!([function|method|module])`: Disable debugging in the given function/method/module
    - Not having debugging enabled for modules that are not between you and your breakpoints massively speeds up the running of your program.
 - `list_breakpoints()`, `list_nodebugs()`: list all the breakpoints/nodebugs
 - `rm_breakpoint!(arg...)`, `rm_nodebug!(args...)`: remove breakpoints/nodebugs. Takes same arguments as `set_...`.
 - `clear_breakpoints!()`, `clear_nodebugs!()`: remove all breakpoints/nodebugs.


[![asciicast](https://asciinema.org/a/DxgPaaLQQYVV5xXCMuwF5Aa36.svg)](https://asciinema.org/a/DxgPaaLQQYVV5xXCMuwF5Aa36)
