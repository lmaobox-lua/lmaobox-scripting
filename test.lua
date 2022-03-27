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
        printc(255, 0, 0, 255, "hello")
        printc( 255, 0, 0, 255, gamecoordinator.GetMatchAbandonStatus() )
    end
end
callbacks.Register( 'FireGameEvent', 'event_observer', event_observer )
