local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    LNXlib - A utility library for Lmaobox
]]

-- Globals
require("Library/Global/Global")

--[[ Main ]]

---@class LNXlib
---@field public TF2 TF2
---@field public UI UI
---@field public Utils Utils
local LNXlib = {
    TF2 = require("Library/TF2/TF2"),
    UI = require("Library/UI/UI"),
    Utils = require("Library/Utils/Utils"),
}

---@return number
function LNXlib.GetVersion()
    return 0.946
end

--[[ Debugging ]]

-- Unloads the entire library. Useful for debugging
function UnloadLib()
    LNXlib.Utils.UnloadPackages("LNXlib")
end

-- Library loaded
printc(75, 210, 55, 255, string.format("LNXlib Loaded (v%.3f)", LNXlib.GetVersion()))
LNXlib.UI.Notify.Simple("LNXlib loaded", string.format("Version: %.3f", LNXlib.GetVersion()))

Internal.Cleanup()
return LNXlib

end)
__bundle_register("Library/Utils/Utils", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Utils
---@field public Conversion Conversion
---@field public FileSystem FileSystem
---@field public Web Web
---@field public Input Input
---@field public KeyHelper KeyHelper
---@field public Logger Logger
---@field public Timer Timer
---@field public Config Config
---@field public Commands Commands
local Utils = {
    Conversion = require("Library/Utils/Conversion"),
    FileSystem = require("Library/Utils/FileSystem"),
    Web = require("Library/Utils/Web"),
    Input = require("Library/Utils/Input"),
    KeyHelper = require("Library/Utils/KeyHelper"),
    Logger = require("Library/Utils/Logger"),
    Timer = require("Library/Utils/Timer"),
    Config = require("Library/Utils/Config"),
    Commands = require("Library/Utils/Commands")
}

-- Removes all special characters from a string
---@param str string
---@return string
function Utils.Sanitize(str)
    _ = str:gsub("%s", "")
    _ = str:gsub("%%", "%%%%")
    return str
end

-- Generates a rainbow color
---@param offset number
---@return integer, integer, integer
function Utils.Rainbow(offset)
    local r = math.floor(math.sin(offset + 0) * 127 + 128)
    local g = math.floor(math.sin(offset + 2) * 127 + 128)
    local b = math.floor(math.sin(offset + 4) * 127 + 128)
    return r, g, b
end

-- Unloads all packages that contain the given name
---@param libName string
---@return integer
function Utils.UnloadPackages(libName)
    local unloadCount = 0
    for name, _ in pairs(package.loaded) do
        if string.find(name, libName) then
            print(string.format("Unloading package '%s'...", name))
            package.loaded[name] = nil
            unloadCount = unloadCount + 1
        end
    end

    warn(string.format("All packages of '%s' have been unloaded!", libName))
    return unloadCount
end

return Utils

end)
__bundle_register("Library/Utils/Commands", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Custom Console Commands
]]

---@class Commands
---@field _Commands table<string, fun(args : Deque)>
local Commands = {
    _Commands = {}
}

-- Register a new command
---@param name string
---@param callback fun(args : Deque)
function Commands.Register(name, callback)
    if Commands._Commands[name] ~= nil then
        warn(string.format("Command '%s' already exists and will be overwritten!", name))
    end
    Commands._Commands[name] = callback
end

-- Unregister a command
---@param name string
function Commands.Unregister(name)
    Commands._Commands[name] = nil
end

---@param stringCmd StringCmd
local function OnStringCmd(stringCmd)
    local args = Deque.new(string.split(stringCmd:Get(), " "))
    local cmd = args:popFront()
    
    if Commands._Commands[cmd] then
        stringCmd:Set("")
        Commands._Commands[cmd](args)
    end
end

Internal.RegisterCallback("SendStringCmd", OnStringCmd, "Utils", "Commands")

