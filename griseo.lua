local __WHO, __VERSION, __NAME = 'Moonverse#9320', 1, 'griseo'

-- LuaFormatter off
local util, cvar, usermessage, msgpack, color, arxgui
util        = require 'util'
color       = require 'color' 
cvar        = require 'convar' -- command line interface
arxgui      = require 'arxgui' -- graphical interface
msgpack     = require 'msgpack' -- serializer
usermessage = require 'usermessagestruct'
-- LuaFormatter on

local _, filename, filename_ext = util.get_script_name()
local fmt = string.format("%s - %s", __NAME, filename_ext)


local vote_start = function( msg )
    if msg:GetID() == VoteStart then
        -------------
    end
end

local vote_pass = function( msg )
    if msg:GetID() == VotePass then
        --
    end
end

local vote_failed = function( msg )
    if msg:GetID() == VoteFailed then
        --
    end
end

local call_vote_failed = function( msg )
    if msg:GetID() == CallVoteFailed then
        --
    end
end

local say_text_2 = function( msg )
    if msg:GetID() == SayText2 then
        --
    end
end

local player_change_class = function( event )
    if event:GetName() == 'player_changeclass' then
        --
    end
end

---

local config = {
    printChat = true,
    printConsole = true,
    sayTextMode = 0,
 }

local savefolder, filepath, datafile, databin
savefolder = engine.GetGameDir() .. [[\..\lua-config]]
filepath = savefolder .. '\\' .. _NAME .. '.msgpack'
if os.rename( savefolder, 'lua-config' ) ~= true then
    os.execute( string.format( 'start /b mkdir "%s" 1>nul: 2>&1', savefolder ) )
    print( 'If a command prompt window flashed, it\'s most likely you didn\'t have this directory:\n' .. savefolder )
    print( '[+] the directory has' .. (os.rename( savefolder, 'lua-config' ) and '' or ' not') .. ' been created' )
end
datafile = io.open( filepath, 'rb' )
if datafile then
    databin = datafile:read( '*a' )
    datafile:close()
end

datafile = io.open( filepath, 'w+b' )
datafile:write( msgpack.encode_one( config ) )
datafile:flush()
datafile:close()

--[[
cvar.add_cvar( script_no_ext, function( cvar )
    local len = #script_no_ext
    local r, g, b = 255 * 10 // len , 255 * 20 // len, 255 * 30 // len
    cvar:Set( '' )
    local valid_arg, arg = {}, cvar:Get()
    valid_arg[1] = arg[1] == "unload" or nil
    if next(valid_arg) == nil then
        printc(r, g, b, 255, string.format('%s available command:', script_tag))
    end
end )]]

-- region:
-- LuaFormatter off 
local lua_callbacks = { 
    { 'DispatchUserMessage', vote_start }, 
    { 'DispatchUserMessage', vote_pass }, 
    { 'DispatchUserMessage', vote_failed },
    { 'DispatchUserMessage', call_vote_failed }, 
    { 'DispatchUserMessage', say_text_2 },
    { 'FireGameEvent', player_change_class }
}
function lua_callbacks:Register()
    for i, o in ipairs( lua_callbacks ) do   callbacks.Register( o[1], GetScriptName() .. "_callback_" .. i, o[2] ) end
end
function lua_callbacks:Unregister() 
    for i, o in ipairs( lua_callbacks ) do callbacks.Unregister( o[1], GetScriptName() .. "_callback_" .. i, o[2] ) end 
end

callbacks.Register( 'Unload', function()
    lua_callbacks:Unregister()
    cvar.release()
    cvar.unload_module()
    -- CvarManager:Unregister()
end )
lua_callbacks:Register()
-- LuaFormatter on
-- endregion:
