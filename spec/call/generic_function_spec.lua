local tl = require("tl")
local util = require("spec.util")

describe("generic function", function()
   it("can declare a generic functiontype", function()
      -- pass
      local tokens = tl.lex([[
         local ParseItem = functiontype<T>(number): T
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("can declare a function using the functiontype as an argument", function()
      -- pass
      local tokens = tl.lex([[
         local ParseItem = functiontype<T>(number): T

         local function parse_list<T>(list: {T}, parse_item: ParseItem): number, T
            return 0, list[1]
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("can use the typevar in the function body", function()
      -- pass
      local tokens = tl.lex([[
         local ParseItem = functiontype<T>(number): T

         local function parse_list<T>(list: {T}, parse_item: ParseItem): number, {T}
            local ret: {T} = {}
            local n = 0
            return n, ret
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("can use the function along with a typevar", function()
      -- pass
      local tokens = tl.lex([[
         local Id = functiontype<a>(a): a

         local function string_id(a: string): string
            return a
         end

         local function use_id<T>(v: T, id: Id<T>): T
            return id(v)
         end

         local x: string = use_id("hello", string_id)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("does not mix up typevars with the same name in different scopes", function()
      -- pass
      local tokens = tl.lex([[
         local Convert = functiontype<a, b>(a): b

         local function id<a>(x: a): a
            return x
         end

         local function convert_num_str(n: number): string
            return tostring(n)
         end

         local function use_conv<X, Y>(x: X, cvt: Convert<X, Y>): Y
            return id(cvt(x))
         end

         print(use_conv(122, convert_num_str) .. "!")
      ]])
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same({}, syntax_errors)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("catches incorrect typevars, does not mix up multiple uses", function()
      -- fail
      local tokens = tl.lex([[
         local Convert = functiontype<a, b>(a): b

         local function convert_num_str(n: number): string
            return tostring(n)
         end

         local function convert_str_num(s: string): number
            return tonumber(s)
         end

         local function use_conv<X,Y>(x: X, cvt: Convert<X, Y>, tvc: Convert<X, Y>): Y -- tvc is not flipped!
            return cvt(tvc(cvt(x)))
         end

         print(use_conv(122, convert_num_str, convert_str_num) .. "!")
      ]])
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same({}, syntax_errors)
      local errors = tl.type_check(ast, nil, "bla.tl")
      assert.same(1, #errors)

      assert.match("argument 3: argument 1: got string, expected number", errors[1].msg, 1, true)
      assert.same(15, errors[1].y)
      assert.same(47, errors[1].x)
   end)
   it("will catch if resolved typevar does not match", function()
      -- pass
      local tokens = tl.lex([[
         local Id = functiontype<a>(a): a

         local function string_id(a: string): string
            return a
         end

         local function use_id<T>(v: T, id: Id<T>): T
            return id(v)
         end

         local x: number = use_id("hello", string_id)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got string, expected number", errors[1].msg, 1, true)
   end)

   it("can use the function along with an indirect typevar", function()
      -- pass
      local tokens = tl.lex([[
         local Id = functiontype<a>(a): a

         local function string_id(a: string): string
            return a
         end

         local function use_id<T>(v: {T}, id: Id<T>): T
            return id(v[1])
         end

         local x: string = use_id({"hello"}, string_id)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("will catch if resolved indirect typevar does not match", function()
      -- pass
      local tokens = tl.lex([[
         local Id = functiontype<a>(a): a

         local function string_id(a: string): string
            return a
         end

         local function use_id<T>(v: {T}, id: Id<T>): T
            return id(v[1])
         end

         local x: number = use_id({"hello"}, string_id)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got string, expected number", errors[1].msg, 1, true)
   end)


   it("can use the function along with an indirect typevar", function()
      -- pass
      local tokens = tl.lex([[
         local ParseItem = functiontype<X>(number): X

         local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
            local ret: {T} = {}
            local n = 0
            for i, t in ipairs(list) do
               n = i
               table.insert(list, parse_item(i))
            end
            return n, ret
         end

         local Node = record
            foo: number
         end

         local nodes: {Node} = {}

         local function parse_node(n: number): Node
            return { foo = n }
         end

         local x, result: number, {Node} = parse_list(nodes, parse_node)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("can use a typevar from an argument as the function return type", function()
      -- ok
      local tokens = tl.lex([[
         local function parse_list<T>(list: {T}): T
            return list[1]
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(0, #errors)
   end)
   it("will catch if typevar is unbound", function()
      -- fail
      local tokens = tl.lex([[
         local function parse_list<T>(list: {T}): T
            return true
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got boolean, expected T", errors[1].msg, 1, true)
   end)
   it("will accept if typevar is bound at a higher level", function()
      -- fail
      local tokens = tl.lex([[
         local function fun<T>()
            local function parse_list<T>(list: {T}): T
               return list[1]
            end
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(0, #errors)
   end)
   it("will catch if return value does not match the typevar", function()
      -- fail
      local tokens = tl.lex([[
         local function parse_list<T>(list: {T}): T
            return true
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got boolean, expected T", errors[1].msg, 1, true)
   end)
   it("will catch if argument value does not match the typevar", function()
      -- fail
      local tokens = tl.lex([[
         local Output = record
            {string}
            x: number
         end

         local function insert<a>(list: {a}, item: a)
            table.insert(list, item)
         end

         local out: Output = { x = 1 }
         local out2: Output = { x = 2 }
         insert(out, out2)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got Output, expected string", errors[1].msg, 1, true)
   end)
   it("will catch if resolved typevar does not match", function()
      -- fail
      local tokens = tl.lex([[
         local ParseItem = functiontype<V>(number): V

         local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
            local ret: {T} = {}
            local n = 0
            for i, t in ipairs(list) do
               n = i
               table.insert(list, parse_item(i))
            end
            return n, ret
         end

         local Node = record
            foo: number
         end

         local Other = record
            bar: string
         end

         local nodes: {Node} = {}

         local function parse_node(n: number): Node
            return { foo = n }
         end

         local x, result: number, Other = parse_list(nodes, parse_node)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("got {Node}, expected Other", errors[1].msg, 1, true)
   end)
   it("can map one typevar to another", function()
      -- pass
      local tokens = tl.lex([[
         local ParseItem = functiontype<V>(number): V

         local function parse_list<T>(list: {T}, parse_item: ParseItem<T>): number, {T}
            local ret: {T} = {}
            local n = 0
            for i, t in ipairs(list) do
               n = i
               table.insert(list, parse_item(i))
            end
            return n, ret
         end

         local Node = record
            foo: number
         end

         local nodes: {Node} = {}

         local function parse_node(n: number): Node
            return { foo = n }
         end

         local x, result: number, {Node} = parse_list(nodes, parse_node)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("checks that missing typevars are caught", util.check_type_error([[
      local Node = record
      end

      local VisitorCallbacks = record<X, Y>
      end

      local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
      end

      local function pretty_print_ast(ast: Node): string
         local visit_node: {string:VisitorCallbacks<Node, string>} = {}
         local visit_type: {string:VisitorCallbacks<Type, string>} = {}
         return recurse_node(ast, visit_node, visit_type)
      end
   ]], {
      { msg = "unknown type Type", x = 134 },
      { msg = "unknown type Type", x = 53 }
   }))
   it("propagates resolved typevar in return type", function()
      local tokens = tl.lex([[
         local Node = record
         end

         local Type = record
         end

         local VisitorCallbacks = record<N, X>
         end

         local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
         end

         local function pretty_print_ast(ast: Node): string
            local visit_node: {string:VisitorCallbacks<Node, string>} = {}
            local visit_type: {string:VisitorCallbacks<Type, string>} = {}
            return recurse_node(ast, visit_node, visit_type)
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
   it("checks that typevars that appear in multiple arguments must match", function()
      -- pass
      local tokens = tl.lex([[
         local Node = record
         end

         local Type = record
         end

         local VisitorCallbacks = record<X, Y>
         end

         local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>}): T
         end

         local function pretty_print_ast(ast: Node): string
            local visit_node: {string:VisitorCallbacks<Node, string>} = {}
            local visit_type: {string:VisitorCallbacks<Type, string>} = {}
            return recurse_node(ast, visit_node, visit_type)
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
      -- fail
      local tokens = tl.lex([[
         local Node = record
         end

         local Type = record
         end

         local VisitorCallbacks = record<X, Y>
         end

         local function recurse_node<T>(ast: Node, visit_node: {string:VisitorCallbacks<Node, T>}, visit_type: {string:VisitorCallbacks<Type, T>})
         end

         local function pretty_print_ast(ast: Node): string
            local visit_node: {string:VisitorCallbacks<Node, string>} = {}
            local visit_type: {string:VisitorCallbacks<Type, number>} = {}
            recurse_node(ast, visit_node, visit_type)
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("argument 3: type parameter <T>: got number, expected string", errors[1].msg, 1, true)
      assert.same(43, errors[1].x)
   end)
   it("inference trickles down to function arguments", function()
      -- pass
      local tokens = tl.lex([[
         local R = record
            arch: string
         end
         local data: {R} = {
            { arch = "foo" },
            { arch = "bar" },
         }
         table.sort(data, function(a:R,b:R):boolean return a.arch < b.arch end)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
      -- fail
      local tokens = tl.lex([[
         local R = record
            arch: string
         end
         local S = record
            different: string
         end
         local data: {R} = {
            { arch = "foo" },
            { arch = "bar" },
         }
         table.sort(data, function(a:R,b:S):boolean return a.arch < b.different end)
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.match("argument 2", errors[1].msg, 1, true)
      assert.same(11, errors[1].y, 1, true)
      assert.same(42, errors[1].x, 1, true)
   end)
   it("does not leak an unresolved generic type", function()
      local tokens = tl.lex([[
         function mypairs<a, b>(map: {a:b}): (a, b)
         end

         local _, resolved   = mypairs({["hello"] = true})
         local _, unresolved = mypairs({})
      ]])
      local _, ast = tl.parse_program(tokens, { lax = true })
      local errors = tl.type_check(ast)
      assert.same(0, #errors)
      -- resolved
      assert.same("string",  ast[2].exps[1].type[1].typename)
      assert.same("boolean", ast[2].exps[1].type[2].typename)
      -- unresolved
      assert.same("unknown", ast[3].exps[1].type[1].typename)
      assert.same("unknown", ast[3].exps[1].type[2].typename)
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

end)

