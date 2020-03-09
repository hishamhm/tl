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

end)
