local util = require("spec.util")

describe("flow analysis with is", function()
   describe("on expressions", function()
      it("narrows type on expressions with and", util.check [[
         local x: number | string

         local s = x is string and x:lower()
      ]])

      it("narrows type on expressions with or", util.check [[
         local x: number | string

         local s = x is number and tostring(x + 1) or x:lower()
      ]])

      it("narrows type on expressions with not", util.check [[
         local x: number | string

         local s = not x is string and tostring(x + 1) or x:lower()
      ]])
   end)

   describe("on if", function()
      it("resolves both then and else branches", util.check [[
         local t: number | string
         if t is number then
            print(t + 1)
         else
            print(t:upper())
         end
      ]])

      it("resolves for tagged records", util.check [[
         local R = record
            tag foo: string
         end
         local R1 = record is R with foo = "aaa"
            a: number
         end
         local R2 = record is R with foo = "bbb"
            b: number
         end
         local r: R1 | R2
         if r is R1 then
            print(r.a)
         else
            print(r.b)
         end
      ]])

      it("catches errors for tagged records", util.check_type_error([[
         local R = record
            tag foo: string
         end
         local R1 = record is R with foo = "aaa"
            a: number
         end
         local R2 = record is R with foo = "bbb"
            b: number
         end
         local r: R1 | R2
         if r is R1 then
            print(r.b) -- inverted!
         else
            print(r.a) -- inverted!
         end
      ]], {
         { msg = "invalid key 'b' in record 'r' of type R1" },
         { msg = "invalid key 'a' in record 'r' of type R2" },
      }))

      it("resolves tagged records without a union", util.check [[
         local R = record
            tag foo: string
         end
         local R1 = record is R with foo = "aaa"
            a: number
         end
         local R2 = record is R with foo = "bbb"
            b: number
         end
         local r: R
         if r is R1 then
            print(r.a)
         else
            print(r.foo)
         end
      ]])

      it("catches errors tagged records without a union", util.check_type_error([[
         local R = record
            tag foo: string
         end
         local R1 = record is R with foo = "aaa"
            a: number
         end
         local R2 = record is R with foo = "bbb"
            b: number
         end
         local r: R
         if r is R1 then
            print(r.a)
         else
            print(r.b)
         end
      ]], {
         { msg = "invalid key 'b' in record 'r' of type R" },
      }))

      it("negates with not", util.check [[
         local t: number | string
         if not t is number then
            print(t:upper())
         else
            print(t + 1)
         end
      ]])

      it("resolves with elseif", util.check [[
         local v: number | string | {boolean}
         if v is number then
            v = v + 1
         elseif v is string then
            print(v:upper())
         end
      ]])

      it("resolves incrementally with elseif", util.check [[
         local v: number | string | {boolean}
         if v is number then
            v = v + 1
         elseif v is string then
            print(v:upper())
         else
            local b: {boolean} = v
         end
      ]])

      it("resolves partially", util.check [[
         local v: number | string | {boolean}
         if v is number then
            print(v + 1)
         else
            -- v is string | {boolean}
            v = "hello"
            v = {true, false}
         end
      ]])

      it("builds union types with is and or", util.check [[
         local v: number | string | {boolean}
         if (v is number) or (v is string) then
            v = 2
            v = "hello"
         else
            -- v is {boolean}
            v = {true, false}
         end
      ]])

      it("builds union types with is and or (parses priorities correctly)", util.check [[
         local v: number | string | {boolean}
         if v is number or v is string then
            v = 2
            v = "hello"
         else
            -- v is {boolean}
            v = {true, false}
         end
      ]])

      it("resolves incrementally with elseif and negation", util.check [[
         local v: number | string | {boolean}
         if v is number then
            print(v + 1)
         elseif not v is {boolean} then
            print(v:upper())
         else
            v = {true, false}
         end
      ]])

      it("rejects other side of the union in the tested branch", util.check_type_error([[
         local t: number | string
         if t is number then
            print(t:upper())
         else
            print(t + 1)
         end
      ]], {
         { y = 3, msg = 'cannot index something that is not a record: number (inferred at foo.tl:2:13: )' },
         { y = 5, msg = [[cannot use operator '+' for types string (inferred at foo.tl:4:10: ) and number]] },
      }))

      it("detects empty unions", util.check_type_error([[
         local t: number | string
         if t is number then
            t = t + 1
         elseif t is string then
            print(t:upper())
         else
            print(t)
         end
      ]], {
         { y = 6, msg = 'branch is always false' },
      }))
   end)

   describe("on while", function()
      pending("needs to resolve a fixpoint to accept some valid code", util.check [[
         local t: number | string
         t = 1
         if t is number then
            while t < 1000 do
               t = t + 1
               if t == 10 then
                  t = "hello"
               end
               if t is string then
                  t = 20
               end
            end
         end
      ]])

      it("needs to resolve a fixpoint to detect some errors", util.check_type_error([[
         local t: number | string
         t = 1
         if t is number then
            while t < 1000 do -- FIXME: this is accepted even though t is not always a number
               if t is number then
                  t = t + 1
               end
               if t == 10 then
                  t = "hello"
               end
            end
         end
         end
      ]], {
         { y = 4, msg = [[cannot use operator '<' for types number | string and number]] },
      }))

      it("resolves is on the test", util.check [[
         function process(ts: {number | string})
            local t: number | string
            t = ts[1]
            local i = 1
            while t is number do
               print(t + 1)
               i = i + 1
               t = ts[i]
            end
         end
      ]])
   end)

   describe("code gen", function()
      describe("limitations", function()
         it("cannot discriminate a union between untagged table types", util.check_type_error([[
            local t: {number} | {string}
            if t is {number} then
               print(t)
            end
         ]], {
            { y = 1, msg = [[cannot discriminate a union between untagged table types: {number} | {string}]] },
         }))

         it("cannot discriminate a union between records", util.check_type_error([[
            local R1 = record
               foo: string
            end
            local R2 = record
               foo: string
            end
            local t: R1 | R2
         ]], {
            { y = 7, msg = [[cannot discriminate a union between untagged table types: R1 | R2]] },
         }))

         it("can discriminate a union between tagged records", util.check [[
            local R = record
               tag foo: string
            end
            local R1 = record is R with foo = "aaa"
               a: number
            end
            local R2 = record is R with foo = "bbb"
               b: number
            end
            local t: R1 | R2
         ]])

         it("cannot discriminate a union with tagged records and untagged table types", util.check_type_error([[
            local R = record
               tag foo: string
            end
            local R1 = record is R with foo = "aaa"
               a: number
            end
            local R2 = record is R with foo = "bbb"
               b: number
            end
            local t: R1 | R2 | R
         ]], {
            { y = 10, msg = [[cannot discriminate a union between untagged table types: R1 | R2]] },
         }))

         it("cannot discriminate a union between multiple string/enum types", util.check_type_error([[
            local Enum = enum
               "hello"
               "world"
            end
            local t: string | Enum
         ]], {
            { y = 5, msg = [[cannot discriminate a union between multiple string/enum types: string | Enum]] },
         }))

         it("does not produce new unions", util.check_type_error([[
            local x: number | string

            local s = x is string and x .. "!" or x + 1
         ]], {
            { y = 3, msg = [[cannot use operator 'or' for types string and number]] },
         }))

      end)

      it("generates type checks for primitive types", util.gen([[
         function process(ts: {number | string | boolean})
            local t: number | string | boolean
            t = ts[1]
            if t is number then
               print(t + 1)
            elseif t is string or t is boolean then
               print(t)
            end
         end
      ]], [[
         function process(ts)
            local t
            t = ts[1]
            if type(t) == "number" do
               print(t + 1)
            elseif type(t) == "string" or type(t) == "boolean" then
               print(t)
            end
         end
      ]]))

      it("generates type checks for non-primitive types", util.gen([[
         function process(ts: {number | {string} | boolean})
            local t: number | {string} | boolean
            t = ts[1]
            if t is number then
               print(t + 1)
            elseif t is {string} or t is boolean then
               print(t)
            end
         end
      ]], [[
         function process(ts)
            local t
            t = ts[1]
            if type(t) == "number" do
               print(t + 1)
            elseif type(t) == "table" or type(t) == "boolean" then
               print(t)
            end
         end
      ]]))

      it("generates type checks for tagged records", util.gen([[
         local R = record
            tag foo: string
         end
         local R1 = record is R with foo = "aaa"
            a: number
         end
         local R2 = record is R with foo = "bbb"
            b: number
         end
         function process(r: R1 | R2)
            if r is R1 then
               print(r.a)
            elseif r is R2 then
               print(r.b)
            end
         end
      ]], [[
         local R = {}


         local R1 = {}


         local R2 = {}


         function process(r)
            if r.foo == "aaa" then
               print(r.a)
            elseif r.foo == "bbb" then
               print(r.b)
            end
         end
      ]]))
   end)

end)
