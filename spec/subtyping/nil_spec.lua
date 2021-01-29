local util = require("spec.util")

describe("subtyping of nil:", function()

   it("nil <: nil", util.check [[
      local n: nil
      n = nil
   ]])

   it("nil <: any", util.check [[
      local a: any
      a = nil
   ]])

   it("nil <: unknown", util.lax_check([[
      local function f(unk)
         unk = nil
      end
   ]], {
      "unk"
   }))

   it("nil <: string", util.check [[
      local s: string
      s = nil
   ]])

   it("nil <: number", util.check [[
      local n: number
      n = nil
   ]])

   it("nil <: boolean", util.check [[
      local b: boolean
      b = nil
   ]])

   it("nil <: thread", util.check [[
      local c = coroutine.create(function() end)
      c = nil
   ]])

   it("nil <: poly", util.check [[
      local record R
         poly: function(s: string)
         poly: function(n: number)
      end

      local r: R = {}
      r.poly = nil
   ]])

   it("nil <: union", util.check [[
      local u: string | number
      u = nil
   ]])

   it("nil <: nominal", util.check [[
      local record R
      end

      local n: R
      n = nil
   ]])

   it("nil <: enum", util.check [[
      local enum E
         "a"
         "b"
      end

      local e: E
      e = nil
   ]])

   it("nil <: emptytable", util.check [[
      local et = {}
      et = nil
   ]])

   it("nil <: array", util.check [[
      local a: {string}
      a = nil
   ]])

   it("nil <: arrayrecord", util.check [[
      local record AR
         {number}
         x: string
      end
      local ar: AR
      ar = nil
   ]])

   it("nil <: map", util.check [[
      local m: {string:number}
      m = nil
   ]])

   it("nil <: record", util.check [[
      local m = {}
      function m.method()
      end

      m = nil
   ]])

   it("nil <: function", util.check [[
      local f = function()
      end

      f = nil
   ]])
end)