return Commands
end)
__bundle_register("Library/Utils/Config", function(require, _LOADED, __bundle_register, __bundle_modules)
---@type FileSystem
local FileSystem = require("Library/Utils/FileSystem")

---@type Json
local Json = require("Library/Libs/dkjson")

---@class Config
---@field private _Name string
---@field private _Content table
---@field public AutoSave boolean
---@field public AutoLoad boolean
local Config = {
    _Name = "",
    _Content = {},
    AutoSave = true,
    AutoLoad = false
}
Config.__index = Config
setmetatable(Config, Config)

local ConfigExtension = ".cfg"
local ConfigFolder = FileSystem.GetWorkDir() .. "/Configs/"

-- Creates a new config
---@return Config
function Config.new(name)
    local self = setmetatable({}, Config)
    self._Name = name
    self._Content = {}
    self.AutoSave = true
    self.AutoLoad = false

    self:Load()

    return self
end

-- Returns the path of the config file
---@return string
function Config:GetPath()
    if not FileSystem.Exists(ConfigFolder) then
        filesystem.CreateDirectory(ConfigFolder)
    end

    return ConfigFolder .. self._Name .. ConfigExtension
end

-- Loads the config file
---@return boolean
function Config:Load()
    local configPath = self:GetPath()
    if not FileSystem.Exists(configPath) then return false end

    local content = FileSystem.Read(self:GetPath())
    self._Content = Json.decode(content, 1, nil)
    return self._Content ~= nil
end

-- Deletes the config file
---@return boolean
function Config:Delete()
    local configPath = self:GetPath()
    if not FileSystem.Exists(configPath) then return false end

    self._Content = {}
    return FileSystem.Delete(configPath)
end

-- Saves the config file
---@return boolean
function Config:Save()
    local content = Json.encode(self._Content, { indent = true })
    return FileSystem.Write(self:GetPath(), content)
end

-- Sets a value in the config file
---@param key string
---@param value any
function Config:SetValue(key, value)
    if self.AutoLoad then self:Load() end
    self._Content[key] = value
    if self.AutoSave then self:Save() end
end

-- Retrieves a value from the config file
---@generic T
---@param key string
---@param default T
---@return T
function Config:GetValue(key, default)
    if self.AutoLoad then self:Load() end
    local value = self._Content[key]
    if value == nil then return default end

    return value
end

return Config

end)
__bundle_register("Library/Libs/dkjson", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Module options:
local register_global_module_table = false
local global_module_name = 'json'

--[==[

David Kolf's JSON module for Lua 5.1 - 5.4

Version 2.6


For the documentation see the corresponding readme.txt or visit
<http://dkolf.de/src/dkjson-lua.fsl/>.

You can contact the author by sending an e-mail to 'david' at the
domain 'dkolf.de'.


Copyright (C) 2010-2021 David Heiko Kolf

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat

---@class Json
local json = { version = "dkjson 2.6" }

local jsonlpeg = {}

if register_global_module_table then
  _G[global_module_name] = json
end

local _ENV = nil -- blocking globals in Lua 5.2 and later

pcall (function()
  -- Enable access to blocked metatables.
  -- Don't worry, this module doesn't change anything in them.
  --local debmeta = require "debug".getmetatable
  --if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable ({}, {
  __tojson = function () return "null" end
})

local function isarray (tbl)
  local max, n, arraylen = 0, 0, 0
  for k,v in pairs (tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end
      if k > max then
        max = k
      end
      n = n + 1
    end
  end
  if max > 10 and max > arraylen and max > n * 2 then
    return false -- don't create an array with too many holes
  end
  return true, max
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

local function escapeutf8 (uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176-\191]", escapeutf8)
  end
  return "\"" .. value .. "\""
end
json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind (str, o, 1, true)
  if i then
    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
  else
    return str
  end
end

-- locale independent num2str and str2num functions
local decpoint, numfilter

local function updatedecpoint ()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  -- build a filter that can be used to remove group separators
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str (num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num (str)
  local num = tonumber(replace(str, ".", decpoint))
  if not num then
    updatedecpoint()
    num = tonumber(replace(str, ".", decpoint))
  end
  return num
end

local function addnewline2 (level, buffer, buflen)
  buffer[buflen+1] = "\n"
  buffer[buflen+2] = strrep ("  ", level)
  buflen = buflen + 2
  return buflen
end

function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type (key)
  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end
  if prev then
    buflen = buflen + 1
    buffer[buflen] = ","
  end
  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ":"
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen
  if type (res) == 'string' then
    buflen = buflen + 1
    buffer[buflen] = res
  end
  return buflen
end

local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason
  local handler = state.exception
  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen
    local ret, msg = handler (reason, value, state, defaultmessage)
    if not ret then return nil, msg or defaultmessage end
    return appendcustom(ret, buffer, state)
  end
end

function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson
  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    state.bufferlen = buflen
    local ret, msg = valtojson (value, state)
    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
    tables[value] = nil
    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray (value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v ~= nil then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            prev = true -- add a seperator before the next element
          end
        end
        for k,v in pairs (value) do
          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception ('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end

function json.encode (value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                   buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error (msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat (buffer)
  end
end

local function loc (str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind (str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end
  return "line " .. line .. ", column " .. (where - linepos)
end

local function unterminated (str, what, where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

local function scanwhite (str, pos)
  while true do
    pos = strfind (str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub (str, pos, pos + 1)
    if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind (str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind (str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated (str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end
    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar (value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end
      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat (buffer), lastpos
  else
    return "", lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local len = strlen (str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable (tbl, objectmeta)
  else
    setmetatable (tbl, arraymeta)
  end
  while true do
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    local char = strsub (str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    char = strsub (str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end
      pos = scanwhite (str, pos + 1)
      if not pos then return unterminated (str, what, startpos) end
      local val2
      val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite (str, pos)
      if not pos then return unterminated (str, what, startpos) end
      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite (str, pos)
  if not pos then
    return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub (str, pos, pos)
  if char == "{" then
    return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring (str, pos)
  else
    local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num (strsub (str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind (str, "^%a%w*", pos)
    if pstart then
      local name = strsub (str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc (str, pos)
  end
end

local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return {__jsontype = 'object'}, {__jsontype = 'array'}
  end
end

function json.decode (str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end

return json


end)
__bundle_register("Library/Utils/FileSystem", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Filesystem Utils
]]

---@class FileSystem
local FileSystem = {}
local WorkDir = engine.GetGameDir() .. "/../LNXlib/"

-- Reads a file and returns its contents
---@param path string
---@return any
function FileSystem.Read(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

-- Writes the given content to the given file path
---@param path string
---@param content any
---@return boolean
function FileSystem.Write(path, content)
    local file = io.open(path, "wb") -- w write mode and b binary mode
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Deletes the file at the given path
---@param path string
---@return boolean
function FileSystem.Delete(path)
    return os.remove(path)
end

-- Returns whether the given file/directory exists
---@param path string
---@return boolean
function FileSystem.Exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end

-- Returns the working directory
---@return string
function FileSystem.GetWorkDir()
    if not FileSystem.Exists(WorkDir) then
        filesystem.CreateDirectory(WorkDir)
    end

    return WorkDir
end

return FileSystem

end)
__bundle_register("Library/Utils/Timer", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Timer
---@field private _LastTime number
local Timer = {
    _LastTime = 0
}
Timer.__index = Timer
setmetatable(Timer, Timer)

-- Creates a new timer.
---@return Timer
function Timer.new()
    local self = setmetatable({}, Timer)
    self._LastTime = 0

    return self
end

---@param delta number
---@return boolean
---@private
function Timer:_Check(delta)
    return globals.CurTime() - self._LastTime >= delta
end

-- Checks if the timer has passed the interval.
---@param interval number
---@return boolean
function Timer:Run(interval)
    if (self:_Check(interval)) then
        self._LastTime = globals.CurTime()
        return true
    end

    return false
end

return Timer

end)
__bundle_register("Library/Utils/Logger", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Logging utility
]]

---@class Logger
---@field public Name string
---@field public Level integer
---@field public Debug fun(...)
---@field public Info fun(...)
---@field public Warn fun(...)
---@field public Error fun(...)
local Logger = {
    Name = "",
    Level = 1
}
Logger.__index = Logger
setmetatable(Logger, Logger)

-- Creates a new logger
---@param name string
---@return Logger
function Logger.new(name)
    local self = setmetatable({}, Logger)
    self.Name = name
    self.Level = 1

    return self
end

---@type table<string, { Color:table, Level:integer }>
local logModes = {
    ["Debug"] = { Color = { 165, 175, 190 }, Level = 0 },
    ["Info"] = { Color = { 15, 185, 180 }, Level = 1 },
    ["Warn"] = { Color = { 225, 175, 45 }, Level = 2 },
    ["Error"] = { Color = { 230, 65, 25 }, Level = 3 }
}

-- Initialize the log methods dynamically
for mode, data in pairs(logModes) do
    rawset(Logger, mode, function(self, ...)
        if data.Level < self.Level then return end

        local msg = string.format(...)

        local r, g, b = table.unpack(data.Color)
        local name = self.Name
        local time = os.date("%H:%M:%S")

        local logMsg = string.format("[%-6s%s] %s: %s", mode, time, name, msg)
        printc(r, g, b, 255, logMsg)
    end)
end

return Logger

end)
__bundle_register("Library/Utils/KeyHelper", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class KeyHelper
---@field public Key integer
---@field private _LastState boolean
local KeyHelper = {
    Key = 0,
    _LastState = false
}
KeyHelper.__index = KeyHelper
setmetatable(KeyHelper, KeyHelper)

-- Creates a new key helper
---@param key integer
---@return KeyHelper
function KeyHelper.new(key)
    local self = setmetatable({}, KeyHelper)
    self.Key = key
    self._LastState = false

    return self
end

-- Is the button currently down?
---@return boolean
function KeyHelper:Down()
    local isDown = input.IsButtonDown(self.Key)
    return isDown
end

-- Was the button just pressed? This will only be true once.
---@return boolean
function KeyHelper:Pressed()
    local shouldCheck = self._LastState == false
    self._LastState = self:Down()
    return self._LastState and shouldCheck
end

-- Was the button just released? This will only be true once.
---@return boolean
function KeyHelper:Released()
    local shouldCheck = self._LastState == true
    self._LastState = self:Down()
    return self._LastState == false and shouldCheck
end

return KeyHelper

end)
__bundle_register("Library/Utils/Input", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Input Utils
]]

---@class Input
local Input = {}

-- Contains pairs of keys and their names
---@type table<integer, string>
local KeyNames = {
    [KEY_SEMICOLON] = "SEMICOLON",
    [KEY_APOSTROPHE] = "APOSTROPHE",
    [KEY_BACKQUOTE] = "BACKQUOTE",
    [KEY_COMMA] = "COMMA",
    [KEY_PERIOD] = "PERIOD",
    [KEY_SLASH] = "SLASH",
    [KEY_BACKSLASH] = "BACKSLASH",
    [KEY_MINUS] = "MINUS",
    [KEY_EQUAL] = "EQUAL",
    [KEY_ENTER] = "ENTER",
    [KEY_SPACE] = "SPACE",
    [KEY_BACKSPACE] = "BACKSPACE",
    [KEY_TAB] = "TAB",
    [KEY_CAPSLOCK] = "CAPSLOCK",
    [KEY_NUMLOCK] = "NUMLOCK",
    [KEY_ESCAPE] = "ESCAPE",
    [KEY_SCROLLLOCK] = "SCROLLLOCK",
    [KEY_INSERT] = "INSERT",
    [KEY_DELETE] = "DELETE",
    [KEY_HOME] = "HOME",
    [KEY_END] = "END",
    [KEY_PAGEUP] = "PAGEUP",
    [KEY_PAGEDOWN] = "PAGEDOWN",
    [KEY_BREAK] = "BREAK",
    [KEY_LSHIFT] = "LSHIFT",
    [KEY_RSHIFT] = "RSHIFT",
    [KEY_LALT] = "LALT",
    [KEY_RALT] = "RALT",
    [KEY_LCONTROL] = "LCONTROL",
    [KEY_RCONTROL] = "RCONTROL",
    [KEY_UP] = "UP",
    [KEY_LEFT] = "LEFT",
    [KEY_DOWN] = "DOWN",
    [KEY_RIGHT] = "RIGHT",
}

-- Contains pairs of keys and their values
---@type table<integer, string>
local KeyValues = {
    [KEY_LBRACKET] = "[",
    [KEY_RBRACKET] = "]",
    [KEY_SEMICOLON] = ";",
    [KEY_APOSTROPHE] = "'",
    [KEY_BACKQUOTE] = "`",
    [KEY_COMMA] = ",",
    [KEY_PERIOD] = ".",
    [KEY_SLASH] = "/",
    [KEY_BACKSLASH] = "\\",
    [KEY_MINUS] = "-",
    [KEY_EQUAL] = "=",
    [KEY_SPACE] = " ",
}

-- Fill the tables
local function D(x) return x, x end
for i = 1, 10 do KeyNames[i], KeyValues[i] = D(tostring(i - 1)) end -- 0 - 9
for i = 11, 36 do KeyNames[i], KeyValues[i] = D(string.char(i + 54)) end -- A - Z
for i = 37, 46 do KeyNames[i], KeyValues[i] = "KP_" .. (i - 37), tostring(i - 37) end -- KP_0 - KP_9
for i = 92, 103 do KeyNames[i] = "F" .. (i - 91) end

-- Returns the name of a keycode
---@param key integer
---@return string|nil
function Input.GetKeyName(key)
    return KeyNames[key]
end

-- Returns the string value of a keycode
---@param key integer
---@return string|nil
function Input.KeyToChar(key)
    return KeyValues[key]
end

-- Returns the keycode of a string value
---@param char string
---@return integer|nil
function Input.CharToKey(char)
    return table.find(KeyValues, string.upper(char))
end

-- Returns the currently pressed key
---@return integer|nil
function Input.GetPressedKey()
    for i = KEY_FIRST, KEY_LAST do
        if input.IsButtonDown(i) then return i end
    end

    return nil
end

-- Returns all currently pressed keys as a table
---@return integer[]
function Input.GetPressedKeys()
    local keys = {}
    for i = KEY_FIRST, KEY_LAST do
        if input.IsButtonDown(i) then table.insert(keys, i) end
    end

    return keys
end

-- Returns if the cursor is in the given bounds
---@param x integer
---@param y integer
---@param x2 integer
---@param y2 integer
---@return boolean
function Input.MouseInBounds(x, y, x2, y2)
    local mx, my = table.unpack(input.GetMousePos())
    return mx >= x and mx <= x2 and my >= y and my <= y2
end

return Input

end)
__bundle_register("Library/Utils/Web", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Simple Web library using curl
]]

local function S(str)
    return "\"" .. str:gsub("\"", "'") .. "\""
end

---@class Web
local Web = {}

-- Downloads the given file/url
---@param url string
---@param path string
function Web.Download(url, path)
    os.execute("curl -o " .. S(path) .. " --url " .. S(url))
end

-- Reads the content of the given file/url
---@param url string
---@return string|nil
function Web.Get(url)
    local handle = io.popen("curl -s -L " .. S(url) .. "")
    if not handle then return nil end

    local content = handle:read("*a")
    handle:close()
    return content
end

-- Sends a POST request with custom data
---@param url string
---@param data string
---@return string|nil
function Web.Post(url, data)
    local handle = io.popen("curl -s -L -d " .. S(data) .. " " .. S(url))
    if not handle then return nil end

    local content = handle:read("*a")
    handle:close()
    return content
end

return Web

end)
__bundle_register("Library/Utils/Conversion", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Conversion Utils
]]

---@class Conversion
local Conversion = {}

-- Converts a given SteamID 3 to SteamID 64 [Credits: Link2006]
---@param steamID3 string|number
---@return string|boolean, string?
function Conversion.ID3_to_ID64(steamID3)
    if tonumber(steamID3) then
        -- XXX format
        return tostring(tonumber(steamID3) + 0x110000100000000)
    elseif steamID3:match("(%[U:1:%d+%])") then
        -- [U:1:XXX] format
        return tostring(tonumber(steamID3:match("%[U:1:(%d+)%]")) + 0x110000100000000)
    end

     return false, "Invalid SteamID"
end

-- Converts a given SteamID 64 to a SteamID 3 [Credits: Link2006]
---@return string|boolean, string?
function Conversion.ID64_to_ID3(steamID64)
    if not tonumber(steamID64) then
        return false, "Invalid SteamID"
    end

    local steamID = tonumber(steamID64)
    if (steamID - 0x110000100000000) < 0 then
        return false, "Not a SteamID64"
    end

    return ("[U:1:%d]"):format(steamID - 0x110000100000000)
end

-- Converts a given Hex Color to RGB
---@param pHex string
---@return number, number, number
function Conversion.Hex_to_RGB(pHex)
    local r = tonumber(string.sub(pHex, 1, 2), 16)
    local g = tonumber(string.sub(pHex, 3, 4), 16)
    local b = tonumber(string.sub(pHex, 5, 6), 16)
    return r, g, b
end

-- Converts a given RGB Color to Hex
---@param r integer
---@param g integer
---@param b integer
---@return string
function Conversion.RGB_to_Hex(r, g, b)
    return string.format("%02x%02x%02x", r, g, b)
end

-- Converts a given HSV Color to RGB
---@param h number
---@param s number
---@param v number
---@return number, number, number
function Conversion.HSV_to_RGB(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- Converts a given RGB Color to HSV
---@param r integer
---@param g integer
---@param b integer
---@return number, number, number
function Conversion.RGB_to_HSV(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end

    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

-- Converts time to game ticks
---@param time number
---@return integer
function Conversion.Time_to_Ticks(time)
    return math.floor(0.5 + time / globals.TickInterval())
end

-- Converts game ticks to time
---@param ticks integer
---@return number
function Conversion.Ticks_to_Time(ticks)
    return ticks * globals.TickInterval()
end

return Conversion

end)
__bundle_register("Library/UI/UI", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class UI
---@field public Fonts Fonts
---@field public Textures Textures
---@field public Notify Notify
local UI = {
    Fonts = require("Library/UI/Fonts"),
    Textures = require("Library/UI/Textures"),
    Notify = require("Library/UI/Notify")
}

return UI

end)
__bundle_register("Library/UI/Notify", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    UI Notifications

    A notification can have the following attributes:
    Title, Content, Duration
]]

---@type Fonts
local Fonts = require("Library/UI/Fonts")

-- Style constants
local Size = { W = 300, H = 50 }
local Offset = { X = 10, Y = 10 }
local Padding = { X = 10, Y = 10 }
local FadeTime = 0.3

---@class Notify
local Notify = {}

---@alias Notification { ID : integer, Duration : number?, StartTime : number, Title : string, Content : string }
---@type table<integer, Notification>
local notifications = {}
local currentID = 0

-- Advanced notification with custom data
---@param data Notification
---@return integer
function Notify.Push(data)
    assert(type(data) == "table", "Notify.Push: data must be a table")

    data.ID = currentID
    data.Duration = data.Duration or 3
    data.StartTime = globals.RealTime()

    notifications[data.ID] = data
    currentID = (currentID + 1) % 1000

    return data.ID
end

-- Simple notification with a title
---@param title string
---@param duration? number
---@return integer
function Notify.Alert(title, duration)
    return Notify.Push({
        Title = title,
        Duration = duration
    })
end

-- Simple notification with a title and a message
---@param title string
---@param msg string
---@param duration? number
---@return integer
function Notify.Simple(title, msg, duration)
    return Notify.Push({
        Title = title,
        Content = msg,
        Duration = duration
    })
end

-- Removes a notification by ID
---@param id number
function Notify.Pop(id)
    local notification = notifications[id]
    if notification then
        notification.Duration = 0
    end
end

local function OnDraw()
    local currentY = Offset.Y

    for id, note in pairs(notifications) do
        local deltaTime = globals.RealTime() - note.StartTime

        if deltaTime > note.Duration then
            notifications[id] = nil
        else
            -- Fade transition
            local fadeStep = 1.0
            if deltaTime < FadeTime then
                fadeStep = deltaTime / FadeTime
            elseif deltaTime > note.Duration - FadeTime then
                fadeStep = (note.Duration - deltaTime) / FadeTime
            end

            local fadeAlpha = math.floor(fadeStep * 255)
            currentY = currentY - math.floor((1 - fadeStep) * Size.H)

            -- Background
            draw.Color(35, 50, 60, fadeAlpha)
            draw.FilledRect(Offset.X, currentY, Offset.X + Size.W, currentY + Size.H)

            -- Duration indicator
            local barWidth = math.floor(Size.W * (deltaTime / note.Duration))
            draw.Color(255, 255, 255, 150)
            draw.FilledRect(Offset.X, currentY, Offset.X + barWidth, currentY + 5)

            draw.Color(245, 245, 245, fadeAlpha)

            -- Title Text
            draw.SetFont(Fonts.SegoeTitle)
            if note.Title then
                draw.Text(Offset.X + Padding.X, currentY + Padding.Y, note.Title)
            end

            -- Content Text
            draw.SetFont(Fonts.Segoe)
            if note.Content then
                draw.Text(Offset.X + Padding.X, currentY + Padding.Y + 20, note.Content)
            end

            currentY = currentY + Size.H + Offset.Y
        end
    end
end

Internal.RegisterCallback("Draw", OnDraw, "UI", "Notify")

return Notify

end)
__bundle_register("Library/UI/Fonts", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Fonts
---@field public Verdana Font
---@field public Segoe Font
---@field public SegoeTitle Font
local Fonts = table.readOnly {
    Verdana = draw.CreateFont("Verdana", 14, 510),
    Segoe = draw.CreateFont("Segoe UI", 14, 510),
    SegoeTitle = draw.CreateFont("Segoe UI", 24, 700),
}

return Fonts

end)
__bundle_register("Library/UI/Textures", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Textures
local Textures = {}

---@alias TColor table<integer, integer, integer, integer?>
---@alias TSize table<integer, integer>

local byteMap = {}
for i = 0, 255 do byteMap[i] = string.char(i) end

---@type table<string, Texture>
local textureCache = {}

---@param color TColor
---@return integer, integer, integer, integer
local function UnpackColor(color)
    local r, g, b, a = table.unpack(color)
    a = a or 255
    return r, g, b, a
end

---@param size TSize
---@return integer, integer
local function UnpackSize(size)
    local w, h = table.unpack(size)
    w, h = w or 256, h or 256
    return w, h
end

---@param name string
---@vararg any
---@return string
local function GetTextureID(name, ...)
    return table.concat({name, ...})
end

-- Creates and caches the texture from RGBA data
---@param id string
---@param width integer
---@param height integer
---@param data table
local function CreateTexture(id, width, height, data)
    local binaryData = table.concat(data)
    local texture = draw.CreateTextureRGBA(binaryData, width, height)
    textureCache[id] = texture
    return texture
end

-- [PERFORMANCE INTENSIVE] Creates a linear gradient
---@param startColor TColor
---@param endColor TColor
---@param size TSize
---@return Texture
function Textures.LinearGradient(startColor, endColor, size)
    local sR, sG, sB, sA = UnpackColor(startColor)
    local eR, eG, eB, eA = UnpackColor(endColor)
    local w, h = UnpackSize(size)

    -- Check if the texture is already cached
    local id = GetTextureID("LG", sR, sG, sB, sA, eR, eG, eB, eA, w, h)
    local cache = textureCache[id]
    if cache then return cache end

    local dataSize = w * h * 4
    local data, bm = {}, byteMap
    
    local i = 1
    while i < dataSize do
        local idx = (i / 4)
        local x, y = idx % w, idx // w

        data[i] = bm[sR + (eR - sR) * x // w]
        data[i + 1] = bm[sG + (eG - sG) * y // h]
        data[i + 2] = bm[sB + (eB - sB) * x // w]
        data[i + 3] = bm[sA + (eA - sA) * y // h]

        i = i + 4
    end

    return CreateTexture(id, w, h, data)
end

-- [PERFORMANCE INTENSIVE] Creates a circle with a given color
---@param radius number
---@param color table<number, number, number, number>
---@return Texture
function Textures.Circle(radius, color)
    local r, g, b, a = UnpackColor(color)

    -- Check if the texture is already cached
    local id = GetTextureID("C", r, g, b, a, radius)
    local cache = textureCache[id]
    if cache then return cache end

    local diameter = radius * 2
    local dataSize = diameter * diameter * 4
    local data, bm = {}, byteMap

    local i = 1
    while i < dataSize do
        local idx = (i / 4)
        local x, y = idx % diameter, idx // diameter
        local dx, dy = x - radius, y - radius
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist <= radius then
            data[i] = bm[r]
            data[i + 1] = bm[g]
            data[i + 2] = bm[b]
            data[i + 3] = bm[a]
        else
            data[i] = bm[0]
            data[i + 1] = bm[0]
            data[i + 2] = bm[0]
            data[i + 3] = bm[0]
        end

        i = i + 4
    end

    return CreateTexture(id, diameter, diameter, data)
end

return Textures

end)
__bundle_register("Library/TF2/TF2", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class TF2
---@field public Globals Globals
---@field public WPlayer WPlayer
---@field public WEntity WEntity
---@field public WWeapon WWeapon
---@field public WPlayerResource WPlayerResource
local TF2 = {
    Helpers = require("Library/TF2/Helpers"),
    Globals = require("Library/TF2/Globals"),

    WPlayer = require("Library/TF2/Wrappers/WPlayer"),
    WEntity = require("Library/TF2/Wrappers/WEntity"),
    WWeapon = require("Library/TF2/Wrappers/WWeapon"),
    WPlayerResource = require("Library/TF2/Wrappers/WPlayerResource")
}

function TF2.Exit()
    os.exit()
end

return TF2

end)
__bundle_register("Library/TF2/Wrappers/WPlayerResource", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Wrapper Class for Wepaon Entities
]]

---@type WEntity
local WEntity = require("Library/TF2/Wrappers/WEntity")

---@class WPlayerResource : WEntity
local WPlayerResource = {}
WPlayerResource.__index = WPlayerResource
setmetatable(WPlayerResource, WEntity)

--[[ Contructors ]]

-- Creates a WPlayerResource from a given native Entity
---@param entity Entity
---@return WPlayerResource
function WPlayerResource.FromEntity(entity)
    local self = setmetatable({}, WPlayerResource)
    self:SetEntity(entity)

    return self
end

-- Returns the current player resource entity
---@return WPlayerResource
function WPlayerResource.Get()
    return WPlayerResource.FromEntity(entities.GetPlayerResources())
end

--[[ Wrapper functions ]]

-- DT_PlayerResource

-- Returns the ping of the given player
---@param index number
---@return integer
function WPlayerResource:GetPing(index)
    return self:GetPropDataTableInt("m_iPing")[index + 1]
end

-- Returns the score of the given player
---@param index number
---@return integer
function WPlayerResource:GetScore(index)
    return self:GetPropDataTableInt("m_iScore")[index + 1]
end

-- Returns the deaths of the given player
---@param index number
---@return integer
function WPlayerResource:GetDeaths(index)
    return self:GetPropDataTableInt("m_iDeaths")[index + 1]
end

-- Returns if the given player is connected
---@param index number
---@return boolean
function WPlayerResource:GetConnected(index)
    return self:GetPropDataTableInt("m_bConnected")[index + 1] == 1
end

-- Returns the team number of the given player
---@param index number
---@return integer
function WPlayerResource:GetTeam(index)
    return self:GetPropDataTableInt("m_iTeam")[index + 1]
end

-- Returns if the given player is alive
---@param index number
---@return boolean
function WPlayerResource:GetAlive(index)
    return self:GetPropDataTableInt("m_bAlive")[index + 1] == 1
end

-- Returns the health of the given player
---@param index number
---@return integer
function WPlayerResource:GetHealth(index)
    return self:GetPropDataTableInt("m_iHealth")[index + 1]
end

-- Returns the account ID of the given player
---@param index number
---@return integer
function WPlayerResource:GetAccountID(index)
    return self:GetPropDataTableInt("m_iAccountID")[index + 1]
end

-- Returns if the given player is valid
---@param index number
---@return boolean
function WPlayerResource:GetValid(index)
    return self:GetPropDataTableInt("m_bValid")[index + 1] == 1
end

-- Returns the user ID of the given player
---@param index number
---@return integer
function WPlayerResource:GetUserID(index)
    return self:GetPropDataTableInt("m_iUserID")[index + 1]
end

-- DT_TFPlayerResource

-- Returns the total score of the given player
---@param index number
---@return integer
function WPlayerResource:GetTotalScore(index)
    return self:GetPropDataTableInt("m_iTotalScore")[index + 1]
end

-- Returns the max health of the given player
---@param index number
---@return integer
function WPlayerResource:GetMaxHealth(index)
    return self:GetPropDataTableInt("m_iMaxHealth")[index + 1]
end

-- Returns the max buffed health of the given player
---@param index number
---@return integer
function WPlayerResource:GetMaxBuffedHealth(index)
    return self:GetPropDataTableInt("m_iMaxBuffedHealth")[index + 1]
end

-- Returns the class number of the given player
---@param index number
---@return integer
function WPlayerResource:GetPlayerClass(index)
    return self:GetPropDataTableInt("m_iPlayerClass")[index + 1]
end

---@param index number
---@return boolean
function WPlayerResource:GetArenaSpectator(index)
    return self:GetPropDataTableInt("m_bArenaSpectator")[index + 1] == 1
end

-- Returns the amount of active dominations of the given player
---@param index number
---@return integer
function WPlayerResource:GetActiveDominations(index)
    return self:GetPropDataTableInt("m_iActiveDominations")[index + 1]
end

-- Returns when the given player will respawn
---@param index number
---@return number
function WPlayerResource:GetNextRespawnTime(index)
    return self:GetPropDataTableFloat("m_flNextRespawnTime")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetChargeLevel(index)
    return self:GetPropDataTableInt("m_iChargeLevel")[index + 1]
end

-- Returns the damage amount of the given player
---@param index number
---@return integer
function WPlayerResource:GetDamage(index)
    return self:GetPropDataTableInt("m_iDamage")[index + 1]
end

-- Returns the damage assist amount of the given player
---@param index number
---@return integer
function WPlayerResource:GetDamageAssist(index)
    return self:GetPropDataTableInt("m_iDamageAssist")[index + 1]
end

-- Returns the boss damage of the given player
---@param index number
---@return integer
function WPlayerResource:GetDamageBoss(index)
    return self:GetPropDataTableInt("m_iDamageBoss")[index + 1]
end

-- Returns the healing of the given player
---@param index number
---@return integer
function WPlayerResource:GetHealing(index)
    return self:GetPropDataTableInt("m_iHealing")[index + 1]
end

-- Returns the healing assist amount of the given player
---@param index number
---@return integer
function WPlayerResource:GetHealingAssist(index)
    return self:GetPropDataTableInt("m_iHealingAssist")[index + 1]
end

-- Returns the blocked damage of the given player
---@param index number
---@return integer
function WPlayerResource:GetDamageBlocked(index)
    return self:GetPropDataTableInt("m_iDamageBlocked")[index + 1]
end

-- Returns the amount of currency collected of the given player
---@param index number
---@return integer
function WPlayerResource:GetCurrencyCollected(index)
    return self:GetPropDataTableInt("m_iCurrencyCollected")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetBonusPoints(index)
    return self:GetPropDataTableInt("m_iBonusPoints")[index + 1]
end

-- Returns the level of the given player
---@param index number
---@return integer
function WPlayerResource:GetPlayerLevel(index)
    return self:GetPropDataTableInt("m_iPlayerLevel")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetStreaks(index)
    return self:GetPropDataTableInt("m_iStreaks")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetUpgradeRefundCredits(index)
    return self:GetPropDataTableInt("m_iUpgradeRefundCredits")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetBuybackCredits(index)
    return self:GetPropDataTableInt("m_iBuybackCredits")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetPartyLeaderRedTeamIndex(index)
    return self:GetPropDataTableInt("m_iPartyLeaderRedTeamIndex")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetPartyLeaderBlueTeamIndex(index)
    return self:GetPropDataTableInt("m_iPartyLeaderBlueTeamIndex")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetEventTeamStatus(index)
    return self:GetPropDataTableInt("m_iEventTeamStatus")[index + 1]
end

---@param index number
---@return integer
function WPlayerResource:GetPlayerClassWhenKilled(index)
    return self:GetPropDataTableInt("m_iPlayerClassWhenKilled")[index + 1]
end

-- Returns the connection state of the given player
---@param index number
---@return integer
function WPlayerResource:GetConnectionState(index)
    return self:GetPropDataTableInt("m_iConnectionState")[index + 1]
end

-- Returns the time the given player has been connected
---@param index number
---@return number
function WPlayerResource:GetConnectTime(index)
    return self:GetPropDataTableFloat("m_flConnectTime")[index + 1]
end

return WPlayerResource

end)
__bundle_register("Library/TF2/Wrappers/WEntity", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Wrapper Class for Entities
]]

---@type Helpers
local Helpers = require("Library/TF2/Helpers")

---@class WEntity : Entity
---@field private Entity Entity|nil
local WEntity = {
    Entity = nil
}
WEntity.__index = WEntity
setmetatable(WEntity, {
    __index = function(self, key, ...)
        return function(self, ...)
            local entity = rawget(self, "Entity")
            return entity[key](entity, ...)
        end
    end
})

--[[ Constructors ]]

-- Creates a WEntity from a given native Entity
---@param entity Entity
---@return WEntity
function WEntity.FromEntity(entity)
    local self = setmetatable({}, WEntity)
    self:SetEntity(entity)

    return self
end

-- Sets the base entity
---@param entity Entity
function WEntity:SetEntity(entity)
    self.Entity = entity
end

-- Returns the native entity
---@return Entity
function WEntity:Unwrap()
    return self.Entity
end

---@param b WEntity|Entity
function WEntity:Equals(b)
    return self:GetIndex() == b:GetIndex()
end

---@return number
function WEntity:GetSimulationTime()
    return self:GetPropFloat("m_flSimulationTime")
end

-- Returns whether the entity can be seen from the given entity
---@param fromEntity Entity
function WEntity:IsVisible(fromEntity)
    return Helpers.VisPos(self, fromEntity:GetAbsOrigin(), self:GetAbsOrigin())
end

return WEntity

end)
__bundle_register("Library/TF2/Helpers", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Helpers
]]

---@class Helpers
local Helpers = {}

-- Computes the move vector between two points
---@param userCmd UserCmd
---@param a Vector3
---@param b Vector3
---@return Vector3
local function ComputeMove(userCmd, a, b)
    local diff = (b - a)
    if diff:Length() == 0 then return Vector3(0, 0, 0) end

    local x = diff.x
    local y = diff.y
    local vSilent = Vector3(x, y, 0)

    local ang = vSilent:Angles()
    local cPitch, cYaw, cRoll = userCmd:GetViewAngles()
    local yaw = math.rad(ang.y - cYaw)
    local pitch = math.rad(ang.x - cPitch)
    local move = Vector3(math.cos(yaw) * 450, -math.sin(yaw) * 450, -math.cos(pitch) * 450)

    return move
end

-- Walks to the destination
---@param userCmd UserCmd
---@param localPlayer Entity
---@param destination Vector3
function Helpers.WalkTo(userCmd, localPlayer, destination)
    local localPos = localPlayer:GetAbsOrigin()
    local result = ComputeMove(userCmd, localPos, destination)

    userCmd:SetForwardMove(result.x)
    userCmd:SetSideMove(result.y)
end

-- Returns if the weapon can shoot
---@param weapon Entity
---@return boolean
function Helpers.CanShoot(weapon)
    local lPlayer = entities.GetLocalPlayer()
    if weapon:IsMeleeWeapon() then return false end

    local nextPrimaryAttack = weapon:GetPropFloat("LocalActiveWeaponData", "m_flNextPrimaryAttack")
    local nextAttack = lPlayer:GetPropFloat("bcc_localdata", "m_flNextAttack")
    if (not nextPrimaryAttack) or (not nextAttack) then return false end

    return (nextPrimaryAttack <= globals.CurTime()) and (nextAttack <= globals.CurTime())
end

-- Returns if the player is visible
---@param target Entity
---@param from Vector3
---@param to Vector3
---@return boolean
function Helpers.VisPos(target, from, to)
    local trace = engine.TraceLine(from, to, MASK_SHOT | CONTENTS_GRATE)
    return (trace.entity == target) or (trace.fraction > 0.99)
end

-- Returns the screen bounding box of the player (or nil if the player is not visible)
---@param player WPlayer
---@return {x:number, y:number, w:number, h:number}|nil
function Helpers.GetBBox(player)
    local padding = Vector3(0, 0, 10)
    local headPos = player:GetEyePos() + padding
    local feetPos = player:GetAbsOrigin() - padding

    local headScreenPos = client.WorldToScreen(headPos)
    local feetScreenPos = client.WorldToScreen(feetPos)
    if (not headScreenPos) or (not feetScreenPos) then return nil end

    local height = math.abs(headScreenPos[2] - feetScreenPos[2])
    local width = height * 0.6

    return {
        x = math.floor(headScreenPos[1] - width * 0.5),
        y = math.floor(headScreenPos[2]),
        w = math.floor(width),
        h = math.floor(height)
    }
end

return Helpers

end)
__bundle_register("Library/TF2/Wrappers/WWeapon", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Wrapper Class for Wepaon Entities
]]

---@type WEntity
local WEntity = require("Library/TF2/Wrappers/WEntity")

---@class WWeapon : WEntity
local WWeapon = {}
WWeapon.__index = WWeapon
setmetatable(WWeapon, WEntity)

--[[ Contructors ]]

-- Creates a WWeapon from a given native Entity
---@param entity Entity
---@return WWeapon
function WWeapon.FromEntity(entity)
    assert(entity:IsWeapon(), "WWeapon.FromEntity: entity is not a weapon")

    local self = setmetatable({}, WWeapon)
    self:SetEntity(entity)

    return self
end

--[[ Wrapper functions ]]

---@return Entity
function WWeapon:GetOwner()
    return self:GetPropEntity("m_hOwner")
end

---@return number
function WWeapon:GetDefIndex()
    return self:GetPropInt("m_iItemDefinitionIndex")
end

return WWeapon

end)
__bundle_register("Library/TF2/Wrappers/WPlayer", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Wrapper Class for Player Entities
]]

---@type WEntity
local WEntity = require("Library/TF2/Wrappers/WEntity")

---@type WWeapon
local WWeapon = require("Library/TF2/Wrappers/WWeapon")

---@class WPlayer : WEntity
local WPlayer = {}
WPlayer.__index = WPlayer
setmetatable(WPlayer, WEntity)

--[[ Constructors ]]

-- Creates a WPlayer from a given native Entity
---@param entity Entity
---@return WPlayer
function WPlayer.FromEntity(entity)
    assert(entity:IsPlayer(), "WPlayer.FromEntity: entity is not a player")

    local self = setmetatable({}, WPlayer)
    self:SetEntity(entity)

    return self
end

-- Returns a WPlayer of the local player
---@return WPlayer
function WPlayer.GetLocal()
    return WPlayer.FromEntity(entities.GetLocalPlayer())
end

--[[ Wrapper functions ]]

-- Returns whether the player is on the ground
---@return boolean
function WPlayer:IsOnGround()
    local pFlags = self:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == 1
end

-- Returns the active weapon
---@return WWeapon
function WPlayer:GetActiveWeapon()
    return WWeapon.FromEntity(self:GetPropEntity("m_hActiveWeapon"))
end

---@return number
function WPlayer:GetObserverMode()
    return self:GetPropInt("m_iObserverMode")
end

-- Returns the spectated target
---@return WPlayer
function WPlayer:GetObserverTarget()
    return WPlayer.FromEntity(self:GetPropEntity("m_hObserverTarget"))
end

-- Returns the position of the hitbox as a Vector3
---@param hitboxID number
---@return Vector3
function WPlayer:GetHitboxPos(hitboxID)
    local hitbox = self:GetHitboxes()[hitboxID]
    if not hitbox then return Vector3(0, 0, 0) end

    return (hitbox[1] + hitbox[2]) * 0.5
end

---@return Vector3
function WPlayer:GetViewOffset()
    return self:GetPropVector("localdata", "m_vecViewOffset[0]")
end

---@return Vector3
function WPlayer:GetEyePos()
    return self:GetAbsOrigin() + self:GetViewOffset()
end

---@return EulerAngles
function WPlayer:GetEyeAngles()
    local angles = self:GetPropVector("tfnonlocaldata", "m_angEyeAngles[0]")
    return EulerAngles(angles.x, angles.y, angles.z)
end

-- Returns the position the player is looking at
---@return Vector3
function WPlayer:GetViewPos()
    local eyePos = self:GetEyePos()
    local targetPos = eyePos + self:GetEyeAngles():Forward() * 8192
    local trace = engine.TraceLine(eyePos, targetPos, MASK_SHOT)

    return trace.endpos
end

return WPlayer

end)
__bundle_register("Library/TF2/Globals", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Global variables for TF2
]]

---@class Globals
---@field public LastCommandNumber integer
---@field public CommandNumber integer
local Globals = {
    LastCommandNumber = 0,
    CommandNumber = 0
}

-- Updates the global variables
---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    Globals.LastCommandNumber = Globals.CommandNumber
    Globals.CommandNumber = userCmd.command_number
end

Internal.RegisterCallback("CreateMove", OnCreateMove, "TF2", "Globals")

return Globals

end)
__bundle_register("Library/Global/Global", function(require, _LOADED, __bundle_register, __bundle_modules)
require("Library/Global/Extensions")
require("Library/Global/Internal")
require("Library/Global/Stack")
require("Library/Global/Deque")
require("Library/Global/DelayedCall")

end)
__bundle_register("Library/Global/DelayedCall", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Delayed Calls
]]

---@type { time : number, func : fun() }[]
local delayedCalls = {}

-- Calls the given function after the given delay
---@param delay number
---@param func fun()
function _G.DelayedCall(delay, func)
    table.insert(delayedCalls, {
        time = globals.RealTime() + delay,
        func = func
    })
end

-- Dispatches the delayed calls
---@private
local function OnDraw()
    local curTime = globals.RealTime()
    for i, call in ipairs(delayedCalls) do
        if curTime > call.time then
            table.remove(delayedCalls, i)
            call.func()
        end
    end
end

Internal.RegisterCallback("Draw", OnDraw, "DelayedCall")

end)
__bundle_register("Library/Global/Deque", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Double ended queue data structure
]]

-- Double ended queue
---@class Deque
---@field private _items table
---@field private _size integer
Deque = {
    _items = {},
    _size = 0
}
Deque.__index = Deque
setmetatable(Deque, Deque)

-- Creates a new deque.
---@param items? any[]
---@return Deque
function Deque.new(items)
    ---@type Deque
    local self = setmetatable({}, Deque)
    self._items = items or {}
    self._size = #self._items

    return self
end

---@param item any
function Deque:pushFront(item)
    table.insert(self._items, 1, item)
    self._size = self._size + 1
end

---@param item any
function Deque:pushBack(item)
    self._size = self._size + 1
    self._items[self._size] = item
end

---@return any
function Deque:popFront()
    self._size = self._size - 1
    return table.remove(self._items, 1)
end

---@return any
function Deque:popBack()
    self._size = self._size - 1
    return table.remove(self._items)
end

---@return any
function Deque:peekFront()
    return self._items[1]
end

---@return any
function Deque:peekBack()
    return self._items[self._size]
end

---@return boolean
function Deque:empty()
    return self._size == 0
end

function Deque:clear()
    self._items = {}
    self._size = 0
end

---@return integer
function Deque:size()
    return self._size
end

-- Returns the items table as read-only
---@return any[]
function Deque:items()
    return table.readOnly(self._items)
end

end)
__bundle_register("Library/Global/Stack", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Stack data structure
]]

---@class Stack
---@field private _items table
---@field private _size integer
Stack = {
    _items = {},
    _size = 0
}
Stack.__index = Stack
setmetatable(Stack, Stack)

-- Creates a new stack.
---@param items? any[]
---@return Stack
function Stack.new(items)
    ---@type Stack
    local self = setmetatable({}, Stack)
    self._items = items or {}
    self._size = #self._items

    return self
end

---@param item any
function Stack:push(item)
    self._size = self._size + 1
    self._items[self._size] = item
end

---@return any
function Stack:pop()
    self._size = self._size - 1
    return table.remove(self._items)
end

---@return any
function Stack:peek()
    return self._items[self._size]
end

---@return boolean
function Stack:empty()
    return self._size == 0
end

function Stack:clear()
    self._items = {}
    self._size = 0
end

---@return integer
function Stack:size()
    return self._size
end

-- Returns the items in the stack
---@return any[]
function Stack:items()
    return table.readOnly(self._items)
end

end)
__bundle_register("Library/Global/Internal", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Internal functions for the library.
]]

