local tl = require("tl")
local util = require("spec.util")

describe("assignment to nominal record", function()
   it("accepts empty table", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
         end
         local x: Node = {}
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("accepts complete table", function()
      local tokens = tl.lex([[
         local R = record
            foo: string
         end
         local AR = record
            {Node}
            bar: string
         end
         local Node = record
            b: boolean
            n: number
            m: {number: string}
            a: {boolean}
            r: R
            ar: AR
         end
         local x: Node = {
            b = true,
            n = 1,
            m = {},
            a = {},
            r = {},
            ar = {},
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("accepts incomplete table", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
            n: number
         end
         local x: Node = {
            b = true,
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("fails if table has extra fields", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
            n: number
         end
         local x: Node = {
            b = true,
            bla = 12,
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.is_not.same({}, errors)
      assert.match("in local declaration: x: unknown field bla", errors[1].msg, 1, true)
   end)

   it("fails if mismatch", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
         end
         local x: Node = 123
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.match("in local declaration: x: got number, expected Node", errors[1].msg, 1, true)
   end)
end)

describe("tagged records", function()
   it("child be assigned to parent", util.check [[
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
      local n: Node = e
   ]])

   it("parent cannot be assigned to child", util.check_type_error([[
      local Node = record
         tag kind: string
         x: number
         y: number
      end

      local EnumNode = record is Node with kind = "enum"
         enumset: {string}
      end

      local n: Node = {}
      n.x = 12
      n.y = 13
      local e: EnumNode
      e = n
   ]], {
      { msg = "in assignment: Node is not a EnumNode" }
   }))
end)
