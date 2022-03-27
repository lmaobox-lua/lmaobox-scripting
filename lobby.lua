--[[ lobby.lua | Test Build | Moonverse#9320 is looking for comments and suggestions
https://github.com/LewdDeveloper/lmaobox-scripting ]] -- 
callbacks.Unregister( 'FireGameEvent', 'observe_party_chat' )

-- #region WIP timeout fn
callbacks.Unregister( 'Draw', 'settimeout_timer' )
local _queue = {}
local settimeout = function( milisecond, fn )
    -- if (milisecond < 1) then return end
    -- if not (type(fn)) == 'function' then return end
    local expire = (milisecond / 1000) + globals.RealTime()
    -- print( 'index: ' .. #_queue+1 .. ' registered, run at: ' .. expire )
    table.insert( _queue, { expire, fn } )
end

local settimeout_timer = function()
    local now = globals.RealTime()
    for k, v in ipairs( _queue ) do
        local expire, fn = v[1], v[2]
        if not (expire > now) then
            -- print( 'index: ' .. k .. ' expired' .. ' at: ' .. now )
            fn()
            table.remove( _queue, k )
        end
    end
end
callbacks.Register( 'Draw', 'settimeout_timer', settimeout_timer )
-- #endregion WIP timeout fn

-- #region utils 
local function compare( a, b )
    return a < b
end
local function PairsByValues( tbl, fn )
    local key, value = {}, {} --  key assigns 'a', value assigns 'b'
    for k, v in pairs( tbl ) do
        table.insert( value, v )
        key[v] = k
    end
    table.sort( value, fn )
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if value[i] == nil then
            return nil
        else
            return key[value[i]], value[i]
        end
    end
    return iter
end
-- #endregion utils

local tf_party_chat = function( sep, ... )
    local tb = { ... }
    if (#sep > 3) then
        table.insert( tb, 1, sep )
        sep = ' '
    end
    local final = table.concat( tb, sep )
    client.Command( table.concat( { 'tf_party_chat \"', final, "\"" } ), true )
end

-- todo: code looks pretty bad, could rewrite this
local cmdarg, cmd = {}, {}

local queue_type = { "casual", "competitive", "bootcamp", "mannup" }

-- todo : rewrite this resource
local help_resources = {  -- "lobbyinfo: query matchmaking info [see docs]", 
-- "gameinfo : query game info (if ingame)",
-- "userinfo: get script runner computer info", 
-- args
".whois: query party member info", ".join [steamid64]: join lobby of this player",
".invite [steamid64]: invite this player to lobby", ".queue: read docs", ".clearqueue: cancel all matchmaking request",
".stopqueue: cancel the last request to queue up for a match group.", 
-- no args
".abandon: i will abandon current match",
-- "q casual: request to queue up for 12v12 gamemode",
-- "q comp: request to queue up for 6v6 ranked gamemode",
-- "q bootcamp: request to queue up for community mvm",
-- "q mannup: request to queue up for valve mvm",
--".autoaccept: auto accept pending lobby memebers for steam friend", ">see docs at github.com" 
}

cmd['help'] = function()
    for i, v in ipairs( help_resources ) do
        tf_party_chat( v )
    end
    return true
end
cmd['.help'] = cmd['help']

cmd['.ping'] = function()
    local dataCenters = gamecoordinator.GetDataCenterPingData()
    local bestdatacenter, bestPing = '', 999
    local i = 0
    local value = {}
    tf_party_chat( "best server ping for", steam.GetSteamID() )
    local dataCenters = gamecoordinator.GetDataCenterPingData()
    for k, v in PairsByValues( dataCenters, compare ) do
        if (i < 3) then
            tf_party_chat( "-", k, v )
            i = i + 1
        end
    end
    return true
end

cmd['.whois'] = function()
    local user, name
    local members = party.GetMembers()
    tf_party_chat( ' | ', "name", "steam", "online", "lobby" )
    for k, steamid in ipairs( members ) do
        name = steam.GetPlayerName( steamid )
        user = party.GetMemberActivity( k )
        tf_party_chat( ' | ', name, steamid, (user:IsOnline() and 'true' or 'false'), user:GetLobbyID() )
        if user:IsMultiqueueBlocked() then
            tf_party_chat( name, " is currently blocked from joining official matchmaking" )
        end
    end
    return true
end

cmd['.abandon'] = function() -- next version!
    -- gamecoordinator.AbandonMatch()
end

-- ==== --

cmdarg['.shutdown'] = function( message, steamid ) -- next version!
    -- party.Leave()
    -- os.exit()
end

cmdarg['.connect'] = function( message, steamid ) -- next version!
    -- client.Command( "connect" .. message, true )
end

cmdarg['.queue'] = function( message, steamid )
    -- todo : waiting for blackfire
end
cmdarg['.join'] = function( message, steamid )
    if (steam.GetPlayerName( message ) == "[unknown]") then
        return print( "Error, invalid steamid" )
    end
    client.Command( "tf_party_request_join_user " .. message, true )
end
cmdarg['.invite'] = function( message, steamid )
    if (steam.GetPlayerName( message ) == "[unknown]") then
        return print( "Error, invalid steamid" )
    end
    client.Command( "tf_party_invite_user " .. message, true )
end
cmdarg['.parse'] = function( message, steamid )
    printc( 255, 0, 0, 255, table.concat( { "parsed:", #message, "characters:", message, "steamid:", steamid }, ' ' ) )
end

local history_steamid, was_cmd_parsed

local observe_party_chat = function( event )
    if not (event:GetName() == 'party_chat') then
        return
    end

    local message = event:GetString( 'text' )
    local steamid = tonumber( event:GetString( 'steamid' ) )
    local me = steam.GetSteamID()
    local steam3_x86 = string.sub( me, 6, #me - 1 )
    local me = steam3_x86 + 76561197960265728

    if (history_steamid == me) and (history_steamid == steamid) then
        -- print( 'prevent self recursion -> return.' )
        -- return
    end

    history_steamid = steamid
    for i, v in ipairs( { message } ) do
        local s = type( cmd[v] ) == "function" and cmd[v]()
        -- print( s )
        if not (s) then
            for k, v in pairs( cmdarg ) do
                local found_at = string.find( message, k )
                -- print( foundAt )
                if found_at == 1 then -- located at the start
                    local parse = string.sub( message, #k + 2, #message ) -- from characters after [key] plus whitespace until the end
                    if (#parse < 1) then
                        return
                    end
                    return v( parse, steamid )
                end
            end
        end

    end
end
callbacks.Register( 'FireGameEvent', 'observe_party_chat', observe_party_chat )

local OnStartup = (function()
    -- for k, v in pairs( cmdarg ) do print( k, v ) end
    -- client.Command( "tf_party_ignore_invites 0", true )
    -- client.Command( "tf_party_join_request_mode 1", true )

    -- create lobby (ghetto)
    if not (party.GetGroupID()) then
        party.QueueUp( 7 )
    end

    settimeout( 2000, function() -- may depend on internet
        party.CancelQueue( 7 )
    end )
end)()

