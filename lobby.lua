-- MannUp
-- Competitive6v6
-- SpecialEvent
-- Casual
-- BootCamp
local queueable_match_group, members, join_pendings, leader, groupid = {}

local function autoqueue()

end

local function party_say( text )
end

local command = {

    -- queue all 
    -- queue autoqueue [mode]
    -- queue casual, competitive
    ['queue'] = {
        all = function()
            for name, matchgroup in pairs( queueable_match_group ) do
                party.QueueUp( matchgroup )
            end
        end,
        autoqueue = autoqueue
     },

    -- info leader
    -- info groupid
    -- info leave
    -- info join
    -- info pending
    ['info'] = {
        leader = function()
            party_say( 'current leader: ' .. steam.GetPlayerName( leader ) )
        end,
        groupid = function()
            party_say( 'current groupid: ' .. groupid )
        end,
        leave = function()
            party_say( 'last 5 entries (members left):' )
        end,
        join = function()
            party_say( 'last 5 entries (members joined):' )
        end,
        pending = function()
            party_say( 'last 5 entries (members in waiting room):' )
        end
     },

    --- whitelisting needed!
    -- user connect <community ip> <opt password>
    -- user disconnect
    -- user lua <filename>
    -- user leader <steamid>
    -- user kick <steamid> | offline | banned
    -- user leave
    -- user standby <join/leave/get>
    -- user priority index | userid | steamid <get, set, color> <opt val>
    ['user'] = function( args )

    end
 }

local function parse( text )
    local args = {}
    for w in text:gmatch( "%S+" ) do
        args[#args + 1] = w:lower()
    end
    command[table.remove( args, 1 )]( args )
end

local event = {
    ['party_chat'] = function( e )
        local steamid64, text, type
        steamid64 = e:GetInt( 'steamid' )
        text = e:GetString( 'text' )
        type = e:GetInt( 'type' )
        parse( text )
    end,
    ['party_updated'] = function()
        members = party.GetMembers()
        leader = party.GetLeader()
        groupid = party.GetGroupID()
        local gamemodes = party.GetAllMatchGroups()
        for name, MatchGroup in pairs( gamemodes ) do
            local reasons = party.CanQueueForMatchGroup( MatchGroup )
            -- reasons[2]: player is already queueing for ... (maybe we should replace with GetQueuedMatchGroups() instead)
            if reasons == true then
                queueable_match_group[name] = MatchGroup
            else
                printLuaTable(reasons)
            end
        end
    end
 }
callbacks.Register( 'FireGameEvent', function( e )
    local f = event[e:GetName()]
    if f then
        f( e )
    end
end )
callbacks.Register( 'SendStringCmd', function( cmd )
    --parse( cmd:Get() )
    --UnloadScript( GetScriptName() )
    --LoadScript( GetScriptName() )
end )

event.party_updated()

local gamemodes = party.GetAllMatchGroups()
for name, MatchGroup in pairs( gamemodes ) do
    local reasons = party.CanQueueForMatchGroup( MatchGroup )
    -- reasons[2]: player is already queueing for ... (maybe we should replace with GetQueuedMatchGroups() instead)
    if reasons == true then
        queueable_match_group[name] = MatchGroup
        party.QueueUp( MatchGroup )
    else
        --printLuaTable(reasons) 
    end
end

-- cannot join a lobby if another player is requesting to join ur lobby.

-- to enable party bypass, set 'share my lobby' or 'auto accept invites' to true

-- tf_party_debug <- useful cvar use it.