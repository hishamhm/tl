# Programming With Types in Teal

## Welcome to Teal!

In this tutorial, we will go through the basics so you can get up and running
type checking your Lua code, through the use of Teal, a typed dialect of Lua.

## Why Types

If you're already convinced about the idea of type checking, you may skip this
part. :)

The data in your program has types: Lua is a high-level language, so each
piece of data stored in the memory of the Lua virtual machine has a type:
number, string, function, boolean, userdata, thread, nil or table.

Your program is basically a series of manipulations of data of various types.
The program is correct when it does what it is supposed to do, and that will
only happen when data is matched with other data of the correct types, like
pieces of a puzzle: you can multiply a number by another number, but not by a
boolean; you can call a function, but not a string; and so on.

The variables of a Lua program, however, know nothing about types. You can put
any value in any variable at any time, and if you make a mistake and match
things incorrectly, the program will crash at runtime, or even worse: it will
misbehave... silently.

The variables of Teal do know about types: each variable has an assigned type
and will hold on to that type forever. This way, there's a whole class of
mistakes that the Teal compiler is able to warn you about before the program
even runs.

Of course, it cannot catch every possible mistake in a program, but it should
help you with things like typos in table fields, missing arguments and so on.
It will also make you be more explicit about what kind of data your program is
dealing with: whenever that is not obvious enough, the compiler will ask you
about it and have you document it via types. It will also constantly check
that this "documentation" is not out of date. Coding with types is like pair
programming with the machine.

## Installing tl

To run tl, the Teal compiler, you need a Lua environment. Install Lua and
LuaRocks (methods vary according to your operating system), and then run

```
luarocks install tl
```

If your environment is set up correctly, you should have a tl command
available now!

## Your first Teal program

Let's start with a simple example, which declares a type-safe function. Let's
call this example `add.tl`:

```
local function add(a: number, b: number): number
   return a + b
end

local s = add(1,2)
print(s)
```

You can type-check it with

```
tl check add.tl
```

You can convert it to Lua with

```
tl gen add.tl
```

This will produce add.lua. But you can also run it directly with

```
tl run add.tl
```

We can also write modules in Teal which we can load from Lua. Let's create our
first module:

```
local addsub = {}

function addsub.add(a: number, b: number): number
   return a + b
end

function addsub.sub(a: number, b: number): number
   return a - b
end

return addsub
```

We can generate addsub.lua with

```
tl gen addsub.tl
```

and then require the addsub module from Lua normally. Or we can load the Teal
package loader, which will allow require to load .tl files directly, without
having to run `tl gen` first:

```
$ rm addsub.lua
$ lua
> tl = require("tl")
> tl.loader()
> addsub = require("addsub")
> print (addsub.add(10, 20))
```

When loading and running the Teal module from Lua, there is no type checking!
Type checking will only happen when you run `tl check` or load a program with
`tl run`.

## Types in Teal

Teal is a dialect of Lua. This tutorial will assume you already know Lua, so
we'll focus on the things that Teal adds to Lua, and those are primarily type
declarations.

Types in Teal are more specific than in Lua, because Lua tables are so general.
These are the types in Teal:

* nil
* boolean
* number
* string
* userdata
* function
* record
* arrayrecord
* map
* enum
* any

## Local variables

Variables in Teal have types. So, when you declare a variable with the `local`
keyword, you need to provide enough information so that the type can be determined.
For this reason, it is not valid in Teal to declare a variable with no type at all
like this:

```
local x -- Error! What is this?
```

There are two ways, however, to give a variable a type:

* through declaration
* through initialization

Declaration is done writing a colon and a type. When declaring multiple
variables at once, each variable should have its own type:

```
local s: string
local r, g, b: number, number, number
```

You don't need to write the type if you are initializing the variable on
creation:

```
local s = "hello"
local r, g, b = 0, 128, 128
local ok = true
```

If you initialize a variable with nil and don't give it any type, this doesn't
give any useful information to work with (you don't want your variable to
be always nil throughout the lifetime of your program, right?) so you will
have to declare the type explicitly:

```
local n: number = nil
```

This is the same as omitting the ` = nil`, like in plain Lua, but it gives the
information the Teal program needs. Every type in Teal accepts nil as a valid
value, even if, like in Lua, attempting to use it with some operations would
cause a runtime error, so be aware!

## Arrays

The simplest structured type in Teal is the array. An array is a Lua table where
all keys are numbers and all values are of the same type. It is in fact a Lua
sequence, and as such it has the same semantics as Lua sequences for things
like the # operator and the use of the `table` standard library.

Arrays are described with curly brace notation, and can be denoted via
declaration or initialization:

