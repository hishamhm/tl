local tl = require("tl")
local util = require("spec.util")

describe("records", function()
   it("can have self-references", util.check [[
      local SLAXML = record
          parse: function(self: SLAXML, xml: string, anotherself: SLAXML)
       end

      local myxml = io.open('my.xml'):read('*all')
      SLAXML:parse(myxml, SLAXML)
   ]])

   it("can have circular type dependencies", util.check [[
      local R = record
         foo: S
      end

      local S = record
         foo: R
      end

      function id(r: R): R
         return r
      end
   ]])

   it("can have circular type dependencies on nested types", util.check [[
      local R = record
         R2 = record
            foo: S.S2
         end

         foo: S
      end

      local S = record
         S2 = record
            foo: R.R2
         end

         foo: R
      end

      function id(r: R): R
         return r
      end
   ]])

   it("can detect errors in type dependencies on nested types", util.check_type_error([[
      local R = record
         R2 = record
            foo: S.S3
         end

         foo: S
      end

      local S = record
         S2 = record
            foo: R.R2
         end

         foo: R
      end

      function id(r: R): R
         return r
      end
   ]], {
      { y = 3, msg = "unknown type S.S3" }
   }))

   it("can overload functions", function()
      local tokens = tl.lex([[
         global love_graphics = record
            print: function(text: string, x: number, y: number, r: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky:number)
            print: function(coloredtext: {any}, x: number, y: number, r: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky:number)
         end

         global love = record
            graphics: love_graphics
         end

         function main()
            love.graphics.print("Hello world", 100, 100)
         end
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("cannot overload other things", function()
      local tokens = tl.lex([[
         global love_graphics = record
            print: number
            print: string
         end
      ]])
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same("attempt to redeclare field 'print' (only functions can be overloaded)", syntax_errors[1].msg)
   end)

   it("can report an error on unknown types in polymorphic definitions", util.check_type_error([[
      -- this reports an error
      local R = record
         u: function(): UnknownType
         u: function(): string
      end

      function f(r: R): R
         return r
      end
   ]], {
      { y = 3, msg = "unknown type UnknownType"},
   }))

   it("can report an error on unknown types in polymorphic definitions in any order", util.check_type_error([[
      -- this reports an error
      local R = record
         u: function(): string
         u: function(): UnknownType
      end

      function f(r: R): R
         return r
      end
   ]], {
      { y = 4, msg = "unknown type UnknownType"},
   }))

   it("can produce an intersection type for polymorphic functions", util.check [[
      local requests = record

         RequestOpts = record
            {string}
            url: string
         end

         Response = record
            status_code: number
         end

         get: function(string): Response
         get: function(string, RequestOpts): Response
         get: function(RequestOpts): Response
      end

      local r: requests = {}
      local resp = r.get("hello")
   ]])

   it("can check the arity of polymorphic functions", util.check_type_error([[
      local requests = record

         RequestOpts = record
            {string}
            url: string
         end

         Response = record
            status_code: number
         end

         get: function(string): Response
         get: function(string, RequestOpts): Response
         get: function(RequestOpts): Response
      end

      local r: requests = {}
      local resp = r.get("hello", 123, 123)
   ]], {
     { y = 18, msg = "wrong number of arguments (given 3, expects 1 or 2)" }
   }))

   it("can be nested", function()
      util.mock_io(finally, {
         ["req.d.tl"] = [[
            local requests = record

               RequestOpts = record
                  {string}
                  url: string
               end

               Response = record
                  status_code: number
               end

               get: function(string): Response
               get: function(string, RequestOpts): Response
               get: function(RequestOpts): Response
            end

            return requests
         ]],
         ["use.tl"] = [[
            local req = require("req")

            local r = req.get("http://example.com")
            print(r.status_code)
            print(r.status_coda)
         ]],
      })
      local result, err = tl.process("use.tl")
      assert.same("invalid key 'status_coda' in record 'r' of type Response", result.type_errors[1].msg)
   end)

   it("can export types as nested records", function()
      util.mock_io(finally, {
         ["req.d.tl"] = [[
            local requests = record

               RequestOpts = record
                  {string}
                  url: string
               end

               Response = record
                  status_code: number
               end

               get: function(string): Response
               get: function(string, RequestOpts): Response
               get: function(RequestOpts): Response
            end

            return requests
         ]],
         ["use.tl"] = [[
            local req = require("req")

            local function f(): req.Response
               return req.get("http://example.com")
            end

            print(f().status_code)
         ]],
      })
      local result, err = tl.process("use.tl")
      assert.same(0, #result.syntax_errors)
      assert.same({}, result.type_errors)
   end)

end)

describe("tagged records", function()
   it("can have tags", util.check [[
      local Node = record
         tag kind: string
      end
   ]])

   it("can have subtypes", util.check [[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Node with kind = "enum"
         enumset: {string}
      end
   ]])

   it("can have enums as tags", util.check [[
      local NodeKind = enum
         "t1"
         "t2"
      end

      local Node = record
         tag kind: NodeKind
      end

      local T1Node = record is Node with kind = "t1"
         t1data: {string}
      end

      local T2Node = record is Node with kind = "t2"
         t2data: {string}
      end
   ]])

   it("enums as tags must be valid", util.check_type_error([[
      local NodeKind = enum
         "t1"
         "t2"
      end

      local Node = record
         tag kind: NodeKind
      end

      local T1Node = record is Node with kind = "t1"
         t1data: {string}
      end

      local T2Node = record is Node with kind = "t3" -- invalid!
         t2data: {string}
      end
   ]], {
      { msg = "string \"t3\" is not a member of NodeKind" }
   }))

   it("subtypes must have tag declarations", util.check_syntax_error([[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Node
         enumset: {string}
      end
   ]], {
      { msg = "expected 'with'" },
   }))

   it("subtype tags can be strings, numbers or booleans", util.check [[
      local WithString = record
         tag kind: string
      end

      local SubString = record is WithString with kind = "enum"
         enumset: {string}
      end

      local WithNumber = record
         tag kind: number
      end

      local SubNumber = record is WithNumber with kind = 1
         enumset: {string}
      end

      local WithBoolean = record
         tag kind: boolean
      end

      local SubBoolean = record is WithBoolean with kind = true
         enumset: {string}
      end
   ]])

   it("subtypes cannot be other literals", util.check_syntax_error([[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Node with kind = {}
         enumset: {string}
      end

      local EnumNode = record is Node with kind = function() end
         enumset: {string}
      end
   ]], {
      { msg = "invalid literal for tag value" },
      { msg = "invalid literal for tag value" },
   }))

   it("detects an unknown parent type", util.check_type_error([[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Bla with kind = "enum"
         enumset: {string}
      end
   ]], {
      { msg = "unknown type Bla" },
   }))

   it("detects an invalid tag", util.check_type_error([[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Node with typename = "enum"
         enumset: {string}
      end
   ]], {
      { msg = "invalid tag 'typename', expected 'kind'" },
   }))

   it("detects an invalid tag value", util.check_type_error([[
      local Node = record
         tag kind: string
      end

      local EnumNode = record is Node with kind = 123
         enumset: {string}
      end
   ]], {
      { msg = "got number, expected string" },
   }))

end)

