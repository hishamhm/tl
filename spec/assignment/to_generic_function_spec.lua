local util = require("spec.util")

describe("assignment to generic function", function()
   it("does not freeze when resolving type variables (#442)", util.check [[
      local t: ( function<T>({T}, number, number): T )

      local function f<A>(xs: {A}, _i: number, _j: number): A
         return xs[1]
      end

      t = f or t
   ]])
end)
