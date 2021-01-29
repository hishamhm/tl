local util = require("spec.util")

describe("[]", function()
   describe("on records", function()
      it("ok if indexing by string", util.check [[
         local x = { foo = "f" }
         print(x["foo"])
      ]])

      it("fails even if record is homogenous", util.check_type_error([[
         local x = { foo = 12, bar = 24 }
         local y = "baz"
         local n: number = x[y]
      ]], {
         { msg = "cannot index object of type record (foo: number; bar: number) with a string, consider using an enum" },
      }))

      it("fail without declaration if record is not homogenous", util.check_type_error([[
         local s = string.upper("hello")
         local x = { foo = 12, bar = s }
         local y = "baz"
         local n: string = x[y]
      ]], {
         { msg = "cannot index object of type record (foo: number; bar: string) with a string, consider using an enum" },
      }))

      it("ok without declaration if key is enum and all keys map to the same type", util.check [[
         local type Keys = enum
            "foo"
            "bar"
         end
         local x = { foo = 12, bar = 24, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]])

      it("fail if key is enum and not all keys map to the same type", util.check_type_error([[
         local type Keys = enum
            "foo"
            "bar"
         end
         local x = { foo = 12, bar = true, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]], {
         { msg = "cannot index, not all enum values map to record fields of the same type" },
      }))

      it("fail if key is enum and not all keys are covered", util.check_type_error([[
         local type Keys = enum
            "foo"
            "bar"
            "oops"
         end
         local x = { foo = 12, bar = 12, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]], {
         { msg = "enum value 'oops' is not a field" },
      }))

      it("fail if indexing by invalid string", util.check_type_error([[
         local x = { foo = "f" }
         print(x["bar"])
      ]], {
         { msg = "invalid key 'bar' in record 'x'" },
      }))
   end)
   describe("on strings", function()
      it("works with relevant stdlib string functions", util.check [[
         local s: string
         s:byte(1)
         s:find("hello")
         s:format()
         s:gmatch("hello")
         s:gsub("hello", "world")
         s:len()
         s:lower()
         s:match()
         s:pack()
         s:packsize()
         s:rep(2)
         s:reverse()
         s:sub(2)
         s:unpack("b")
         s:upper()
      ]])
   end)
   describe("on enums", function()
      it("works with relevant stdlib string functions", util.check [[
         local type foo = enum
            "bar"
         end
         local s: foo
         s:byte(1)
         s:find("hello")
         s:format()
         s:gmatch("hello")
         s:gsub("hello", "world")
         s:len()
         s:lower()
         s:match()
         s:pack()
         s:packsize()
         s:rep(2)
         s:reverse()
         s:sub(2)
         s:unpack("b")
         s:upper()
      ]])
   end)
   describe("on tuples", function()
      it("results in the correct type for integer literals", util.check [[
         local t: {string, number} = {"hi", 1}
         local str: string = t[1]
         local num: number = t[2]
      ]])
      it("produces a union when indexed with a number variable", util.check [[
         local t: {string, number} = {"hi", 1}
         local x: number = 1
         local var: string | number = t[x]
      ]])
      it("errors when a union can't be produced from indexing", util.check_type_error([[
         local t: {{string}, {number}} = {{"hey"}, {1}}
         local x: number = 1
         local var = t[x]
      ]], {
         { msg = "cannot index this tuple with a variable because it would produce a union type that cannot be discriminated at runtime" },
      }))
   end)
end)
