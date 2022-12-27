-- local inspect = require "libraries.inspect"
-- local parser = require "libraries.dumbParser"

-- local printLuaTable = function(o)
--     print(inspect(o))
-- end

-- local tokens = parser.tokenize("function fun() end 1 + 2 + 3 + \"e\" ")
-- local ast    = parser.parse(tokens)

-- printLuaTable(tokens)
-- print(string.rep("-", 80))
-- printLuaTable(ast)

print(pcall(require, "lua-5.4.4"))
pcall(require, "cjson")
local lib  = package.loadlib('cjson.dll', 'luaopen_cjson')()


printLuaTable(lib)