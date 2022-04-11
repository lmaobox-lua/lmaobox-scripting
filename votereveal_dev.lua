callbacks.Unregister( 'FireGameEvent', "event_observer" )
callbacks.Unregister( 'FireGameEvent', 'votecounting' )

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
    ---
    run this example: 
        luatable = { [0] = "a", "b", [3] = "g", "c", "f", [3] = "e", [99] = "h", ['99'] = "h" }
        luatable[3] = "what"
        for key,value in ipairs(luatable) do print(key,value,type(key)) end
        for key,value in pairs(luatable) do print(key,value,type(key)) end
    ..remove the line contains: luatable[3] = "what" and run the example again.
]]
local user_message_callbacks = {
    [CallVoteFailed] = {}, -- Sent to a player when they attempt to call a vote and fail.
    [VoteStart] = {}, -- Sent to all players currently online. The default implementation also sends it to bots.
    [VotePass] = {}, -- Sent to all players after a vote passes.
    [VoteFailed] = {}, -- Sent to all players after a vote fails.
    [VoteSetup] = {} -- Sent to a player when they load the Call Vote screen (which sends the callvote command to the server), lists what votes are allowed on the server
 }

user_message_callbacks.new = function( id, unique, callback ) -- this has noticable delay
    assert( type( id ) == "number" and type( unique ) == "string" and type( callback ) == "function",
        string.format( "user_message_callback.new failed to register callbacks: <line: %s, id: %s, unique: %s>",
            debug.getinfo( 2, 'l' ).currentline, id, unique ) )
    callbacks.Unregister( 'DispatchUserMessage', unique )
    callbacks.Register( 'DispatchUserMessage', unique, function( msg )
        if (msg:GetID() == id) then
            callback( msg )
        end
    end )
    table.insert( user_message_callbacks[id], unique )
    return unique
end

