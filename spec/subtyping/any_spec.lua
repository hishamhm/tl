local util = require("spec.util")

describe("subtyping of any:", function()

   it("nil <: any", util.check [[
      local a: any
      a = nil
   ]])

   it("any <: any", util.check [[
      local a: any
      local b: any
      a = b
   ]])

   it("unknown <: any", util.lax_check([[
      local a: any
      local function f(unk)
         a = unk
      end
   ]], {
      "unk"
   }))

   it("string <: any", util.check [[
      local a: any
      a = "string"
   ]])

   it("number <: any", util.check [[
      local a: any
      a = 1
   ]])

   it("boolean <: any", util.check [[
      local a: any
      a = false
   ]])

   it("thread <: any", util.check [[
      local a: any
      a = coroutine.create(function() end)
   ]])

   it("poly <: any", util.check [[
      local record R
         poly: function(s: string)
         poly: function(n: number)
      end

      local r: R = {}
      local a: any
      a = r.poly
   ]])

   it("union <: any", util.check [[
      local u: string | number
      local a: any
      a = u
   ]])

   it("nominal <: any", util.check [[
      local record R
      end

      local n: R
      local a: any
      a = n
   ]])

   it("enum <: any", util.check [[
      local enum E
         "a"
         "b"
      end

      local e: E
      local a: any
      a = e
   ]])

   it("emptytable <: any", util.check [[
      local et = {}
      local a: any
      a = et
   ]])

   it("array <: any", util.check [[
      local ar: {string}
      local a: any
      a = ar
   ]])

   it("arrayrecord <: any", util.check [[
      local record AR
         {number}
         x: string
      end
      local ar: AR
      local a: any
      a = ar
   ]])

   it("map <: any", util.check [[
      local m: {string:number}
      local a: any
      a = m
   ]])

   it("record <: any", util.check [[
      local m = {}
      function m.method()
      end

      local a: any
      a = m
   ]])

   it("function <: any", util.check [[
      local f = function()
      end

      local a: any
      a = f
   ]])
end)
