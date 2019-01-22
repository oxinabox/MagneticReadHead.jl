# MagneticReadHead ![https://www.tidyverse.org/lifecycle/#experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oxinabox.github.io/MagneticReadHead.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://oxinabox.github.io/MagneticReadHead.jl/latest)
[![Build Status](https://travis-ci.com/oxinabox/MagneticReadHead.jl.svg?branch=master)](https://travis-ci.com/oxinabox/MagneticReadHead.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/oxinabox/MagneticReadHead.jl?svg=true)](https://ci.appveyor.com/project/oxinabox/MagneticReadHead-jl)
[![Coveralls](https://coveralls.io/repos/github/oxinabox/MagneticReadHead.jl/badge.svg?branch=master)](https://coveralls.io/github/oxinabox/MagneticReadHead.jl?branch=master)


# Commands

`@iron_debug foo()`: run `foo()` inside the debugger.
When a breakpoint is hit, then you will be given an Iron REPL to work with-in,
allowing you to view/manipulate the arguments.

## Breakpoints

 - `set_breakpoint(f)`: Set a breakpoint on call to the function `f`



[![asciicast](https://asciinema.org/a/PnffnrsqEkX8Oum71KY9sWMue.svg)](https://asciinema.org/a/PnffnrsqEkX8Oum71KY9sWMue)


## MagneticReadHead Vs Rebugger
[Rebugger](https://github.com/timholy/Rebugger.jl) is the another debugging package for Julia.
Rebugger is a very nontraditional rebugger, MagneticReadHead is a lot closer to a traditional debugger.

They are complementary tools that can both be used in the same project.
Rebugger has has a user interface based on scooping the code of any function it steps into, into the REPL.
Then allow you to point your cursor at a function and step into that one.
Rebugger lets you edit the code at each step.
MagneticReadHead lets you run code to inspect variables or save data,
but you can not edit the code itself.

You can step backwards up the call-stack in Rebugger, MagneticReadHead does not support that (yet).
MagneticReadHead lets you set breakpoints, Rebugger does not support that (yet).

Rebugger is based on Revise.jl,
MagneticReadHead is based on Cassette.jl and uses Revise.jl as a helper library.
