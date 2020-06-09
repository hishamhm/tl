local util = {}

local tl = require("tl")
local assert = require("luassert")

function util.mock_io(finally, files)
   assert(type(finally) == "function")
   assert(type(files) == "table")

   local io_open = io.open
   finally(function() io.open = io_open end)
   io.open = function (filename, mode)
      local basename = string.match(filename, "([^/]+)$")
      if files[basename] then
         -- Return a stub file handle
         return {
            read = function (_, format)
               if format == "*a" then
                  return files[basename]     -- Return fake bar.tl content
               else
                  error("Not implemented!")  -- Implement other modes if needed
               end
            end,
            close = function () end,
         }
      else
         return io_open(filename, mode)
      end
   end
end

local function unindent(code)
   assert(type(code) == "string")

   return code:gsub("[ \t]+", " "):gsub("\n[ \t]+", "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end

function util.assert_line_by_line(s1, s2)
   assert(type(s1) == "string")
   assert(type(s2) == "string")

   s1 = unindent(s1)
   s2 = unindent(s2)
   local l1 = {}
   for l in s1:gmatch("[^\n]*") do
      table.insert(l1, l)
   end
   local l2 = {}
   for l in s2:gmatch("[^\n]*") do
      table.insert(l2, l)
   end
   for i in ipairs(l1) do
      assert.same(l1[i], l2[i], "mismatch at line " .. i .. ":")
   end
end

function util.write_tmp_file(finally, name, content)
   assert(type(finally) == "function")
   assert(type(name) == "string")
   assert(type(content) == "string")

   local full_name = "/tmp/" .. name
   local fd = io.open(full_name, "w")
   fd:write(content)
   fd:close()
   finally(function()
      os.remove(full_name)
   end)
   return full_name
end

function util.read_file(name)
   assert(type(name) == "string")

   local fd = io.open(name, "r")
   local output = fd:read("*a")
   fd:close()
   return output
end

function util.assert_popen_close(want1, want2, want3, ret1, ret2, ret3)
   assert(want1 == nil or type(want1) == "boolean")
   assert(type(want2) == "string")
   assert(type(want3) == "number")

   if _VERSION == "Lua 5.3" then
      assert.same(want1, ret1)
      assert.same(want2, ret2)
      assert.same(want3, ret3)
   end
end

local function check(lax, code, unknowns)
   return function()
      local tokens = tl.lex(code)
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same({}, syntax_errors, "Code was not expected to have syntax errors")
      local errors, unks = tl.type_check(ast, { filename = "foo.tl", lax = lax })
      assert.same({}, errors)
      if unknowns then
         assert.same(#unknowns, #unks)
         for i, u in ipairs(unknowns) do
            if u.y then
               assert.same(u.y, unks[i].y)
            end
            if u.x then
               assert.same(u.x, unks[i].x)
            end
            if u.msg then
               assert.same(u.msg, unks[i].msg)
            end
         end
      end
   end
end

local function check_type_error(lax, code, type_errors)
   return function()
      local tokens = tl.lex(code)
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same({}, syntax_errors, "Code was not expected to have syntax errors")
      local errors = tl.type_check(ast, { filename = "foo.tl", lax = lax })
      assert.same(#type_errors, #errors, "Expected same number of errors:")
      for i, err in ipairs(type_errors) do
         if err.y then
            assert.same(err.y, errors[i].y,  "[" .. i .. "] Expected same y location:")
         end
         if err.x then
            assert.same(err.x, errors[i].x,  "[" .. i .. "] Expected same x location:")
         end
         if err.msg then
            assert.match(err.msg, errors[i].msg, 1, true,  "[" .. i .. "] Expected messages to match:")
         end
      end
   end
end

function util.check(code)
   assert(type(code) == "string")

   return check(false, code)
end

function util.lax_check(code, unknowns)
   assert(type(code) == "string")
   assert(type(unknowns) == "table")

   return check(true, code, unknowns)
end

function util.check_type_error(code, type_errors)
   assert(type(code) == "string")
   assert(type(type_errors) == "table")

   return check_type_error(false, code, type_errors)
end

function util.lax_check_type_error(code, type_errors)
   assert(type(code) == "string")
   assert(type(type_errors) == "table")

   return check_type_error(true, code, type_errors)
end

function util.check_syntax_error(code, syntax_errors)
   assert(type(code) == "string")
   assert(type(syntax_errors) == "table")

   return function()
      local tokens = tl.lex(code)
      local errors = {}
      tl.parse_program(tokens, errors)
      assert.same(#syntax_errors, #errors, "Expected same amount of syntax errors:")
      for i, err in ipairs(syntax_errors) do
         if err.y then
            assert.same(err.y, errors[i].y, "[" .. i .. "] Expected same y location:")
         end
         if err.x then
            assert.same(err.x, errors[i].x,  "[" .. i .. "] Expected same x location:")
         end
         if err.msg then
            assert.match(err.msg, errors[i].msg, 1, true,  "[" .. i .. "] Expected messages to match:")
         end
      end
   end
end

local function gen(lax, code, expected)
   return function()
      local tokens = tl.lex(code)
      local syntax_errors = {}
      local _, ast = tl.parse_program(tokens, syntax_errors)
      assert.same({}, syntax_errors, "Code was not expected to have syntax errors")
      local errors, unks = tl.type_check(ast, { filename = "foo.tl", lax = lax })
      assert.same({}, errors)

      local output_code = tl.pretty_print_ast(ast)

      local expected_tokens = tl.lex(expected)
      local _, expected_ast = tl.parse_program(expected_tokens, {})
      local expected_code = tl.pretty_print_ast(expected_ast)

      assert.same(expected_code, output_code)
   end
end

function util.gen(code, expected)
   assert(type(code) == "string")
   assert(type(expected) == "string")

   return gen(false, code, expected)
end

return util
