local tl = require("tl")

describe("assignment to maps", function()
   it("resolves a record to a map", function()
      local tokens = tl.lex([[
         local m: {string:number} = {
            hello = 123,
            world = 234,
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)
end)
