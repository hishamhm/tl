local util = require("spec.util")

describe("metamethod __call", function()
   it("can be set on a record", util.check [[
      local type Rec = record
         x: number
         metamethod __call: function(Rec, ? string, ? number): string
      end

      local rec_mt: metatable<Rec> = {
         __call = function(self: Rec, s?: string, n?: number): string
            return tostring(self.x + n) .. s
         end
      }

      local r = setmetatable({} as Rec, rec_mt)

      r.x = 12
      print(r("!!!", 34))
   ]])

   it("can be used on a record prototype", util.check [[
      local record A
         value: number
         metamethod __call: function(A, ? number): A
      end
      local A_mt: metatable<A>
      A_mt = {
         __call = function(a: A, v?: number): A
            return setmetatable({value = v} as A, A_mt)
         end
      }

      local inst = A(2)
      print(inst.value)
   ]])

   it("can type check arguments and argument count skips self", util.check_type_error([[
      local type Rec = record
         x: number
         metamethod __call: function(Rec, ? string, ? number): string
      end

      local rec_mt: metatable<Rec> = {
         __call = function(self: Rec, s?: string, n?: number): string
            return tostring(self.x + n) .. s
         end
      }

      local r = setmetatable({} as Rec, rec_mt)

      r.x = 12
      print(r("!!!", r))
   ]], {
      { msg = "argument 2: got Rec, expected number" },
   }))

   it("cannot be typechecked if the metamethod is not defined in the record", util.check_type_error([[
      local type Rec = record
         x: number
      end

      local rec_mt: metatable<Rec> = {
         __call = function(self: Rec, s?: string): string
            return tostring(self.x) .. s
         end
      }

      -- this is not sufficient to tell the compiler that r supports __call,
      -- because setmetatable is a dynamic operation.
      local r = setmetatable({} as Rec, rec_mt)

      r.x = 12
      print(r("!!!"))
   ]], {
      { msg = "not a function" }
   }))

   it("can use the record prototype in setmetatable and types flow through correctly", util.check [[
      local record mymod
        metamethod __call: function(mymod, ? string): string
      end

      function mymod.myfunc(s?: string):string
         return "Hello, " .. s .. "!"
      end

      return setmetatable(mymod, {
        __call = function(_: mymod, s?: string): string
          return mymod.myfunc(s)
        end
      })
   ]])

   it("can use nested record prototypes in setmetatable and types flow through correctly", util.check [[
      local record Rec
         record Type
            x: number
            y: number
            metamethod __call: function(Rec.Type): number
         end
         metamethod __call: function(Rec, ? number, ? number): Rec.Type
      end

      local Rec_instance_mt = {
         __call = function(self: Rec.Type): number
            return self.x + self.y
         end
      }

      local Rec_class_mt = {
         __call = function(_: Rec, x?: number, y?: number): Rec.Type
            return setmetatable({ x = x, y = y } as Rec.Type, Rec_instance_mt)
         end
      }

      setmetatable(Rec, Rec_class_mt)

      local a = Rec(10, 20)
      local b = Rec(1, 2)
      print(a() + b())

      local function f(_t: Rec)
      end

      f(Rec)
   ]])

   -- this is failing because the definition and implementations are not being cross-checked
   -- this causes the test to output an error on line 15, because the call doesn't match the
   -- metamethod definition inside Rec.
   pending("record definition and implementations must match their types", util.check_type_error([[
      local type Rec = record
         x: number
         metamethod __call: function(Rec, number, number): string
      end

      local rec_mt: metatable<Rec> = {
         __call = function(self: Rec, s: string): string
            return tostring(self.x) .. s
         end
      }

      local r = setmetatable({} as Rec, rec_mt)

      r.x = 12
      print(r("!!!"))
   ]], {
      { y = 7, msg = "in assignment: argument 2: got string, expected number" }
   }))
end)
