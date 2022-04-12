callbacks.Unregister( 'FireGameEvent', "event_observer" )

-- region: global to local variable
-- endregion: global to local variable

-- region: constant and helper function
-- LuaFormatter off
local white_c<const>, old_c<const>, team_c<const>, location_c<const>, achievement_c<const>, black_c<const> = '\x01', '\x02', '\x03', '\x04', '\x05', '\x06'
local  rgb_c = function( hexcodes ) return '\x07' .. string.sub(hexcodes, 2, #hexcodes)  end
local argb_c = function( hexcodes_a ) return '\x08' .. string.sub(hexcodes_a, 2, #hexcodes_a) end
-- LuaFormatter on
local to_rgba = function( hexcodes_a )
    local integer = tonumber( "0x" .. hexcodes_a:sub( 2, #hexcodes_a ) )
    assert( integer < 4294967295, "hexcodes cannot go over 32bits" )
    local r, g, b, a
    a = integer & 0xFF
    r = integer >> 24 & 0xFF
    g = integer >> 16 & 0xFF
    b = integer >> 8 & 0xFF
    return r, g, b, a
end

local try_localize_key = function( key, fallback )
    local localized = client.Localize( key )
    key = (#localized > 0 and localized ~= nil) and localized or fallback or key
    return key
end

local localize_and_format = function( key, ... )
    local text = try_localize_key( key )
    local va_args, order = { ... }, {}
    text = text:gsub( '%%s(%d+)', function( i )
        return "%" .. tonumber( i ) -- .. "s" -> %%(%d+)s
    end )
    text = text:gsub( '%%(%d+)', function( i )
        table.insert( order, va_args[tonumber( i )] or "nil" )
        return '%s'
    end )
    text = string.format( text, table.unpack( order ) )
    return text
end
-- endregion: constant and helper function

-- region: callback handler
--[[
    when to ipairs vs pairs, dumbed down version
    use ipairs to iterate ALL over table when table doesn't contain String keys
        , MUST contain first numeric key: example: luatable[1]
        , numeric keys must not smaller than 1: example: luatable[0] will get ignored
        , numeric keys are in sequence (ordered lists of numbers represented by the formula n+1)
    use pairs to iterate when table contains a string keys
    otherwise, use loop
    ---
    run this example: 
        luatable = { [0] = "a", "b", [3] = "g", "c", "f", [3] = "e", [99] = "h", ['99'] = "h" }
        luatable[3] = "what"
        for key,value in ipairs(luatable) do print(key,value,type(key),"-> ipairs") end
        for key,value in pairs(luatable) do print(key,value,type(key), "-> pairs") end
        for key=-1, #luatable do local value = luatable[key]; print(key,value,type(key), "-> loop") end
        print(#luatable)
    ..remove the line contains: luatable[3] = "what" and run the example again.
]]

-- todo : Looks pretty complicated, i should rewrite this in a near future.
-- 13/4/2022
--  the use case of callbacks.register without unique is when we only register the id once in script lifetime
-- register the same unique will override the previous unique (im thinking do i have to manually write code to unload callbacks again)
-- UnloadScript takes absolute path, hmmm
-- todo : um table is legacy code and i should change it's structure to be the same as event.

local um = {
    [CallVoteFailed] = {}, -- Sent to a player when they attempt to call a vote and fail.
    [VoteStart] = {}, -- Sent to all players currently online. The default implementation also sends it to bots.
    [VotePass] = {}, -- Sent to all players after a vote passes.
    [VoteFailed] = {}, -- Sent to all players after a vote fails.
    [VoteSetup] = {} -- Sent to a player when they load the Call Vote screen (which sends the callvote command to the server), lists what votes are allowed on the server
 }
um.new = function( id, unique, callback ) -- this has noticable delay
    assert( type( id ) == "number" and type( unique ) == "string" and type( callback ) == "function",
        string.format( "[user_message] failed to register callbacks: <line: %s, id: %s, unique: %s>", debug.getinfo( 2, 'l' ).currentline,
            id, unique ) )

    callbacks.Unregister( 'DispatchUserMessage', unique )
    callbacks.Register( 'DispatchUserMessage', unique, function( msg )
        if msg:GetID() == id then
            -- local eval, ret = pcall(callback, msg)
            -- assert(eval == true, string.format('callbacks error: <unique: %s, ret: %s>', unique, ret))
            callback( msg )
        end
    end )
    table.insert( um[id], unique )
    return unique
end

local events = {}
events.new = function( id, callback )
    local unique = '_seed_' .. tostring( engine.RandomInt( 0, 0x7FFF ) )
    assert( type( id ) == "string" and type( unique ) == "string" and type( callback ) == "function",
        string.format( "[fire_game_event] failed to register callbacks: <line: %s, id: %s, unique: %s>",
            debug.getinfo( 2, 'l' ).currentline, id, unique ) )

    callbacks.Unregister( 'FireGameEvent', unique )
    callbacks.Register( 'FireGameEvent', unique, function( event )
        if event:GetName() == id then
            -- local eval, ret = pcall(callback, event)
            -- assert(eval == true, string.format('callbacks error: <unique: %s, ret: %s>', unique, ret))
            callback( event )
        end
    end )
    events[#events + 1] = unique
    return unique
end

callbacks.Register( 'Unload', function()
    for i, v in pairs( um ) do
        if type( v ) == "table" and next( v ) ~= nil then
            for i1, v1 in pairs( v ) do
                callbacks.Unregister( 'DispatchUserMessage', v1 )
            end
        end
    end
    for i = 1, #events do
        callbacks.Unregister( "FireGameEvent", events[i] )
    end
    local r, g, b, a = to_rgba( '#39b83dff' )
    printc( r, g, b, a, string.format( "[%s] previous instance:\n%s was unloaded", os.date( '%c' ), GetScriptName() ) )
end )

-- endregion: callback handler

-- region: UserMessage resources
-- https://wiki.alliedmods.net/Tf2_voting
-- http://lua-users.org/wiki/SwitchStatement
-- https://github.dev/lua9520/source-engine-2018-hl2_src/ (note: reference only)

local vote_failed_reason_t<const> = {
    [0] = "VOTE_FAILED_GENERIC",
    [1] = "VOTE_FAILED_TRANSITIONING_PLAYERS",
    [2] = "VOTE_FAILED_RATE_EXCEEDED",
    [3] = "VOTE_FAILED_YES_MUST_EXCEED_NO",
    [4] = "VOTE_FAILED_QUORUM_FAILURE",
    [5] = "VOTE_FAILED_ISSUE_DISABLED",
    [6] = "VOTE_FAILED_MAP_NOT_FOUND",
    [7] = "VOTE_FAILED_MAP_NAME_REQUIRED",
    [8] = "VOTE_FAILED_ON_COOLDOWN",
    [9] = "VOTE_FAILED_TEAM_CANT_CALL",
    [10] = "VOTE_FAILED_WAITINGFORPLAYERS",
    [11] = "VOTE_FAILED_PLAYERNOTFOUND",
    [12] = "VOTE_FAILED_CANNOT_KICK_ADMIN",
    [13] = "VOTE_FAILED_SCRAMBLE_IN_PROGRESS",
    [14] = "VOTE_FAILED_SPECTATOR",
    [15] = "VOTE_FAILED_NEXTLEVEL_SET",
    [16] = "VOTE_FAILED_MAP_NOT_VALID",
    [17] = "VOTE_FAILED_CANNOT_KICK_FOR_TIME",
    [18] = "VOTE_FAILED_CANNOT_KICK_DURING_ROUND",
    [19] = "VOTE_FAILED_VOTE_IN_PROGRESS",
    [20] = "VOTE_FAILED_KICK_LIMIT_REACHED",
    [21] = "VOTE_FAILED_KICK_DENIED_BY_GC"
 }

local vote_failed_localize<const> = {
    [0] = "#GameUI_vote_failed",
    [3] = "#GameUI_vote_failed_yesno",
    [4] = "#GameUI_vote_failed_quorum"
 }

local vote_call_vote_failed_localize<const> = {
    [1] = "#GameUI_vote_failed_transition_vote",
    [2] = function( time )
        local response = (time > 60) and "#GameUI_vote_failed_vote_spam_min" or "#GameUI_vote_failed_vote_spam_mins"
        return response
    end,
    [5] = "#GameUI_vote_failed_disabled_issue",
    [6] = "#GameUI_vote_failed_map_not_found",
    [7] = "#GameUI_vote_failed_map_name_required",
    [8] = function( time )
        local response = (time > 60) and "GameUI_vote_failed_recently_min" or "GameUI_vote_failed_recently_mins"
        return response
    end,
    [9] = "#GameUI_vote_failed_team_cant_call",
    [10] = "#GameUI_vote_failed_waitingforplayers",
    [11] = "VOTE_FAILED_PLAYERNOTFOUND", -- doesn't appear to work
    [12] = "#GameUI_vote_failed_cannot_kick_admin",
    [13] = "#GameUI_vote_failed_scramble_in_prog",
    [14] = "#GameUI_vote_failed_spectator",
    [15] = "#GameUI_vote_failed_nextlevel_set",
    [16] = "#GameUI_vote_failed_map_not_valid",
    [17] = function( time ) -- VOTE_FAILED_ON_COOLDOWN
        local response = (time > 60) and "#GameUI_vote_failed_cannot_kick_min" or "#GameUI_vote_failed_cannot_kick_mins"
        return response
    end,
    [18] = "GameUI_vote_failed_round_active",
    [19] = "#GameUI_vote_failed_event_already_active"
 }

local vote_setup_localize<const> = { "#TF_Kick", "#TF_RestartGame", "#TF_ChangeLevel", "#TF_NextLevel", "#TF_ScrambleTeams",
                                     "#TF_ChangeMission", "#TF_TeamAutoBalance_Enable", "#TF_TeamAutoBalance_Disable",
                                     "#TF_ClassLimit_Enable", "#TF_ClassLimit_Disable" }
-- endregion: UserMessage resources

-- region:
local TFUnassigned<const>, TFSpectator<const>, TFRed<const>, TFBlu<const> = 0, 1, 2, 3
local team_can_vote = {
    [0] = "[All]",
    [1] = "[Spectator]",
    [2] = "[Red]",
    [3] = "[Blu]"
 }

local colors = {
    [0] = argb_c( "#9EE09Eff" ),
    [1] = argb_c( "#cfcfc4ff" ),
    [2] = argb_c( "#ff6663ff" ),
    [3] = argb_c( "#9EC1CFff" ),
    [4] = argb_c( "#B4CFB0ff" ),
    [5] = argb_c( "#D885A3ff" ),
    [6] = argb_c( "#D885A3ff" ),
    [7] = argb_c( "#F6D7A7ff" ),
    [8] = argb_c( "#87AAAAff" )
 }

local vote_default_t = {
    [0] = "Yes",
    [1] = "No"
 }

local vote_t = {}

-- region: predict vote outcome
local vote = { has_voted, can_vote, options, is_yes_no_vote, team_can_vote, details_str }

-- @param count: number
function vote:begin( count )
    self.players_voted = {} -- table: [pairs] playerindex | option, of player already chosed an option in this issue 
    self.players_can_vote = {} -- table: [ipairs] playerindex, of player allowed to vote in this issue 
    self.options = count -- number: options can be voted in this issue (max: 5) (from vote_options)
    self.is_yes_no_vote = count ~= 2 -- boolean: true for Yes/No, false for Multiple choice (from VoteStart, but checking count =~ 2 is adequate enough)
    self.team_can_vote = nil -- ?number: which team can vote (from VoteStart)
    self.details_str = '' -- string: used for visualising
end

-- @table vote
-- @return can_vote 
function vote:query_voting_status()
    local team = self.team_can_vote
    local filter = {} -- table: [pairs]
    local players = entities.FindByClass( 'CTFPlayer' ) -- table: [ipairs]

    if not team then
        -- note : game_event is called before user_message, maybe teamid hasn't been dispatched yet.
        players = {}
    end

    -- note : f2p opinion does not count
    local count_players_can_vote, count_player_has_voted = 0, 0
    local options = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0
     }
    local all_vote = team == TFUnassigned
    local vote_allow_spectators = client.GetConVar( 'sv_vote_allow_spectators' ) ~= 0 -- networked convar
    -- client.GetConVar returns int, num, string
    -- returns int, num if convar value is a number and 0, 0.0 otherwise
    -- in lua, conditionals consider false and nil as false and anything else as true. 

    for i = 1, #players do
        local ent, t, c
        ent = players[i]
        t = ent:GetTeamNumber()
        c = client.GetPlayerInfo( i )
        repeat
            if not t then -- skip if player is not valid
                filter[i] = nil
                break
            end
            if c.IsBot or c.IsHLTV then
                filter[i] = string.format( "[filter] L1 | IsBot: %s, IsHLTV: %s", c.IsBot, c.IsHLTV )
                break
            elseif not vote_allow_spectators and t == TFSpectator then
                filter[i] = string.format( "[filter] L2 | sv_vote_allow_spectators: %s, teamid: %s", vote_allow_spectators, t )
                break
            elseif not all_vote and t ~= team then
                filter[i] = string.format( "[filter] L3 | free_for_all_vote: %s, team: %s", all_vote, t )
                break
            elseif gamerules.IsMvM() and t ~= TFRed then
                -- todo : donno what this does.
            else
                filter[i] = true
                break
            end
        until (true)
    end

    -- if player has already voted, count player as valid voter
    -- @table players_voted[entityindex] = vote_option
    for k, v in pairs( self.players_voted ) do
        filter[k] = true
        count_player_has_voted = count_player_has_voted + 1
        options[v + 1] = options[v + 1] + 1 -- __add
    end

    for k, v in pairs( filter ) do
        if v == true then
            self.players_can_vote[#self.players_can_vote + 1] = i
            count_players_can_vote = count_players_can_vote + 1
        end
    end
    -- print(string.format( "> count_players_can_vote: %s, count_player_has_voted: %s, options -> %s %s %s %s %s", count_players_can_vote, count_player_has_voted, table.unpack( options ) ))
    return count_players_can_vote, count_player_has_voted, options
end

events.new( 'vote_cast', function( event )
    local vote_option<const> = event:GetInt( 'vote_option' )
    local entityindex<const> = event:GetInt( 'entityid' )
    vote.players_voted[entityindex] = vote_option
    local count_players_can_vote, count_player_has_voted, options = vote:query_voting_status()

    local max, index = 0, 0
    for i = 1, #options do
        local v = options[i]
        if max < v then
            max = v
            index = i
        end
    end
    max = max / count_players_can_vote * 100

    -- percentage of most picked vote
    vote.details_str = string.format( "(option%s: %.f%s)", index, max, "%%" )
    -- Using default values, votes require a minimum of 60% of the team to vote Yes for the vote to succeed. This is controlled with the server command sv_vote_quorum_ratio.
    -- But idk how valve calculates vote kick on matchmaking so it's your turn to contribute
    -- Kick votes will end early and automatically pass if the vote target leaves the match during the vote
end )

events.new( 'vote_options', function( event )
    vote:begin( event:GetInt( 'count' ) )
end )

-- 1 byte = 8 bits
um.new( VoteStart, "tally_vote_start", function( msg )
    local team<const> = msg:ReadByte()
    msg:SetCurBit( 192 )
    vote.team_can_vote = team
end )

-- endregion: predict vote outcome

callbacks.Register( 'FireGameEvent', 'event_observer', function( event )
    if (event:GetName() == "vote_options") then -- called when there's a new voteissue
        -- todo : this seems bugged atm, too lazy to find where problem is, plus idk how multi-option vote works
        local count = event:GetInt( 'count' )
        if (count < 3) then
            vote_t = vote_default_t
            return
        end
        for i = 1, count do
            vote_t[i - 1] = event:GetString( 'option' .. i )
        end
    end

    if (event:GetName() == "vote_cast") then
        local vote_option<const> = event:GetInt( 'vote_option' )
        local team<const> = event:GetInt( 'team' )
        local entityindex<const> = event:GetInt( 'entityid' )
        ---
        local entity = entities.GetByIndex( entityindex )
        local player_name = entity:GetName() or '<player left>'
        local str = vote.details_str

        local final = string.format( "%s%s %s%s %s %s%s %s%s", --
        colors[team], team_can_vote[team], -- %1s%2s
        white_c, player_name, -- %3s%4s
        "voted", -- %5s
        colors[vote_option + 4], vote_t[vote_option], -- %6s%7s
        white_c, str -- %8s%9s
         )
        client.ChatPrintf( final )
        -- todo colors[vote_option + 4] could be misleading!
    end
end )

um.new( VoteStart, "MsgFunc_VoteStart", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local ent_idx<const> = msg:ReadByte() -- Client index of person who started the vote, or 99 for the server.
    local disp_str<const> = msg:ReadString( 256 ) -- Vote issue translation string
    local details_str<const> = msg:ReadString( 256 ) -- Vote issue text
    local is_yes_no_vote<const> = msg:ReadByte() -- true for Yes/No, false for Multiple choice
    ---
    local s = localize_and_format( disp_str, details_str )
    local text = table.concat( { colors[team], team_can_vote[team], " ", white_c, s } )
    client.ChatPrintf( text )
end )

um.new( VotePass, "MsgFunc_VotePass", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local disp_str<const> = msg:ReadString( 256 ) -- Vote success translation string
    local details_str<const> = msg:ReadString( 256 ) -- Vote winner
    ---
    local s = localize_and_format( disp_str, details_str )
    local text = table.concat( { colors[team], team_can_vote[team], " ", white_c, s } )
    client.ChatPrintf( text )
end )

um.new( VoteFailed, "MsgFunc_VoteFailed", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local reason<const> = msg:ReadByte() -- Failure reason code (0, 3-4)
    ---
    local s = localize_and_format( vote_failed_localize[reason] )
    local text = table.concat( { colors[team], team_can_vote[team], " ", achievement_c, s } )
    client.ChatPrintf( text )
end )

um.new( CallVoteFailed, "MsgFunc_CallVoteFailed", function( msg )
    local reason<const> = msg:ReadByte() -- Failure reason (1-2, 5-10, 12-19)
    local time<const> = msg:ReadInt( 16 ) -- For failure reasons 2 and 8, time in seconds until client can start another vote. 2 is per user, 8 is per vote type.
    ---
    local me = entities.GetLocalPlayer()
    local text = string.format( "%s%s %s%s %s%s left to wait before casting another vote. \r\n%s%s", --
    colors[me:GetTeamNumber()], "[YOU]", -- %1s%2s
    argb_c( "#FDFD97FF" ), time, -- %3s%4s
    white_c, (time <= 1 and "second" or "seconds"), -- %5s%6s
    achievement_c, vote_failed_reason_t[reason] -- %7s%8s
     )
    client.ChatPrintf( text )
end )
-- endregion:
