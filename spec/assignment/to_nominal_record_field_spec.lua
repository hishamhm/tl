local tl = require("tl")
local util = require("spec.util")

describe("assignment to nominal record field", function()
   it("passes", function()
      local tokens = tl.lex([[
         local Node = record
            foo: boolean
         end
         local Type = record
            node: Node
         end
         local t: Type = {}
         t.node = {}
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("fails if mismatch", function()
      local tokens = tl.lex([[
         local Node = record
            foo: boolean
         end
         local Type = record
            node: Node
         end
         local t: Type = {}
         t.node = 123
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.match("in assignment: got number, expected Node", errors[1].msg, 1, true)
   end)
end)

describe("tagged records", function()
   it("inherit fields from parent", util.check [[
      local Node = record
         tag kind: string
         x: number
         y: number
      end

      local EnumNode = record is Node with kind = "enum"
         enumset: {string}
      end

      local e: EnumNode = {}
      e.x = 12
      e.y = 13
      e.enumset = { "hello" }
   ]])

   it("child fields do not exist in parent", util.check_type_error([[
      local Node = record
         tag kind: string
         x: number
         y: number
      end

      local EnumNode = record is Node with kind = "enum"
         enumset: {string}
      end

      local e: Node = {}
      e.x = 12
      e.y = 13
      e.enumset = { "hello" }
   ]], {
      { msg = "invalid key 'enumset' in record 'e' of type Node" }
   }))
end)
