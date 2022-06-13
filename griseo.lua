-------------------------------------------------^------------------------------------------------- 
local author<const>, version<const> = 'Moonverse#9320', 1
-------------------------------------------------^------------------------------------------------- 
local cvar, usermessage_proto, msgpack = require 'cvar', require 'usermessage_proto', require 'msgpack'
local ChatPrintf = client.ChatPrintf

local GetScriptFileName = function()
    local s = GetScriptName()
    local _, p = s:find( '.*[/\\]' )
    local _, q = s:find( '.*[.]' )
    return s:sub( p + 1, q - 1 ), s:sub( p + 1, #s )
end

local localize_string = function( v )
    v = type( v ) == 'string' and v or tostring( v )
    v = client.Localize( v )
    return utf8.char( string.byte( v, 1, #v ) )
end

local to_plain_string = function( v ) return v:sub( '%c', '' ):sub( '%%', '%%%%' ) end

local text_range = function( v, substr, prefix, suffix )
    prefix = prefix or ''
    suffix = suffix or ''
    return tostring( v ):gsub( substr, prefix .. '%1' ):gsub( substr, '%1' .. suffix )
end

local filename, filename_ext = GetScriptFileName()

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

cvar.unregister( 'fuck' )

cvar.register( 'hi u', function(cvar) 
    cvar:Set("") 
    end
 )

cvar.register( 'fuck', function() end )
cvar.register( 'fuck', function() end )


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
