local util = require("spec.util")

describe("generic function", function()
   it("argument list can be empty on declaration", util.check [[
      local type ParseItem = function<>(number): number

      local x: ParseItem = function(i: number): number
         return i
      end
   ]])

   it("argument list can be empty on instance", util.check [[
      local type ParseItem = function<>(number): number

      local x: ParseItem<> = function(i: number): number
         return i
      end
   ]])

   it("can declare a generic function type", util.check [[
      local type ParseItem = function<T>(number): T
   ]])

   it("can declare a function using the function type as an argument", util.check [[
      local type ParseItem = function<T>(number): T

      local function parse_list<T>(list: {T}, parse_item: ParseItem): number, T
         return 0, list[1]
      end
   ]])

   it("can use the typevar in the function body", util.check [[
      local type ParseItem = function<T>(number): T

      local function parse_list<T>(list: {T}, parse_item: ParseItem): number, {T}
         local ret: {T} = {}
         local n = 0
         return n, ret
      end
   ]])

   it("can use the function along with a typevar", util.check [[
      local type Id = function<a>(a): a

      local function string_id(a: string): string
         return a
      end

      local function use_id<T>(v: T, id: Id<T>): T
         return id(v)
      end

      local x: string = use_id("hello", string_id)
   ]])

   it("does not mix up typevars with the same name in different scopes", util.check [[
      local type Convert = function<a, b>(a): b

      local function id<a>(x: a): a
         return x
      end

      local function convert_num_str(n: number): string
         return tostring(n)
      end

      local function convert_str_num(s: string): number
         return tonumber(s)
      end

      local function use_conv<X, Y>(x: X, cvt: Convert<X, Y>): Y
         return id(cvt(x))
      end

      print(use_conv(122.0, convert_num_str) .. "!")

      print(use_conv("123", convert_str_num) + 123.0)
   ]])

   it("catches incorrect typevars, does not mix up multiple uses", util.check_type_error([[
      local type Convert = function<a, b>(a): b

      local function convert_num_str(n: number): string
         return tostring(n)
      end

      local function convert_str_num(s: string): number
         return tonumber(s)
      end

      local function use_conv<X,Y>(x: X, cvt: Convert<X, Y>, tvc: Convert<X, Y>): Y -- tvc is not flipped!
         return cvt(tvc(cvt(x)))
      end

      print(use_conv(122.0, convert_num_str, convert_str_num) .. "!")
   ]], {
      { y = 15, x = 46, msg = "argument 3: argument 1: got string, expected number" }
   }))

   it("will catch if resolved typevar does not match", util.check_type_error([[
      local type Id = function<a>(a): a

      local function string_id(a: string): string
         return a
      end

      local function use_id<T>(v: T, id: Id<T>): T
         return id(v)
      end

      local x: number = use_id("hello", string_id)
   ]], {
      { msg = "got string, expected number" }
   }))

   it("can use the function along with an indirect typevar", util.check [[
      local type Id = function<a>(a): a

      local function string_id(a: string): string
         return a
      end

      local function use_id<T>(v: {T}, id: Id<T>): T
         return id(v[1])
      end

      local x: string = use_id({"hello"}, string_id)
   ]])

   it("will catch if resolved indirect typevar does not match", util.check_type_error([[
      local type Id = function<a>(a): a

      local function string_id(a: string): string
         return a
      end

      local function use_id<T>(v: {T}, id: Id<T>): T
         return id(v[1])
      end

      local x: number = use_id({"hello"}, string_id)
   ]], {
      { msg = "got string, expected number" }
   }))

   it("can use the function along with an indirect typevar", util.check [[
      local type ParseItem = function<X>(number): X

      local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
         local ret: {T} = {}
         local n = 0
         for i, t in ipairs(list) do
            n = i
            table.insert(list, parse_item(i))
         end
         return n, ret
      end

      local type Node = record
         foo: number
      end

      local nodes: {Node} = {}

      local function parse_node(n: number): Node
         return { foo = n }
      end

      local x, result: number, {Node} = parse_list(nodes, parse_node)
   ]])

   it("can use a typevar from an argument as the function return type", util.check [[
      local function parse_list<T>(list: {T}): T
         return list[1]
      end
   ]])

   it("will catch if typevar is unbound", util.check_type_error([[
      local function parse_list<T>(list: {T}): T
         return true
      end
   ]], {
      { msg = "got boolean, expected T" }
   }))

   it("will accept if typevar is bound at a higher level", util.check [[
      local function fun<T>()
         local function parse_list<T>(list: {T}): T
            return list[1]
         end
      end
   ]])

   it("will catch if return value does not match the typevar", util.check_type_error([[
      local function parse_list<T>(list: {T}): T
         return true
      end
   ]], {
      { msg = "expected T" }
   }))

   it("will catch if argument value does not match the typevar", util.check_type_error([[
      local type Output = record
         {string}
         x: number
      end

      local function insert<a>(list: {a}, item: a)
         table.insert(list, item)
      end

      local out: Output = { x = 1 }
      local out2: Output = { x = 2 }
      insert(out, out2)
   ]], {
      { msg = "got Output, expected string" }
   }))

   it("will catch if resolved typevar does not match", util.check_type_error([[
      local type ParseItem = function<V>(number): V

      local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
         local ret: {T} = {}
         local n = 0
         for i, t in ipairs(list) do
            n = i
            table.insert(list, parse_item(i))
         end
         return n, ret
      end

      local type Node = record
         foo: number
      end

      local type Other = record
         bar: string
      end

      local nodes: {Node} = {}

      local function parse_node(n: number): Node
         return { foo = n }
      end

      local x, result: number, Other = parse_list(nodes, parse_node)
   ]], {
      { msg = "got {Node}, expected Other" }
   }))

   it("can map one typevar to another", util.check [[
      local type ParseItem = function<V>(number): V

      local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
         local ret: {T} = {}
         local n = 0
         for i, t in ipairs(list) do
            n = i
            table.insert(list, parse_item(i))
         end
         return n, ret
      end

      local type Node = record
         foo: number
      end

      local nodes: {Node} = {}

      local function parse_node(n: number): Node
         return { foo = n }
      end

      local x, result: number, {Node} = parse_list(nodes, parse_node)
   ]])

   it("checks that missing typevars are caught", util.check_type_error([[
      local type Node = record
      end

      local type VisitorCallbacks = record<X, Y>
      end

      local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
      end

      local function pretty_print_ast(ast: Node): string
         local visit_node: {string:VisitorCallbacks<Node, string>} = {}
         local visit_type: {string:VisitorCallbacks<Type, string>} = {}
         return recurse_node(ast, visit_node, visit_type)
      end
   ]], {
      { msg = "unknown type Type", y = 7, x = 134 },
      { msg = "unknown type Type", y = 12, x = 53 },
   }))

   it("propagates resolved typevar in return type", util.check [[
      local type Node = record
      end

      local type Type = record
      end

      local type VisitorCallbacks = record<N, X>
      end

      local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
      end

      local function pretty_print_ast(ast: Node): string
         local visit_node: {string:VisitorCallbacks<Node, string>} = {}
         local visit_type: {string:VisitorCallbacks<Type, string>} = {}
         return recurse_node(ast, visit_node, visit_type)
      end
   ]])

   it("checks that typevars that appear in multiple arguments must match, pass", util.check [[
      local type Node = record
      end

      local type Type = record
      end

      local type VisitorCallbacks = record<X, Y>
      end

      local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
      end

      local function pretty_print_ast(ast: Node): string
         local visit_node: {string:VisitorCallbacks<Node, string>} = {}
         local visit_type: {string:VisitorCallbacks<Type, string>} = {}
         return recurse_node(ast, visit_node, visit_type)
      end
   ]])

   it("checks that typevars that appear in multiple arguments must match, fail", util.check_type_error([[
      local type Node = record
      end

      local type Type = record
      end

      local type VisitorCallbacks = record<X, Y>
      end

      local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>})
      end

      local function pretty_print_ast(ast: Node): string
         local visit_node: {string:VisitorCallbacks<Node, string>} = {}
         local visit_type: {string:VisitorCallbacks<Type, number>} = {}
         recurse_node(ast, visit_node, visit_type)
      end
   ]], {
      { x = 40, msg = "argument 3: type parameter <T>: got number, expected string" }
   }))

   it("inference trickles down to function arguments, pass", util.check [[
      local type R = record
         arch: string
      end
      local data: {R} = {
         { arch = "foo" },
         { arch = "bar" },
      }
      table.sort(data, function(a:R,b:R):boolean return a.arch < b.arch end)
   ]])

   it("inference trickles down to function arguments, pass", util.check_type_error([[
      local type R = record
         arch: string
      end
      local type S = record
         different: string
      end
      local data: {R} = {
         { arch = "foo" },
         { arch = "bar" },
      }
      table.sort(data, function(a:R,b:S):boolean return a.arch < b.different end)
   ]], {
      { msg = "argument 2" }
   }))

   it("does not leak an unresolved generic type", function()
      local _, ast = util.check([[
         function mypairs<a, b>(map: {a:b}): (a, b)
         end

         local _, resolved   = mypairs({["hello"] = true})
         local _, unresolved = mypairs({})
      ]])()

      -- resolved
      assert.same("string",  ast[2].exps[1].type[1].typename)
      assert.same("boolean", ast[2].exps[1].type[2].typename)
      -- unresolved
      assert.same("invalid", ast[3].exps[1].type[1].typename)
      assert.same("invalid", ast[3].exps[1].type[2].typename)
   end)

   it("does not produce a recursive type", util.lax_check([[
      function mypairs<a, b>(map: {a:b}): (a, b)
      end
      function myipairs<a>(array: {a}): (a)
      end

      local _, xs = mypairs(xss)
      local _, x = mypairs(xs)
      local u = myipairs({})
      local v = x[u]
      _, v = next(v)
   ]], {
      { msg = "xss" },
      { msg = "_" },
      { msg = "xs" },
      { msg = "_" },
      { msg = "x" },
      { msg = "u" },
      { msg = "v" },
   }))

   pending("check that 'any' matches any type variable", util.check [[
      local function map<X, Y>(xs: {X}, f: function(X):Y): {Y}
         local rs = {}
         for i, v in ipairs(xs) do
            rs[i] = f(v)
         end
         return rs
      end

      local words = { "10", "20" }
      -- works if I use tonumber as function(string):number
      local numbers = map(words, tonumber)

      for _, n in ipairs(numbers) do
         print(n)
      end
   ]])

   it("generic function definitions do not leak type variables (#322)", util.check [[
      local function my_unpack<T>(_list: {T}, _x: number, _y: number): T...
      end
      local _tbl_unpack = my_unpack or table.unpack
      local _map: {string:number} = setmetatable(assert({}), { __mode = "k" })
   ]])

   it("nested uses of generic functions using the same names for type variables don't cause conflicts", util.check [[
      local function pcall1<A, B>(f: function(A):(B), a: A): boolean, B
         return true, f(a)
      end

      local function pcall2<A, A2, B, B2>(f: function(A, A2):(B, B2), a: A, a2: A2): boolean, B, B2
         return true, f(a, a2)
      end

      local function greet(s: string): number
         print(s .. "!")
         return #s
      end

      local pok1, pok2, msg = pcall2(pcall1, greet, "hello")

      print(pok1)
      print(pok2)
      print(msg)
   ]])
end)