local oldInternal = rawget(_G, "Internal")

---@class Internal
_G.Internal = {}

-- (Re-)Registers a callback with a given namespace
---@param id Callback
---@param callback fun()
---@vararg string
function Internal.RegisterCallback(id, callback, ...)
    local name = table.concat({"LNXlib", ..., id}, ".")
    callbacks.Unregister(id, name)
    callbacks.Register(id, name, callback)
end

-- Removes all internal functions
function Internal.Cleanup()
    _G.Internal = oldInternal
end
end)
__bundle_register("Library/Global/Extensions", function(require, _LOADED, __bundle_register, __bundle_modules)
--[[
    Extensions for Lua
]]

--[[ Math ]]

-- Clamp a number between a low and high value
---@param n number
---@param low number
---@param high number
---@return number
function math.clamp(n, low, high)
    return math.min(math.max(n, low), high)
end

-- Rounds a number to the nearest integer
---@param n number
---@return integer
function math.round(n)
    return math.floor(n + 0.5)
end

-- Performs linear interpolation between two numbers.
---@param a number
---@param b number
---@param t number
---@return number
function math.lerp(a, b, t)
    return a + (b - a) * t
end

--[[ Table ]]

-- Returns a read-only version of the given table
---@generic T : table
---@param t T
---@return T
function table.readOnly(t)
    local proxy = {}
    setmetatable(proxy, {
        __index = t,
        __newindex = function(u, k, v)
            error("Attempt to modify read-only table", 2)
        end
    })

    return proxy
end

-- Performans a linear search on a table and returns the key of the given value
---@generic K, V
---@param t table<K, V>
---@param value V
---@return K|nil
function table.find(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end

    return nil
end

-- Checks if the given table contains the given value
---@param t table
---@param value any
---@return boolean
function table.contains(t, value)
    return table.find(t, value) ~= nil
end

--[[ String ]]

-- Splits a string into a table of substrings based on a specified delimiter
---@param str string
---@param delimiter string
---@return string[]
function string.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end

    table.insert(result, string.sub(str, from))
    return result
end
end)
return __bundle_require("__root")