callbacks.Register( 'Unload', function()
    -- normally this isn't needed, but knowing i may fuck it up this is the final cleanup
    for i, v in pairs( user_message_callbacks ) do
        if type( v ) == "table" and next( v ) ~= nil then
            for i1, v1 in pairs( v ) do
                callbacks.Unregister( 'DispatchUserMessage', v1 )
            end
        end
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
local team_t = {
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

-- region: predict vote outcome [exprimental feature, and pretty spaghetti]
-- LuaFormatter off
local tally = {
    --o1, o2, o3, o4, o5, -- (table) playerindex of player choosed option
    eligible, -- (table) playerindex of member allowed to vote for this issue
    poll, -- (table) playerindex of member already voted with value being the chosen option
    count, -- (vote_options) number of options can be voted in this issue (max: 5)
    is_yes_no_vote, -- (usermessage or vote_options: count <= 2: is_yes_no_vote , count > 2 : multi-option vote )
    team_t, -- (usermessage) which team can vote
}
-- LuaFormatter on

-- if usual, vote_cast and vote_options gets called before usermessages

function tally:get_eligible_voter( team )
    self.team_t = team
    local is_yes_no_vote = not (self.count > 2)
    local free_for_all_vote = team == TFUnassigned
    local sv_vote_allow_spectators = tonumber( client.GetConVar( 'sv_vote_allow_spectators' ) )
    local filter = {}

    for index, ent in ipairs( entities.FindByClass( 'CTFPlayer' ) ) do
        repeat
            local playerinfo = client.GetPlayerInfo( index )
            if playerinfo.IsBot or playerinfo.IsHLTV then
                filter[index] = string.format( "[filter] L1 | IsBot: %s, IsHLTV: %s", playerinfo.IsBot, playerinfo.IsHLTV )
                break
            end
            if sv_vote_allow_spectators == 0 and ent:GetTeamNumber() == TFSpectator then
                filter[index] = string.format( "[filter] L2 | sv_vote_allow_spectators: %s, team: %s", sv_vote_allow_spectators,
                    ent:GetTeamNumber() )
                break
            end
            if not free_for_all_vote and ent:GetTeamNumber() ~= self.team_t then
                filter[index] = string.format( "[filter] L3 | free_for_all_vote: %s, team: %s", free_for_all_vote, ent:GetTeamNumber() )
                break
            end
            -- todo : need further testing
            if gamerules.IsMvM() and ent:GetTeamNumber() ~= TFRed then
            end
            filter[index] = true
        until true
    end

    -- override said logic if player has already voted
    for playerindex, voteoption in pairs( self.poll ) do
        filter[playerindex] = true
    end

    for i, v in ipairs( filter ) do
        if v == true then
            self.eligible[#self.eligible + 1] = i
        end
    end

end

function tally:begin( count )
    self.count = count
    local is_yes_no_vote = not (self.count > 2)
    self.is_yes_no_vote = is_yes_no_vote
    self.poll = {}
    self.eligible = {}
end

local talley_counting = function( event )
    local vote_option<const> = event:GetInt( 'vote_option' )
    local team<const> = event:GetInt( 'team' )
    local entityindex<const> = event:GetInt( 'entityid' )

    tally.poll[entityindex] = vote_option

    local count = 0
    for i, v in pairs( tally.poll ) do
        count = count + 1
    end

    if next( tally.eligible ) == nil or tally.count == nil then
    end

    local text = ''

    local a, b, c, d, e = 0, 0, 0, 0, 0
    local voted, al, bl, cl, dl, el

    -- truly gay code
    for i, v in pairs( tally.poll ) do
        repeat
            if v == 0 then
                a = a + 1
            elseif v == 1 then
                b = b + 1
            elseif v == 2 then
                c = c + 1
            end
        until true
    end

    voted = a + b
    al = (a) / count * 100
    bl = (b + count - voted) / count * 100 -- because hasn't voted also count as no vote
    text = string.format( '| Yes: %s, No: %s', al, bl )
    
    -- this thing needs to be logged into console, no way to retrack valve weight on f2p votes and p2p votes man.
    print( a, b, count )

    -- calculate completion percentage
    print( text )
    return text
end
-- C:\Users\localuser\AppData\Local//lbox/votereveal_dev.lua:275: attempt to perform arithmetic on a nil value (field '?')

callbacks.Register( 'FireGameEvent', 'tally_count', function( event )
    if (event:GetName() == "vote_options") then
        tally:begin( event:GetInt( 'count' ) )
    end
end )

-- 1 byte = 8 bits
user_message_callbacks.new( VoteStart, "tally_vote_start", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    msg:SetCurBit( 192 )
    local is_yes_no_vote<const> = msg:ReadByte() -- true for Yes/No, false for Multiple choice
    tally.get_eligible_voter( tally, team ) -- main problem is yes/no already counted before usermessage gets calledd
    -- we have to change our logic
    return true
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
        local str = talley_counting( event )

        local final = string.format( "%s%s %s%s %s %s%s %s%s", --
        colors[team], team_t[team], -- %1s%2s
        white_c, player_name, -- %3s%4s
        "voted", -- %5s
        colors[vote_option + 4], vote_t[vote_option], -- %6s%7s
        white_c, str -- %8s%9s
         )
        client.ChatPrintf( final )
        -- todo colors[vote_option + 4] could be misleading!
    end
end )

user_message_callbacks.new( VoteStart, "MsgFunc_VoteStart", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local ent_idx<const> = msg:ReadByte() -- Client index of person who started the vote, or 99 for the server.
    local disp_str<const> = msg:ReadString( 256 ) -- Vote issue translation string
    local details_str<const> = msg:ReadString( 256 ) -- Vote issue text
    local is_yes_no_vote<const> = msg:ReadByte() -- true for Yes/No, false for Multiple choice
    ---
    local s = localize_and_format( disp_str, details_str )
    local text = table.concat( { colors[team], team_t[team], " ", white_c, s } )
    client.ChatPrintf( text )
end )

user_message_callbacks.new( VotePass, "MsgFunc_VotePass", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local disp_str<const> = msg:ReadString( 256 ) -- Vote success translation string
    local details_str<const> = msg:ReadString( 256 ) -- Vote winner
    ---
    local s = localize_and_format( disp_str, details_str )
    local text = table.concat( { colors[team], team_t[team], " ", white_c, s } )
    client.ChatPrintf( text )
end )

user_message_callbacks.new( VoteFailed, "MsgFunc_VoteFailed", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local reason<const> = msg:ReadByte() -- Failure reason code (0, 3-4)
    ---
    local s = localize_and_format( vote_failed_localize[reason] )
    local text = table.concat( { colors[team], team_t[team], " ", achievement_c, s } )
    client.ChatPrintf( text )
end )

user_message_callbacks.new( CallVoteFailed, "MsgFunc_CallVoteFailed", function( msg )
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
