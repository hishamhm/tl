local tl = require("tl")
local util = require("spec.util")

describe("xpcall", function()
   pending("can't xpcall nothing", util.check_type_error([[
      local pok = xpcall()
   ]], {
      { msg = "given 0, expects at least 2" }
   }))

   pending("can't xpcall without a message handler", util.check_type_error([[
      local pok = xpcall(function() end)
   ]], {
      { msg = "given 1, expects at least 2" }
   }))

   it("checks the correct input arguments", util.check_type_error([[
      local function f(a: string, b: number)
      end

      local function msgh(err: string) print(err) end

      local pok = xpcall(f, msgh, 123, "hello")
   ]], {
      { msg = "argument 3: got integer, expected string" },
      { msg = "argument 4: got string \"hello\", expected number" },
   }))

   it("xpcalls through xpcall", function()
      -- ok
      util.mock_io(finally, {
         ["foo.tl"] = [[
            local function f(s: string): number
               return 123
            end

            local function msgh(err: string) print(err) end

            local a, b, d = xpcall(xpcall, msgh, f, msgh, "num")

            assert(a == true)
            assert(b == true)
            assert(d == 123)
         ]],
      })
      local result, err = tl.process("foo.tl")

      assert.same({}, result.syntax_errors)
      assert.same({}, result.type_errors)
   end)

   it("xpcalls through xpcall through xpcall", function()
      -- ok
      util.mock_io(finally, {
         ["foo.tl"] = [[
            local function f(s: string): number
               return 123
            end
            local function msgh(err: string) print(err) end
            local a, b, c, d = xpcall(xpcall, msgh, xpcall, msgh, f, msgh, "num")

            assert(a == true)
            assert(b == true)
            assert(c == true)
            assert(d == 123)
         ]],
      })
      local result, err = tl.process("foo.tl")

      assert.same({}, result.syntax_errors)
      assert.same({}, result.type_errors)
   end)

   it("xpcalls through other magical stdlib functions", function()
      -- ok
      util.mock_io(finally, {
         ["num.tl"] = [[
            return 123
         ]],
         ["foo.tl"] = [[
            local function msgh(err: string) print(err) end
            local a, b, c, d = xpcall(xpcall, msgh, xpcall, msgh, require, msgh, "num")

            assert(a == true)
            assert(b == true)
            assert(c == true)
            assert(d == 123)
         ]],
      })
      local result, err = tl.process("foo.tl")

      assert.same({}, result.syntax_errors)
      assert.same({}, result.type_errors)
   end)

   it("returns the correct output arguments", util.check_type_error([[
      local function f(a: string, b: number): {string}, boolean
         return {"hello", "world"}, true
      end

      local function msgh(err: string) print(err) end
      local pok, strs, yep = xpcall(f, msgh, "hello", 123)
      print(strs[1]:upper())
      local xyz: number = yep
   ]], {
      { msg = "xyz: got boolean, expected number" }
   }))

   it("type checks the message handler", util.check_type_error([[
      local function f(a: string, b: number)
      end

      local msgh = "not a function!"

      local pok = xpcall(f, msgh, 123, "hello")
   ]], {
      { msg = "argument 2: got string, expected function(<any type>)" },
      { msg = "argument 3: got integer, expected string" },
      { msg = "argument 4: got string \"hello\", expected number" },
   }))

end)