```
local values: {number}
local names = {"John", "Paul", "George", "Ringo"}
```

Note that values was initialized to nil. To initialize it with an empty table,
you have to do so explicitly:

```
local prices: {number} = {}
```

Creating empty tables to fill an array is so common that Teal includes a naive
inference logic to support determining the type of empty tables with no
declaration. The first array assignment to an empty table, reading the code
top-to-bottom, determines its type. So this works:

```
local lengths = {}
for i, n in ipairs(names) do
   table.insert(lengths, #n) -- this makes the  lengths table a {number}
end
```

Note that this works even with library calls. If you make assignments of
conflicting types, the tl compiler will tell you in its error message from
which point in the program it originally got the idea that the empty table was
an array of that incompatible type.

Note also that we didn't need to declare the types of i and n in the above
example: the for statement can infer those from the return type of the
iterator function produced by the ipairs call. Feeding ipairs with a {string}
means that the iteration variables of the ipairs loop will be number and
string. For an example of a custom user-written iterator, see the [Functions](#functions)
section below.

Note that all items of the array are expected to be of the same type. If you
need to deal with heterogeneous arrays, you will have to use the cast operator
`as` to force the elements to their desired types. Keep in mind that when you
use `as`, Teal will accept whatever type you use, meaning that it can also hide
incorrect usage of data:

```
local sizes: {number} = {34, 36, 38}
sizes[#sizes + 1] = true as number -- this does not perform a conversion! it will just stop tl from complaining!
local sum = 0
for i = 1, #sizes do
   sum = sum + sizes[i] -- will crash at runtime!
end
```

## Maps

Another very common type of table is the map: a table where all keys of one
given type, and all values are of another given type, which may or may not be
the same as that of the keys. Maps are notated with curly brackets and a
colon:

```
local populations: {string:number}
local complicated: {Object:{string:{Point}}} = {}
local modes = { -- this is {boolean:number}
   [false] = 127,
   [true] = 230,
}
```

In case you're wondering, yes, an array is functionally equivalent to a map
with keys of type number.

When creating a map with string keys you may want to declare its type
explicitly, so it doesn't get mistaken for a record. Records are freely usable
as maps with string keys when all its fields are of the same type, so you
wouldn't have to annotate the type to get a correct program, but the
annotation will help the compiler produce better error messages if any errors
occur involving this variable:

```
local is_vowel: {string:boolean} = {
   a = true,
   e = true,
   i = true,
   o = true,
   u = true,
}
```

For now, if you have to deal with heterogeneous maps (that is, Lua tables with
a mix of types in their keys or values), you'll have to use casts.

## Records

Records are the third major type of table supported in Teal. They represent
another super common pattern in Lua code, so much that Lua includes special
syntax for it (the dot and colon notations for indexing): tables with a set of
string keys known in advance, each of them corresponding to a possibly
different value type. Records (named as such in honor of the Algol/Pascal
tradition from which Lua gets much of the feel of its syntax) can be used
to represent objects, "structs", etc.

To declare a record variable you need to refer by name to a record type, which
describes the set of valid fields (keys of type string and their values of
specific types) this record can take.

```
local Point = record
   x: number
   y: number
end
```

Tables that match the shape of the record type will be accepted as an
initializer of variables declared with the record type:

```
local p: Point = { x = 100, y = 100 }
```

This, however, won't work:

```
local p1 = { x = 100, y = 100 }
local p2: Point = p1 -- Error!
```

Just because a table has fields with the same names and types, it doesn't mean
that it is a Point. A Distance could also be defined as fields x and y, but a
distance is not a point.

You can always force a type, though, using the `as` operator:

```
local p2 = p1 as Point -- Ok, I'll trust you...
```

Note we didn't even have to declare the type of p2. The `as` expression resolves
as a Point, so p2 picks up that type.

You can also declare record functions after the record definition using the
regular Lua colon or dot syntax, as long as you do it in the same scope block
where the record type is defined:

```
function Point.new(x: number, y: number): Point
   local self: Point = setmetatable({}, { __index = Point })
   self.x = x or 0
   self.y = y or 0
   return self
end

function Point:move(dx: number, dy: number)
   self.x = self.x + dx
   self.y = self.y + dy
end
```

When using the function, don't worry: if you get the colon or dot mixed up, tl
will detect and tell you about it!

If you want to define the function in a later scope (for example, if it is a
callback to be defined by users of a module you are creating), you can declare
the type of the function field in the record and fill it later from anywhere:

```
local Obj = record
   location: Point
   draw: function(Obj)
end
```

A record can also have an array part, making it an "arrayrecord". The
following is an arrayrecord. You can use it both as a record, accessing its
fields by name, and as an array, accessing its entries by number.

```
local Node = record
   {Node}
   weight: number
   name: string
end
```

Note the recursive definition in the above example: records of type Node can
be organized as a tree using its array part.

Finally, records can contain nested record type definitions. This is useful
when exporting a module as a record, so that the types created in the module
can be used by the client code which requires the module.

```
local http = record

   Response = record
      status_code: number
   end

   get: function(string): Response
end
```

### Tagged records

Teal supports a very simple form of subtyping for records: tagged records.
You can specify a field of type number, string or boolean to act as a _tag_
for a parent record type, and then define children record types that extend
the parent record discriminating them based on the tag. This is how it
works:

```
local Widget = record
   tag widget_type: string

   x: number
   y: number
end

local Button = record is Widget with widget_type = "button"
   text: string
end

local Field = record is Widget with widget_type = "field"
   width: number
   input: string
end

local function show_widget(w: Widget)
   if w is Button then
      draw_button(w.x, w.y, w.text)
   elseif w is Field then
      draw_field(w.x, w.y, w.width, w.input)
   end
end
```

## Generics

Teal supports a simple form of generics that is useful enough for dealing
collections and algorithms that operate over abstract data types.

You can use type variables wherever a type is used, and you can declare them
in both functions and records. Here's an example of a generic function:

```
local function keys<K,V>(xs: {K:V}):{K}
   local ks = {}
   for k, v in pairs(xs) do
      table.insert(ks, k)
   end
   return ks
end

local s = keys({ a = 1, b = 2 }) -- s is {string}
```

we declare the type variables in angle brackets and use them as types. Generic
records are declared and used like this:

```
local Tree = record<X>
   {Tree<X>}
   item: X
end

local t: Tree<number> = {
   item: 1,
   { item: 2 },
   { item: 3, { item: 4 } },
}
```

## Enums

Enums are a restricted type of string value, which represent a common practice
in Lua code: using a limited set of string constants to describe an
enumeration of possible values.

You describe an enum like this:

```
local Direction = enum
   "north"
   "south"
   "east"
   "west"
end
```

Variables and arguments of this type will only accept values from the declared
list. Enums are freely convertible to strings, but not the other way around.
You can of course promote an arbitrary string to an enum with a cast.

## Functions

Functions in Teal should work like you expect, and we have already showed
various examples.

You can declare nominal function types, like we do for records, to avoid
longwinded type declarations, especially when declaring functions that take
callbacks. This is done with using `functiontype`, and they can be generic as
well:

```
local Comparator = functiontype<T>(T, T): boolean

local function mysort<A>(arr: {A}, cmp: Comparator<A>)
   -- ...
end
```

Another thing to know about function declarations is that you can parenthesize
the declaration of return types, to avoid ambiguities when using nested
declarations and multiple returns:

```
f: function(function():(number, number), number)
```

You can declare functions that generate iterators which can be used in
`for` statements: the function needs to produce another function that iterates.
This is an example [taken the book "Programming in Lua"](https://www.lua.org/pil/7.1.html):

```
function allwords(): (function(): string)
   local line = io.read()
   local pos = 1
   return function(): string
      while line do
         local s, e = line:find("%w+", pos)
         if s then
            pos = e + 1
            return line:sub(s, e)
         else
            line = io.read()
            pos = 1
         end
      end
      return nil
   end
end

for word in allwords() do
   print(word)
end
```

The only changes made to the code above were the addition of type signatures
in both function declarations.

### Variadic functions

Just like in Lua, some functions in Teal may receive a variable amount of arguments. Variadic functions can be declared by specifying `...` as the last argument of the function:

```
function test(...: number)
	print(...)
end

test(1, 2, 3)
```

In case your function returns a variable amount of values, you may also declare variadic return types by using the following syntax:

```
function test(...: number): number...
	return ...
end

local a, b, c = test(1, 2, 3)
```

## Union types

The language supports a basic form of union types. You can register a type
that is a logical "or" of multiple types: it will accept values from multiple
types, and you can discriminate them at runtime.

You can declare union types like this:

```
local a: string | number | MyRecord
local b: {boolean} | MyEnum
local c: number | {string:number}
```

To use a value of this type, you need to discriminate the variable, using
the `is` operator, which takes a variable of a union type and one of its types:

```
local a: string | number | MyRecord

if a is string then
   print("Hello, " .. a)
elseif a is number then
   print(a + 10)
else
   print(a.my_record_field)
end
```

As you can see in the example above, each use of the `is` operator causes the
type of the variable to be properly narrowed to the type tested in its
respective block.

The flow analysis of `is` also takes effect within expressions:

```
local a: string | number

local x: number = a is number and a + 1 or 0
```

### Current limitations of union types

In the current version, there are two main limitations regarding support
for union types in Teal.

The first one is that the `is` operator always matches a variable, not arbitrary
expressions. This limitation is there to avoid aliasing


Since code generation for the `is` operator used for
discrimination of union types translates into a runtime `type()` check, we can
only discriminates across primitive types and at most one table type.

This means that these unions not accepted:

```
local invalid1: MyRecord | MyOtherRecord
local invalid2: {string} | {number}
local invalid3: {string} | {string:string}
local invalid4: {string} | MyRecord
```

Also, since `is` checks for enums currently also translate into
`type()` checks, this means they are indistinguishable from strings
at runtime. So, for now this is also not accepted:

```
local invalid5: string | MyEnum
```

This restriction between strings and enums may be removed in the future.
The restriction on records may also be lifted in the future if we start
registering metatables for them (it may be that a future release may
start supporting unions of records _with_ metatables, if we add a form
of record constructors with metatables).

## The type `any`

The type `any`, as it name implies, accepts any value, like a
dynamically-typed Lua variable. However, since Teal doesn't know anything
about this value, there isn't much you can do with it, besides comparing for
equality and against nil, and casting it into other values using the `as`
operator.

Some Lua libraries use complex dynamic types that can't be easily represented
in Teal. In those cases, using `any` and making explicit casts is our last
resort.

## Const variables

Teal supports the `<const>` annotation, like that of Lua 5.4 (it works at compile
time, even if you're running a different version of Lua). Do note however that
this is an annotation for variables, and not values: the contents of a value
set to a const variable are not constant:

```
local xs <const> = {1,2,3}
xs[1] = 999 -- ok! the array is not frozen
xs = {} -- Error! can't replace the array in variable xs
```

## Global variables

Unlike in Lua, global variables in Teal need to be declared, because the
compiler needs to know its type. It also allows the compiler to catch typos in
variable names, because an invalid name will not be assumed to be some unknown
global that happens to be nil.

You declare global variables in Teal using `global`, like this, doing
declaration and/or assignment:

```
global n: number
global m: {string:boolean} = {}
global hi = function(): string
   return "hi"
end
```

You can also declare global types, which are visible across modules, as long
as their definition has been previously required:

```
-- mymod.tl
local mymod = {}

global MyPoint = record
   x: number
   y: number
end

return mymod
```

```
-- main.tl
local mymod = require("mymod")

local function do_something(p: MyPoint)
   -- ...
end
```

## The Standard Library

tl supports a fair subset the Lua 5.3 standard library (even in other Lua
versions, using compat-5.3), avoiding 5.3-isms that are difficult to reproduce
in other Lua implementations.

It declares all entries of the standard library as `<const>`, and assumes that
Lua libraries don't modify it. If your environment modifies the Lua standard
library with incompatible behaviors, tl will be oblivious to it and you're on
your own.

## Using tl with Lua

You can use tl to type-check not only Teal programs, but Lua programs too! When
type-checking Lua files (with the .lua extension or a Lua #! identifier), the
type-checker adds support for an extra type:

* unknown

which is the type of all non-type-annotated variables. This means that in a
Lua file you can declare untyped variables as usual:

```
local x -- invalid in .tl, valid but unknown in .lua
```

When processing .lua files, tl will report no errors involving unknown
variables. Anything pertaining unknown variables is, well, unknown. Think of
.tl files as the safer, "strict mode", and .lua files as the looser "lax
mode". However, even a Lua file with no annotations whatsoever will still have
a bunch of types: every literal value (numbers, strings, arrays, etc.) has a
type. Variables initialized on declaration are also assumed to keep consistent
types like in Teal. The types of the Lua standard library are also known to tl:
for example, the compiler knows that if you run table.concat on a table, the
only valid output is a string.

Plus, requiring type-annotated modules from your untyped Lua program will also
help tl catch errors: tl can check the types of calls from Lua to functions
declared as Teal modules, and will report errors as long as the input arguments
are not of type unknown.

You can also create declaration files to annotate the types of third-party Lua
modules, including C Lua modules. If you create a file with the .d.tl
extension, that will be used as a source of type information when type
checking with `tl check`, even though the real Lua module will be loaded
instead when requiring the module from Lua or `tl run`.

Having unknown variables in a Lua program is not an error, but it may hide
errors. Running `tl check` on a Lua file will report every unknown variable in
a separate list from errors. This allows you to see which parts of your
program tl is helpless about and help you incrementally add type annotations
to your code.

Note that even though adding type annotations to .lua files makes it invalid
Lua, you can still do so and load them from the Lua VM once the Teal package
loader is installed by calling tl.loader().

