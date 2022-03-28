-- LuaFormatter off
--[[ 
    lobby.lua | Test Build | Moonverse#9320 is looking for comments and suggestions
    https://github.com/LewdDeveloper/lmaobox-scripting 
]] -- 
-- LuaFormatter on
local __human_version__ = "1.0.0.0"

callbacks.Unregister( 'FireGameEvent', 'observe_party_chat' )
callbacks.Unregister( 'FireGameEvent', 'event_observer' )

-- #region WIP timeout fn
callbacks.Unregister( 'Draw', 'settimeout_timer' )
local _queue = {}
local settimeout = function( milisecond, fn, loop_forever )
    local expire = (milisecond / 1000) + globals.RealTime()
    -- print( 'index: ' .. #_queue+1 .. ' registered, run at: ' .. expire )
    if (loop_forever) then
        table.insert( _queue, { expire, fn, milisecond } )
    else
        table.insert( _queue, { expire, fn, 0 } )
    end
end

local settimeout_timer = function()
    local now = globals.RealTime()
    for k, v in ipairs( _queue ) do
        local expire, fn, milisecond = v[1], v[2], v[3]
        if not (expire > now) then
            -- print( 'index: ' .. k .. ' expired' .. ' at: ' .. now )
            fn()
            table.remove( _queue, k )
            if (milisecond > 0) then
                settimeout( milisecond, fn, true )
            end
        end
    end
end
callbacks.Register( 'Draw', 'settimeout_timer', settimeout_timer )
-- #endregion WIP timeout fn

-- #region utils 
local round_number = function( num )
    num = (num - math.floor( num ) > 0.5) and math.ceil( num ) or math.floor( num )
    return num
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

-- #region : vscode-ext inline color
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

local text_builder = function( sep, ... )
    local tb = { ... }
    if (#sep > 3) then
        table.insert( tb, 1, sep )
        sep = ' '
    end
    return table.concat( tb, sep )
end

local tf_party_chat = function( sep, ... )
    local final = text_builder( sep, ... )
    client.Command( table.concat( { 'tf_party_chat \"', final, "\"" } ), true )
end

local print_console = function( sep, ... )
    local final = text_builder( sep, ... )
    print( final )
end

local print_console_color = function( color, sep, ... )
    local r, g, b, a = table.unpack( color )
    local final = text_builder( sep, ... )
    return printc( r, g, b, a, final )
end
local adv_cmd, basic_cmd, config = {}, {}, {}
local blacklisted_steamid, superuser_steamid = {}, {}
local queue_type = { "casual", "competitive", "bootcamp", "mannup" }

config = {
    auto_queue = false, -- next update, auto_queue has 4 mode : 1. disabled, 2. will not queue if  IsInStandbyQueue, 3. force new queue when in lobby, 4. QueueUpStandby if IsInStandbyQueue, else new queue
    fast_join = false
 }

config.toggle = function( key, bAnnouce )
    config[key] = not config[key]
    if (bAnnouce) then
        tf_party_chat( "config:", key, "is", (config[key] and 'enabled' or 'disabled') )
    end
end

local allowExecute = false -- todo : chat timeout + permission

-- #region basic. cmd

basic_cmd['.ping'] = function()
    local dataCenters = gamecoordinator.GetDataCenterPingData()
    local bestdatacenter, bestPing = '', 999
    local i = 0
    local value = {}
    tf_party_chat( "best server ping for", steam.GetSteamID() )
    local dataCenters = gamecoordinator.GetDataCenterPingData()
    -- LuaFormatter off
        for k, v in PairsByValues( dataCenters, function( a, b ) return a > b end ) do
        -- LuaFormatter on
        if (i < 3) then
            tf_party_chat( "-", k, v )
            i = i + 1
        end
    end
    return true
end

basic_cmd['.party'] = function()
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

basic_cmd['.autoqueue'] = function()
    config.toggle( 'auto_queue', true )
end

basic_cmd['.fastjoin'] = function()
    config.toggle( 'fast_join', true )
end

basic_cmd['.abandon'] = function() -- #testing-commands
    if (allowExecute) then
        gamecoordinator.AbandonMatch()
    end
end

basic_cmd['.stopqueue'] = function()

end

basic_cmd['.clearqueue'] = function()

end

-- #endregion basic. cmd

-- #region adv. cmd

adv_cmd['.shutdown'] = function( message, steamid ) -- #testing-commands
    if (allowExecute) then
        party.Leave()
        os.exit()
    end
end

adv_cmd['.connect'] = function( message, steamid ) -- #testing-commands
    if (allowExecute) then
        client.Command( "connect" .. message, true )
    end
end

adv_cmd['.queue'] = function( message, steamid )
    -- todo : waiting for blackfire
end

adv_cmd['.join'] = function( message, steamid ) -- #testing-commands
    if (steam.GetPlayerName( message ) == "[unknown]") then -- todo : check if steamid has valid structure instead
        return print( "Error, invalid steamid" )
    end
    client.Command( "tf_party_request_join_user " .. message, true )
end

adv_cmd['.invite'] = function( message, steamid ) -- #testing-commands
    if (steam.GetPlayerName( message ) == "[unknown]") then
        return print( "Error, invalid steamid" )
    end
    client.Command( "tf_party_invite_user " .. message, true )
end

adv_cmd['.parse'] = function( message, steamid ) -- #testing-commands
    printc( 255, 0, 0, 255, table.concat( { "parsed:", #message, "characters:", message, "steamid:", steamid }, ' ' ) )
end

-- #endregion adv. cmd

local help_resources = {  -- "lobbyinfo: query matchmaking info [see docs]", 
-- "gameinfo : query game info (if ingame)",
-- "userinfo: get script runner computer info", 
-- args
".party: query party info", ".join [steamid64]: join lobby of this player",
".invite [steamid64]: invite this player to lobby", ".queue: read docs", ".clearqueue: cancel all matchmaking request",
".stopqueue: cancel the last request to queue up for a match group.", ".autoqueue : read docs",
".abandon: i will abandon current match" -- "q casual: request to queue up for 12v12 gamemode",
-- "q comp: request to queue up for 6v6 ranked gamemode",
-- "q bootcamp: request to queue up for community mvm",
-- "q mannup: request to queue up for valve mvm",
-- ".autoaccept: auto accept pending lobby memebers for steam friend", ">see docs at github.com" 
 }

basic_cmd['help'] = function()
    for i, v in ipairs( help_resources ) do
        tf_party_chat( v )
    end
    return true
end
basic_cmd['.help'] = basic_cmd['help']

--- '#>.<#\ ---

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
        local s = type( basic_cmd[v] ) == "function" and basic_cmd[v]()
        -- print( s )
        if not (s) then
            for k, v in pairs( adv_cmd ) do
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

local event_observer = function( event )
    if (event:GetName() == "match_invites_updated") then
        if (gamecoordinator.GetNumMatchInvites() > 0) and config['fast_join'] then
            gamecoordinator.AcceptMatchInvites()
        end
    end
end
callbacks.Register( 'FireGameEvent', 'event_observer', event_observer )

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

    settimeout( 5000, function()
        if not config['auto_queue'] or gamecoordinator.HasLiveMatch() or gamecoordinator.IsConnectedToMatchServer() or
            gamecoordinator.GetNumMatchInvites() > 0 then
            return
        end

        if #party.GetQueuedMatchGroups() == 0 and not party.IsInStandbyQueue() then
            party.QueueUp( 7 )
        end
    end, true )
end)()

