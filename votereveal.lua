-- region: global function to local variable
-- Returns a localized string. The localizable strings usually start with a # character, but there are exceptions. Will return nil on failure.
-- @param key:string
local localize = client.Localize
local table_insert, table_concat, string_format, chat_print_f = table.insert, table.concat, string.format,
    client.ChatPrintf
-- endregion: global function to local variable

callbacks.Unregister( 'DispatchUserMessage', 'usermessage_observer' )
callbacks.Unregister( 'FireGameEvent', "event_observer" )

-- region: custom string builder
-- LuaFormatter off
local white_c<const>, old_c<const>, team_c<const>, location_c<const>, achievement_c<const>, black_c<const> = '\x01', '\x02', '\x03', '\x04', '\x05', '\x06'
local  rgb_c = function( hex_no_alpha ) return '\x07' .. string.sub(hex_no_alpha, 2, #hex_no_alpha)  end
local argb_c = function( hex_with_alpha ) return '\x08' .. string.sub(hex_with_alpha, 2, #hex_with_alpha) end

--@param { color_c, text } or text
local ChatPrint = function( ... )
    local buf = {}
    for k, v in ipairs({...}) do
        local f, g
        if (type(v) == "table") then
             f, g = v[1], v[2]
            table_insert(buf, f .. g)
        else 
            f = v
            table_insert(buf, f)
        end 
    end
    local e = table_concat(buf, " ")
    return chat_print_f(e)
end
-- LuaFormatter on
-- endregion

-- region: UserMessage resources
-- https://wiki.alliedmods.net/Tf2_voting
-- http://lua-users.org/wiki/SwitchStatement
-- https://github.dev/lua9520/source-engine-2018-hl2_src/ (note: could be outdated)

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

local vote_setup_localize<const> = { "#TF_Kick", "#TF_RestartGame", "#TF_ChangeLevel", "#TF_NextLevel",
                                     "#TF_ScrambleTeams", "#TF_ChangeMission", "#TF_TeamAutoBalance_Enable",
                                     "#TF_TeamAutoBalance_Disable", "#TF_ClassLimit_Enable", "#TF_ClassLimit_Disable" }
-- endregion: UserMessage resources

local team_index = {
    [0] = "[All]",
    [1] = "[Spectator]",
    [2] = "[Red]",
    [3] = "[Blu]"
 }

local color_resource = {
    [0] = argb_c( "#9EE09Eff" ),
    [1] = argb_c( "#cfcfc4ff" ),
    [2] = argb_c( "#ff6663ff" ),
    [3] = argb_c( "#9EC1CFff" ),
    --
    [4] = argb_c( "#B4CFB0ff" ),
    [5] = argb_c( "#D885A3ff" ),
    [6] = argb_c( "#D885A3ff" ),
    [7] = argb_c( "#F6D7A7ff" ),
    [8] = argb_c( "#87AAAAff" )
 }

-- TODO #1
-- vote_prediction_outcome
local outcome = {
    [1] = 0, -- option1
    [2] = 0, -- option2
    [3] = 0, -- option3
    [4] = 0, -- option4
    [5] = 0, -- option5
    [6] = 0, -- voting
    is_yes_no_vote = nil,
    free_for_all_vote = nil
 }
function outcome:clear()
    for k, v in ipairs( outcome ) do
        -- print( 'key: ' .. tostring( k ) )
        outcome[k] = 0
    end
    self.is_yes_no_vote = nil
    self.free_for_all_vote = nil
end
function outcome:add( k, v )
    self[k] = v + v
    return true
end

local user_message_callback = {
    [CallVoteFailed] = {}, -- Note: Sent to a player when they attempt to call a vote and fail.
    [VoteStart] = {}, -- Note: Sent to all players currently online. The default implementation also sends it to bots.
    [VotePass] = {}, -- Note: Sent to all players after a vote passes.
    [VoteFailed] = {}, -- Note: Sent to all players after a vote fails.
    [VoteSetup] = {} -- Note: Sent to a player when they load the Call Vote screen (which sends the callvote command to the server), lists what votes are allowed on the server
 }

user_message_callback.bind = function( id, unique, callback )
    local s = user_message_callback[id]
    if type( s ) ~= "table" then
        print( "user_message_callback.bind fails to create callback: " .. unique )
    end
    if (type( unique ) == 'function') then
        callback = unique
        unique = tostring( math.randomseed( os.time() ) )
    end
    s[unique] = callback
    return unique
end

user_message_callback.unbind = function( id, unique )
    local s = user_message_callback[id]
    if type( s ) ~= "table" then
        print( "user_message_callback.unbind fails to remove callback: " .. unique )
    end
    s[unique] = undef
    return true
end

local vote_type = {
    [0] = "Yes",
    [1] = "No"
 }

callbacks.Register( 'FireGameEvent', 'event_observer', function( event )
    if (event:GetName() == "vote_options") then
        local count = event:GetInt( 'count' )
        -- local option1, option2, option3, option4, option5 = event:GetString( 'option1' ), event:GetString( 'option2' ), event:GetString( 'option3' ), event:GetString( 'option4' ), event:GetString( 'option5' )
        for i = 1, count, 1 do
            vote_type[i - 1] = event:GetString( 'option' .. i )
        end
    end

    if (event:GetName() == "vote_cast") then
        local vote_option<const> = event:GetInt( 'vote_option' )
        local team<const> = event:GetInt( 'team' )
        local entityindex<const> = event:GetInt( 'entityid' )

        local entity = entities.GetByIndex( entityindex )
        local plr_team = entity:GetTeamNumber()
        --- 

        ChatPrint( { color_resource[plr_team], team_index[plr_team] }, { white_c, entity:GetName() }, "voted",
            { color_resource[vote_option + 4], vote_type[vote_option] } )
        -- TODO vote_option + 4 is lazy variable naming 
    end
end )

user_message_callback.bind( VoteStart, function( msg )
    local team<const> = msg:ReadByte()
    local ent_idx<const> = msg:ReadByte()
    local disp_str<const> = msg:ReadString( 256 )
    local details_str<const> = msg:ReadString( 256 )
    local is_yes_no_vote<const> = msg:ReadByte()

    local players = entities.FindByClass( "CTFPlayer" )

    if (team == 0) then
        outcome.free_for_all_vote = true
        for k, v in ipairs( players ) do
            if (client.GetPlayerInfo( v:GetIndex() )['IsBot'] == false) then
                outcome:add( 6, 1 )
            end
        end
    else
        outcome.free_for_all_vote = false
        for k, v in ipairs( players ) do
            if (v:GetTeamNumber() == team and client.GetPlayerInfo( v:GetIndex() )['IsBot'] == false) then
                outcome:add( 6, 1 )
            end
        end
    end
    outcome.is_yes_no_vote = is_yes_no_vote
end )

user_message_callback.bind( VotePass, function( msg )
    print( outcome.free_for_all_vote )
    print( outcome.is_yes_no_vote )
    print( "outcome.voting: " .. tostring( outcome.voting ) )

    outcome:clear()
end )
user_message_callback.bind( VoteFailed, function( msg )
    outcome:clear()
end )

callbacks.Register( 'DispatchUserMessage', 'usermessage_observer', function( msg )
    local msg_enum = msg:GetID()
    local s = user_message_callback[msg_enum]
    if (type( s ) == "table") then
        for k, v in pairs( s ) do
            local fn = type( s[k] ) == "function" and s[k]( msg )
            msg:Reset()
        end
    end
end )

-- region: core function
user_message_callback.bind( VoteStart, "MsgFunc_VoteStart", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local ent_idx<const> = msg:ReadByte() -- Client index of person who started the vote, or 99 for the server.
    local disp_str<const> = msg:ReadString( 256 ) -- Vote issue translation string
    local details_str<const> = msg:ReadString( 256 ) -- Vote issue text
    local is_yes_no_vote<const> = msg:ReadByte() -- true for Yes/No, false for Multiple choice
    -- local target_ent_idx<const> = msg:ReadByte()

    local s = (#localize( disp_str ) > 0) and localize( disp_str ) or disp_str
    s = string.gsub(s, "%%s%d" , "%%s")
    s = string.format( s, details_str )

    ChatPrint( { color_resource[team], team_index[team] }, { white_c, s } )
end )

user_message_callback.bind( VotePass, "MsgFunc_VotePass", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local disp_str<const> = msg:ReadString( 256 ) -- Vote success translation string
    local details_str = msg:ReadString( 256 ) -- Vote winner

    local s = (#localize( disp_str ) > 0) and localize( disp_str ) or disp_str
    s = string.gsub(s, "%%s%d" , "%%s") --s = string.gsub(s, "s%d" , "s")
    s = string.format( s, details_str )

    ChatPrint( { color_resource[team], team_index[team] }, { white_c, s } )
end )

user_message_callback.bind( VoteFailed, "MsgFunc_VoteFailed", function( msg )
    local team<const> = msg:ReadByte() -- Team index or 0 for all
    local reason<const> = msg:ReadByte() -- Failure reason code (0, 3-4)

    -- Order : game_ui_localize, enum fallback
    local s = vote_failed_localize[reason]

    s = (#localize( s ) > 0) and localize( s ) or vote_failed_reason_t[reason]

    ChatPrint( { color_resource[team], team_index[team] }, { achievement_c, s } )
end )

user_message_callback.bind( CallVoteFailed, "MsgFunc_CallVoteFailed", function( msg )
    local reason<const> = msg:ReadByte() -- Failure reason (1-2, 5-10, 12-19)
    local time<const> = msg:ReadInt( 16 ) -- For failure reasons 2 and 8, time in seconds until client can start another vote. 2 is per user, 8 is per vote type.

    -- Order : game_ui_localize, enum fallback
    --[[
    local s = type( vote_call_vote_failed_localize[reason] ) == "function" and
                  vote_call_vote_failed_localize[reason]( time ) or vote_call_vote_failed_localize[reason]

    s = (#localize( s ) > 0) and localize( s ) or vote_failed_reason_t[reason]

    s = string.gsub( s, "%S+", { -- convert lua format
        ["%s1"] = "%s",
        ["%s2"] = "%s"
     } )
    s = string.format( s, time )]] --

    local s = vote_failed_reason_t[reason]
    local me = entities.GetLocalPlayer()
    ChatPrint( { color_resource[me:GetTeamNumber()], "[YOU]" }, { argb_c( "#FDFD97FF" ), time },
        { white_c, (time <= 1 and "second" or "seconds") }, "left to wait before casting another vote.",
        { achievement_c, s } )
end )
-- endregion: core function

printLuaTable( client.GetPlayerInfo( entities.GetLocalPlayer():GetIndex() ) )
