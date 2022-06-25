local vote_failed_reason_t = {
    [0] = 'VOTE_FAILED_GENERIC',
    [1] = 'VOTE_FAILED_TRANSITIONING_PLAYERS',
    [2] = 'VOTE_FAILED_RATE_EXCEEDED',
    [3] = 'VOTE_FAILED_YES_MUST_EXCEED_NO',
    [4] = 'VOTE_FAILED_QUORUM_FAILURE',
    [5] = 'VOTE_FAILED_ISSUE_DISABLED',
    [6] = 'VOTE_FAILED_MAP_NOT_FOUND',
    [7] = 'VOTE_FAILED_MAP_NAME_REQUIRED',
    [8] = 'VOTE_FAILED_ON_COOLDOWN',
    [9] = 'VOTE_FAILED_TEAM_CANT_CALL',
    [10] = 'VOTE_FAILED_WAITINGFORPLAYERS',
    [11] = 'VOTE_FAILED_PLAYERNOTFOUND',
    [12] = 'VOTE_FAILED_CANNOT_KICK_ADMIN',
    [13] = 'VOTE_FAILED_SCRAMBLE_IN_PROGRESS',
    [14] = 'VOTE_FAILED_SPECTATOR',
    [15] = 'VOTE_FAILED_NEXTLEVEL_SET',
    [16] = 'VOTE_FAILED_MAP_NOT_VALID',
    [17] = 'VOTE_FAILED_CANNOT_KICK_FOR_TIME',
    [18] = 'VOTE_FAILED_CANNOT_KICK_DURING_ROUND',
    [19] = 'VOTE_FAILED_VOTE_IN_PROGRESS',
    [20] = 'VOTE_FAILED_KICK_LIMIT_REACHED',
    [21] = 'VOTE_FAILED_KICK_DENIED_BY_GC'
 }

local vote_failed_localize = {
    [0] = '#GameUI_vote_failed',
    [3] = '#GameUI_vote_failed_yesno',
    [4] = '#GameUI_vote_failed_quorum'
 }

local vote_call_vote_failed_localize = {
    [1] = '#GameUI_vote_failed_transition_vote',
    [2] = function( time )
        local response = (time > 60) and '#GameUI_vote_failed_vote_spam_min' or '#GameUI_vote_failed_vote_spam_mins'
        return response
    end,
    [5] = '#GameUI_vote_failed_disabled_issue',
    [6] = '#GameUI_vote_failed_map_not_found',
    [7] = '#GameUI_vote_failed_map_name_required',
    [8] = function( time )
        local response = (time > 60) and 'GameUI_vote_failed_recently_min' or 'GameUI_vote_failed_recently_mins'
        return response
    end,
    [9] = '#GameUI_vote_failed_team_cant_call',
    [10] = '#GameUI_vote_failed_waitingforplayers',
    [11] = 'VOTE_FAILED_PLAYERNOTFOUND', -- doesn't appear to work
    [12] = '#GameUI_vote_failed_cannot_kick_admin',
    [13] = '#GameUI_vote_failed_scramble_in_prog',
    [14] = '#GameUI_vote_failed_spectator',
    [15] = '#GameUI_vote_failed_nextlevel_set',
    [16] = '#GameUI_vote_failed_map_not_valid',
    [17] = function( time ) -- VOTE_FAILED_ON_COOLDOWN
        local response = (time > 60) and '#GameUI_vote_failed_cannot_kick_min' or '#GameUI_vote_failed_cannot_kick_mins'
        return response
    end,
    [18] = 'GameUI_vote_failed_round_active',
    [19] = '#GameUI_vote_failed_event_already_active'
 }

local make_clean_string = function( original )
    -- filter control characters
    original = string.gsub( original, '%c', '' )
    -- escape magic characters
    original = string.gsub( original, '%%', '%%%%' )
    return original -- modified
end

local teamName, teamColor = {}, {}
teamName[0] = '~'
teamName[1] = client.Localize( 'TF_Spectators' )
teamName[2] = client.Localize( 'TF_RedTeam_Name' )
teamName[3] = client.Localize( 'TF_BlueTeam_Name' )
teamColor[0] = 'F6D7A7ff'
teamColor[1] = 'cfcfc4ff'
teamColor[2] = 'ff6663ff'
teamColor[3] = '9EC1CFff'
local tempTeamColor = {}
tempTeamColor[0] = 'rgba(246, 215, 167, 255)'
tempTeamColor[1] = 'rgba(250, 250, 240, 255)'
tempTeamColor[2] = 'rgba(255, 102, 99, 255)'
tempTeamColor[3] = 'rgba(158, 193, 207, 255)'

local g_voteidx = nil

