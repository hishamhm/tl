local util = require("spec.util")

describe("record method call", function()
   it("method call on an expression", util.check [[
      local r = {
         x = 2,
         b = true,
      }
      function r:f(a: number, b: string): boolean
         if self.b then
            return #b == 3
         else
            return a > self.x
         end
      end
      (r):f(3, "abc")
   ]])

   it("method call with different call forms", util.check [[
      local foo = {bar = function(x: any, t?: any) end}
      print(foo:bar())
      print(foo:bar{})
      print(foo:bar"hello")
   ]])

   it("catches wrong use of : without a call", util.check_syntax_error([[
      local foo = {bar = function(x: any, t: any) end}
      print(foo:bar)
   ]], {
      { y = 2, msg = "expected a function call" },
   }))

   it("nested record method calls", util.check [[
      local r = {
         x = 2,
         b = true,
      }
      function r:f(b: string): string
         if self.b then
            return #b == 3 and "yes" or "no"
         end
         return "what"
      end
      function foo()
         r:f(r:f("hello"))
      end
   ]])

   describe("lax", function()
      it("nested record method calls", util.lax_check([[
         local SW = {}

         function SW:write(arg1,arg2,...)
         end

         function SW:writef(fmt,...)
            self:write(fmt:format(...))
         end
      ]], {
         { msg = "arg1" },
         { msg = "arg2" },
         { msg = "fmt" },
         { msg = "fmt.format" },
      }))
   end)

   it("catches wrong use of self. in call", util.check_type_error([[
      local record Foo
      end
      function Foo:method_a()
      end
      function Foo:method_c(arg: string)
      end
      function Foo:method_b()
         self.method_a()
         self.method_c("hello")
      end
   ]], {
      { y = 8, msg = "invoked method as a regular function: use ':' instead of '.'" },
      { y = 9, msg = "invoked method as a regular function: use ':' instead of '.'" },
   }))

end)
