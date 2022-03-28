--[[
local party_chat_commands_workshop = {
    status = function()
        local leader = party.GetLeader()
        local members = party.GetMembers()
        local pending = party.GetPendingMembers()
        local groupID = party.GetGroupID()
        local queuedMatchGroup = party.GetQueuedMatchGroups()
        local IsInStandbyQueue = party.IsInStandbyQueue()
        local IsInGame
        local GameServer
        local Map
        local DateCurrentTime
        local DataCenterPingData
        -- GetMemberActivity( index:integer )
    end

 }

 local GetMatchType = function()
    gamerules.IsMatchTypeCasual()
    gamerules.IsMatchTypeCompetitive()
    gamerules.IsMvM()
    gamerules.GetRoundState()
end]] -- 
callbacks.Unregister( 'DispatchUserMessage', 'usermessage_observer' )

-- #region : vscode-ext inline color
local print_console_color = function( color, text )
    local r, g, b, a = table.unpack( color )
    return printc( r, g, b, a, text )
end
local rgba = function( ... )
    return { ... }
end
local _rgba = function( ... ) -- rgba to hex
    -- The integer form of RGBA is 0xRRGGBBAA
    -- Hex for red is 0xRR000000, Multiply red value by 0x1000000(16777216) to get 0xRR000000
    -- Hex for green is 0x00GG0000, Multiply green value by 0x10000(65536) to get 0x00GG0000
    -- Hex for blue is 0x0000BB00, Multiply blue value by 0x100(256) to get 0x0000BB00
    -- Hex for alpha is 0x00000AA, no need to multiply since
    local r, g, b, a = table.unpack( { ... } )
    a = (0x100 <= a) and 255 or a
    local rgba = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    return string.format( "0x%06x", rgba )
end
-- #endregion : vscode-ext inline color

-- rewrite this lua.
local usermessage_cmd = {}
usermessage_cmd[CallVoteFailed] = function( msg )
    pcall( print( msg ) )
end

usermessage_cmd[VoteStart] = function( msg )
    pcall( print( msg ) )
end

usermessage_cmd[VotePass] = function( msg )
    pcall( print( msg ) )
end

usermessage_cmd[VoteFailed] = function( msg )
    pcall( print( msg ) )
end

usermessage_cmd[VoteSetup] = function( msg )
    pcall( print( msg ) )
end

local usermessage_observer = function( proton )
    local id = proton:GetID()
    local s = type( usermessage_cmd[id] ) == "function" and usermessage_cmd[id]()
end

local OnStartup = (function()
    -- tf2 settings to make voting easier
end)()

callbacks.Register( 'DispatchUserMessage', 'usermessage_observer', usermessage_observer )

