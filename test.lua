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
callbacks.Unregister( 'FireGameEvent', 'event_observer' )
local event_observer = function( event )
    if (event:GetName() == "match_invites_updated") then
        printc( 0, 255, 0, 255, "match_invites_updated." )
        printc( 0, 255, 0, 255, gamecoordinator.GetNumMatchInvites() ) -- 1 if after search queue found map
        print( gamecoordinator.GetMatchAbandonStatus() ) -- 0 if invite recived, 1 if match offer accepted
        -- when abandon or when a match is found
    end

    if (event:GetName() == "player_abandoned_match") then
        printc( 255, 0, 0, 255, "hello" )
        printc( 255, 0, 0, 255, gamecoordinator.GetMatchAbandonStatus() )
    end
end
-- callbacks.Register( 'FireGameEvent', 'event_observer', event_observer )

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

