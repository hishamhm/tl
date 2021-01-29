local util = require("spec.util")

describe("binary metamethod __add", function()
   it("can be set on a record", util.check [[
      local type Rec = record
         x: number
         metamethod __call: function(Rec, string, number): string
         metamethod __add: function(Rec, Rec): Rec
      end

      local rec_mt: metatable<Rec>
      rec_mt = {
         -- FIXME ARITY the callback for __call is declared as vararg, so the string arguments need to be optional...
         __call = function(self: Rec, s?: string, n?: number): string
            return tostring(self.x + n) .. s
         end,
         __add = function(a: Rec, b: Rec): Rec
            local res = setmetatable({} as Rec, rec_mt)
            res.x = a.x + b.x
            return res
         end
      }

      local r = setmetatable({ x = 10 } as Rec, rec_mt)
      local s = setmetatable({ x = 20 } as Rec, rec_mt)

      print((r + s).x)
      print(r("!!!", 34))
   ]])

   it("can be used on a record prototype", util.check [[
      local record A
         value: number
         metamethod __call: function(A, ? number): A
         metamethod __add: function(A, A): A
      end
      local A_mt: metatable<A>
      A_mt = {
         -- FIXME ARITY the callback for __call is declared as vararg, so the string arguments need to be optional...
         __call = function(a: A, v?: number): A
            return setmetatable({value = v} as A, A_mt)
         end,
         __add = function(a: A, b: A): A
            local res = setmetatable({} as A, A_mt)
            res.value = a.value + b.value
            return res
         end,
      }

      A.value = 10
      local c = A + A
      print(c.value)
   ]])

   it("can be used via the second argument", util.check [[
      local type Rec = record
         x: number
         metamethod __add: function(number, Rec): Rec
      end

      local rec_mt: metatable<Rec>
      rec_mt = {
         __add = function(a: number, b: Rec): Rec
            local res = setmetatable({} as Rec, rec_mt)
            res.x = a + b.x
            return res
         end
      }

      local s = setmetatable({ y = 20 } as Rec, rec_mt)

      print((10 + s).x)
   ]])
end)