local function vote_start( msg )
    if msg:GetID() == VoteStart then
        local team, voteidx, ent_idx, disp_str, details_str, target
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        ent_idx = msg:ReadByte()
        disp_str = msg:ReadString( 64 )
        details_str = msg:ReadString( 64 )
        target = msg:ReadByte() >> 1

        local ent = entities.GetByIndex( ent_idx )
        local playername = ent:GetName() or 'NULLNAME'

        local message = client.Localize( disp_str ):gsub( '%%s1', details_str )
        message = string.format( '[%s] %s: %s', teamName[team], playername, message )

        details_str = #details_str > 1 and details_str or 'no-value'

        local highlighted = '\x01' .. message:gsub( details_str, function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end ):gsub( teamName[team], function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end ):gsub( playername, function( s )
            local color = '\x08' .. teamColor[ent:GetTeamNumber()]
            return color .. s .. '\x01'
        end )

 
        client.ChatPrintf( highlighted )

        tempTeamColor[team]:gsub( '%((.-)%)', function( s )
            local t = {}
            s:gsub( '(%d+)', function( m )
                t[#t + 1] = m
                if #t == 4 then
                    printc( t[1], t[2], t[3], t[4], message )
                end
            end )
        end )
    end
end

local function vote_pass( msg )
    if msg:GetID() == VotePass then
        local team, voteidx, disp_str, details_str
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        disp_str = msg:ReadString( 256 )
        details_str = msg:ReadString( 256 )

        local message = client.Localize( disp_str ):gsub( '%%s1', details_str )
        message = string.format( '[%s] %s', teamName[team], message )
        local highlighted = '\x01' .. message:gsub( details_str, function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end ):gsub( teamName[team], function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end )

        client.ChatPrintf( highlighted )

        tempTeamColor[team]:gsub( '%((.-)%)', function( s )
            local t = {}
            s:gsub( '(%d+)', function( m )
                t[#t + 1] = m
                if #t == 4 then
                    printc( t[1], t[2], t[3], t[4], message )
                end
            end )
        end )
    end
end

local function vote_failed( msg )
    if msg:GetID() == VoteFailed then
        local team, voteidx, reason
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        reason = msg:ReadByte()

        local disp_str = vote_failed_localize[reason]

        local message = client.Localize( disp_str )
        message = string.format( '[%s] %s', teamName[team], message )
        local highlighted = '\x01' .. message:gsub( teamName[team], function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end )

        client.ChatPrintf( highlighted )

        tempTeamColor[team]:gsub( '%((.-)%)', function( s )
            local t = {}
            s:gsub( '(%d+)', function( m )
                t[#t + 1] = m
                if #t == 4 then
                    printc( t[1], t[2], t[3], t[4], message )
                end
            end )
        end )
    end
end

local function call_vote_failed( msg )
    if msg:GetID() == CallVoteFailed then
        local reason, time
        reason = msg:ReadByte()
        time = msg:ReadInt( 16 )

        local disp_str = vote_failed_reason_t[reason]
        local message = '[\x03' .. client.Localize( '#GameUI_vote_failed' ) .. '\x01]' .. disp_str .. '\n' .. time ..
                            ' seconds left to wait before casting another vote'
        local highlighted = '\x01' .. message:gsub( disp_str, function( s ) return '\x05' .. s .. '\x01' end )

        client.ChatPrintf( highlighted )
        printc( 157, 194, 80, 255, message )
    end
end

local options = { 'Yes', 'No' }

local CAT_IDENTIFY = 0xCA7
local CAT_REPLY = 0xCA8

local function on_vote( event )

    if event:GetName() == 'achievement_earned' then
        local ent_idx, achievement
        ent_idx = event:GetInt( 'player' )
        achievement = event:GetInt( 'achievement' )
        local ent = entities.GetByIndex( ent_idx )
        client.ChatPrintf( string.format( '%s got an achievement.', ent:GetName() ) )
        if achievement == CAT_IDENTIFY or achievement == CAT_REPLY then

            client.ChatPrintf( string.format( '\x01[ALERT] \x05%s sent a CAT ID.', ent:GetName() ) )
        end
    end

    if event:GetName() == 'vote_options' then
        for i = 1, event:GetInt( 'count' ) do
            options[i] = event:GetString( 'option' .. i )
        end
    end

    if event:GetName() == 'vote_cast' then
        local vote_option, team, ent_idx, vote_idx
        vote_option = event:GetInt( 'vote_option' ) + 1 -- ??? consistency
        team = event:GetInt( 'team' )
        ent_idx = event:GetInt( 'entityid' )
        vote_idx = event:GetInt( 'voteidx' )

        g_voteidx = vote_idx

        local ent = entities.GetByIndex( ent_idx )
        local playername = ent ~= nil and ent.GetName( ent )  or 'NULLNAME'

        local message = '[' .. options[vote_option] .. ']' .. ' ' .. playername
        local highlighted = '\x01' .. message:gsub( playername, function( s )
            local color = '\x08' .. teamColor[team]
            return color .. s .. '\x01'
        end ):gsub( options[vote_option], function( s )
            local color = '\x05' -- todo TOO LAZY
            return color .. s .. '\x01'
        end )

        client.ChatPrintf( highlighted )

        tempTeamColor[team]:gsub( '%((.-)%)', function( s )
            local t = {}
            s:gsub( '(%d+)', function( m )
                t[#t + 1] = m
                if #t == 4 then
                    printc( t[1], t[2], t[3], t[4], message )
                end
            end )
        end )

    end
end

local function on_send_string_cmd( cmd )
    local input = cmd:Get()
    if input:find( 'vote option' ) then
        cmd:Set( '' )
        client.Command( input:gsub( 'vote', '%1 ' .. g_voteidx ), true )
    end
end

-- region:
-- LuaFormatter off 
local lua_callbacks = { 
    { 'FireGameEvent',  on_vote},
    { 'SendStringCmd',  on_send_string_cmd},
    { 'DispatchUserMessage', vote_start }, 
    { 'DispatchUserMessage', vote_pass }, 
    { 'DispatchUserMessage', vote_failed },
    { 'DispatchUserMessage', call_vote_failed }, 
}
function lua_callbacks:Register()
    for i, o in ipairs( lua_callbacks ) do   callbacks.Register( o[1], GetScriptName() .. "_callback_" .. i, o[2] ) end
end
function lua_callbacks:Unregister() 
    for i, o in ipairs( lua_callbacks ) do callbacks.Unregister( o[1], GetScriptName() .. "_callback_" .. i, o[2] ) end 
end

callbacks.Register( 'Unload', function()
    lua_callbacks:Unregister()
end )
lua_callbacks:Register()
-- LuaFormatter on
-- endregion:
