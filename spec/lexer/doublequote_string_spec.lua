local tl = require("tl")
local util = require("spec.util")


local function string_trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end


describe("doublequote string", function()
   it("accepts", util.check([[local foo = "bar"]]))

   it("parses escapes", util.check [[
      local msg = "foo"
      msg = msg:gsub("\n\t%(tail call%): %?", "\000")
      msg = msg:gsub("\n\t%.%.%.\n", "\001\n")
      msg = msg:gsub("\n\t%.%.%.$", "\001")
      -- FIXME ARITY the callback for gsub is declared as vararg, so the string arguments need to be optional...
      msg = msg:gsub("(%z+)\001(%z+)", function(some?: string, other?: string): string
         return "\n\t(..."..#some+#other.." tail call(s)...)"
      end)
   ]])

   it("export Lua", function()
      local result = tl.process_string([[local foo = "bar"]])
      local lua = tl.pretty_print_ast(result.ast)
      assert.equal([[local foo = "bar"]], string_trim(lua))
   end)
end)
