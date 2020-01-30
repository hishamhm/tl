local tl = require("tl")

describe("local function", function()
   describe("type", function()
      it("can have anonymous arguments", function()
         local tokens = tl.lex([[
            local f: function(number, string): boolean

            f = function(a: number, b: string): boolean
               return #b == a
            end
            local ok = f(3, "abc")
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
      end)

      it("can take names in arguments but names are ignored", function()
         local tokens = tl.lex([[
            local f: function(x: number, y: string): boolean

            f = function(a: number, b: string): boolean
               return #b == a
            end
            local ok = f(3, "abc")
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
      end)

      it("can take typed vararg in arguments", function()
         local tokens = tl.lex([[
            local f: function(x: number, ...: string): boolean

            f = function(a: number, ...: string): boolean
               return #select(1, ...) == a
            end
            local ok = f(3, "abc")
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
      end)

      it("cannot take untyped vararg", function()
         local tokens = tl.lex([[
            local f: function(number, ...): boolean

            f = function(a: number, ...: string): boolean
               return #select(1, ...) == a
            end
            local ok = f(3, "abc")
         ]])
         local syntax_errors = {}
         local _ = tl.parse_program(tokens, syntax_errors)
         assert.same("cannot have untyped '...' when declaring the type of an argument", syntax_errors[1].msg)
      end)
   end)

   it("declaration", function()
      local tokens = tl.lex([[
         local function f(a: number, b: string): boolean
            return #b == a
         end
         local ok = f(3, "abc")
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("declaration with nil as return", function()
      local tokens = tl.lex([[
         local function f(a: number, b: string): nil
            return
         end
         local ok = f(3, "abc")
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("declaration with no return", function()
      local tokens = tl.lex([[
         local function f(a: number, b: string): ()
            return
         end
         f(3, "abc")
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("declaration with no return cannot be used in assignment", function()
      local tokens = tl.lex([[
         local function f(a: number, b: string): ()
            return
         end
         local x = f(3, "abc")
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(1, #errors)
      assert.same("assignment in declaration did not produce an initial value for variable 'x'", errors[1].msg)
   end)

   it("declaration with return nil can be used in assignment", function()
      local tokens = tl.lex([[
         local function f(a: number, b: string): nil
            return
         end
         local x = f(3, "abc")
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same(0, #errors)
   end)

   describe("with function arguments", function()
      it("has ambiguity without parentheses in function type return", function()
         local tokens = tl.lex([[
            local function map(f: function(`a):`b, xs: {`a}): {`b}
               local r = {}
               for i, x in ipairs(xs) do
                  r[i] = f(x)
               end
               return r
            end
            local function quoted(s: string): string
               return "'" .. s .. "'"
            end

            print(table.concat(map(quoted, {"red", "green", "blue"}), ", "))
         ]])
         local syntax_errors = {}
         tl.parse_program(tokens, syntax_errors)
         assert.same(1, syntax_errors[1].y)
         assert.same(54, syntax_errors[1].x)
      end)

      it("has no ambiguity with parentheses in function type return", function()
         local tokens = tl.lex([[
            local function map(f: function(`a):(`b), xs: {`a}): {`b}
               local r = {}
               for i, x in ipairs(xs) do
                  r[i] = f(x)
               end
               return r
            end
            local function quoted(s: string): string
               return "'" .. s .. "'"
            end

            print(table.concat(map(quoted, {"red", "green", "blue"}), ", "))
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
      end)
   end)
end)
