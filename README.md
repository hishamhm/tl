
Teal
====

[![Build Status](https://travis-ci.org/teal-language/tl.svg?branch=master)](https://travis-ci.org/teal-language/tl)
[![Join the chat at https://gitter.im/dotnet/coreclr](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/teal-language/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This is the repository of **tl**, the compiler for Teal, a typed dialect of Lua.

## Introduction

Here are videos of talks given at FOSDEM 2019 and 2020 which discuss the
history of Lua and types, outline the motivations behind Teal and talk about
the project's progress:

* [Minimalism versus types (2019)](https://www.youtube.com/watch?v=OPyBQRndLUk)
* [Minimalistic typed Lua is here (2020)](https://www.youtube.com/watch?v=HfnjUCRzRKU)

## Installing

Install Lua and LuaRocks, then run:

```
luarocks install tl
```

This should put a `tl` command in your `$PATH` (run `eval $(luarocks path)` if
the LuaRocks-installed binaries are not in your `$PATH`)

## Running

Once `tl` is in your path, there are a few subcommands:

* `tl run script.tl` will run a Teal script.
* `tl check module.tl` will type check a Teal module, report any errors and
  quit.
* `tl gen module.tl` will check for syntax errors and
  generate a `module.lua` file in plain Lua with all type annotations
  stripped.
* `tl repl` lets you try out Teal on the command-line through an interactive
  REPL.
* `tl build` will compile all Teal files in the current or specified directory,
  according to the options in a `tlconfig.lua` file. See the documentation for more details.

## Documentation

You can learn more about programming with Teal in the [tutorial](docs/tutorial.md).

## Type definitions

We have a collaborative repository for type definitions of Lua libraries
at https://github.com/teal-language/teal-types — check it out and make your
contribution!

To use the definitions, simply place them on your module search path or use `tl
-I path/to/types/` and call `require("module")` in your code as usual. When run
from Teal, this will automatically search for and load the corresponding `.d.tl`
file containing the type definitions into the compiler during the type checking
phase.

## Text editor support

Teal language support is currently available for [Vim](https://github.com/teal-language/vim-teal) and [Visual Studio Code](https://github.com/teal-language/vscode-teal).

## Community

Join the chat on [Gitter](https://gitter.im/teal-language/community)!

Teal is a project started by [Hisham Muhammad](https://hisham.hm),
developed by a [growing number of contributors](https://github.com/teal-language/tl/graphs/contributors)
and is written using Teal itself!

## License

License is MIT, the same as Lua.
