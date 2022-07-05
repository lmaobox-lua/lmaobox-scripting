_G.announce_party_chat = true

local vote_failed_e = {
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

local vote_failed_t = {
    [0] = '#GameUI_vote_failed',
    [3] = '#GameUI_vote_failed_yesno',
    [4] = '#GameUI_vote_failed_quorum'
 }

local call_vote_failed_t = {
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

-- what if we do full string color, unless :flushed:
local team_name = {
    [0] = '~',
    client.Localize( 'TF_Spectators' ) or 'Spectators',
    client.Localize( 'TF_RedTeam_Name' ) or 'Red',
    client.Localize( 'TF_BlueTeam_Name' ) or 'Blu'
 }
local function GetTeamName( teamidx ) return team_name[teamidx] end

local team_color = {
    [0] = '#F6D7A7ff',
    '#cfcfc4ff',
    '#ff6663ff',
    '#9EC1CFff'
 }
local function GetTeamColor( teamidx )
    local objColor = {}
    objColor.hex = team_color[teamidx]
    function objColor:colorCode()
        local hex = team_color[teamidx]:gsub( '#', '' )
        local markup = #hex < 8 and '\x07' .. hex or '\x08' .. hex
        return markup
    end
    function objColor:rgbArray()
        local i = tonumber( '0x' .. team_color[teamidx]:gsub( '#', '' ) )
        local rgba = { i >> 24, i >> 16 & 0xFF, i >> 8 & 0xFF, i & 0xFF }
        if rgba[1] == 0 then
            table.remove( rgba, 1 )
            rgba[#rgba + 1] = 255
        else
            rgba[1] = rgba[1] & 0xFF
        end
        return rgba
    end
    function objColor:printc( message )
        local r, g, b, a = table.unpack( objColor:rgbArray() )
        return printc( r, g, b, a, message )
    end
    return objColor, objColor.hex
end

local function removeColorCode( message )
    local tbl = { message:byte( 1, #message ) }
    for i, val in ipairs( tbl ) do
        if val > 0 and val <= 8 then
            table.remove( tbl, i )
        end
        if val == 7 or val == 8 then
            for i1 = 1, val, 1 do
                table.remove( tbl, i )
            end
        end
    end
    return string.char( table.unpack( tbl ) )
end

local function interp( message, tbl )
    local s = message:gsub( '(%b{})', function( w ) return tbl[w:sub( 2, -2 )] or w end )
    return s
end
-- getmetatable( '' ).__mod = interp

-- What if i start doing overengineer.

local function PartySay( message )
    if announce_party_chat then
        client.Command( string.format( 'tf_party_chat %q', message:gsub('"', "'") ), true )
    end
end

local votesArr = {}
local meVotedOption -- todo EXP
local buflogger = {}

local function vote_start( msg )
    if msg:GetID() == VoteStart then
        local team, voteidx, entidx, disp_str, details_str, target
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        entidx = msg:ReadByte()
        disp_str = msg:ReadString( 64 )
        details_str = msg:ReadString( 64 )
        target = msg:ReadByte() >> 1

        local ent = entities.GetByIndex( entidx )
        if #details_str > 0 then
            details_str = GetTeamColor( ent:GetTeamNumber() ):colorCode() .. details_str .. '\x01'
        end

        local loc, fmt, tfchat, tfparty, tfconsole
        loc = client.Localize( disp_str )
        loc = (loc ~= nil and #loc > 0) and utf8.char( loc:byte( 1, #loc ) ) or disp_str
        tfconsole = loc:gsub( '%%s%d+', function( capture )
            if capture == '%s1' then
                return details_str
            end
            return '%' .. capture
        end ):gsub( '\n', ' ' )
        fmt = string.format( '%d • [{TEAM}%s\x01] {ENT}%s\x01\n* \x05%s', voteidx, GetTeamName( team ),
                             client.GetPlayerNameByIndex( entidx ) or 'NULLNAME', tfconsole )
        tfchat = '\x01' .. interp( fmt, {
            ENT = GetTeamColor( ent:GetTeamNumber() ):colorCode(),
            TEAM = GetTeamColor( team ):colorCode()
         } )

        client.ChatPrintf( tfchat )
        tfconsole = removeColorCode( tfconsole )
        -- GetTeamColor( ent:GetTeamNumber() ):printc( tfconsole )
        PartySay( string.format( 'Vote started by %s - %s', client.GetPlayerNameByIndex( entidx ), client.GetPlayerInfo( entidx ).SteamID ) )
        PartySay( tfconsole .. ' ' .. client.GetPlayerInfo( target ).SteamID or '' )
        buflogger[#buflogger + 1] = tfconsole

        for idx, arr in pairs( votesArr ) do
            if idx ~= voteidx then
                votesArr[idx] = undef
            end
        end

    end
end

local function vote_pass( msg )
    if msg:GetID() == VotePass then
        local team, voteidx, disp_str, details_str
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        disp_str = msg:ReadString( 256 )
        details_str = msg:ReadString( 256 )

        local loc, fmt, tfchat, tfparty, tfconsole
        loc = client.Localize( disp_str )
        loc = (loc ~= nil and #loc > 0) and utf8.char( loc:byte( 1, #loc ) ) or disp_str
        tfconsole = loc:gsub( '%%s%d+', function( capture )
            if capture == '%s1' then
                return details_str
            end
            return '%' .. capture
        end ):gsub( '\n', ' ' )
        fmt = string.format( '%d • [{TEAM}%s\x01] \x05%s\x01 %s', voteidx, GetTeamName( team ), tfconsole, votesArr[voteidx] or '' )
        tfchat = '\x01' .. interp( fmt, {
            TEAM = GetTeamColor( team ):colorCode()
         } )

        client.ChatPrintf( tfchat )
        tfconsole = removeColorCode( tfconsole )
        PartySay( tfconsole )

    end
end

local function vote_failed( msg )
    if msg:GetID() == VoteFailed then
        local team, voteidx, reason
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        reason = msg:ReadByte()

        local disp_str = vote_failed_t[reason]

        local loc, fmt, tfchat, tfparty, tfconsole
        loc = client.Localize( disp_str )
        loc = (loc ~= nil and #loc > 0) and utf8.char( loc:byte( 1, #loc ) ) or disp_str
        tfconsole = loc:gsub( '%%s%d+', function( capture )
            if capture == '%s1' then
                return details_str
            end
            return '%' .. capture
        end ):gsub( '\n', ' ' )
        fmt = string.format( '%d • [{TEAM}%s\x01] \x05%s\x01 %s', voteidx, GetTeamName( team ), tfconsole, votesArr[voteidx] or '' )

        tfchat = '\x01' .. interp( fmt, {
            TEAM = GetTeamColor( team ):colorCode()
         } )

        PartySay( tfconsole )
        client.ChatPrintf( tfchat )
        tfconsole = removeColorCode( tfconsole )
    end
end

-- todo
local function call_vote_failed( msg )
    if msg:GetID() == CallVoteFailed then
        local reason, time
        reason = msg:ReadByte()
        time = msg:ReadInt( 16 )

        local disp_str = vote_failed_e[reason]
        local message = '[\x03' .. client.Localize( '#GameUI_vote_failed' ) .. '\x01] ' .. disp_str .. '\n' .. time ..
                            ' seconds left to wait before casting another vote'
        local highlighted = '\x01' .. message:gsub( disp_str, function( s ) return '\x05' .. s .. '\x01' end )

        client.ChatPrintf( highlighted )
        printc( 157, 194, 80, 255, message )
    end
end

local options = { 'Yes', 'No' }

local function on_vote( event )

    if event:GetName() == 'vote_options' then
        for i = 1, event:GetInt( 'count' ) do
            options[i] = event:GetString( 'option' .. i )
        end
    end

    if event:GetName() == 'vote_changed' then
        local vote_option1, vote_option2, vote_option3, vote_option4, vote_option5, potentialVotes, voteidx
        local vote = {}
        local buf = {}
        for i = 1, 5 do
            vote[i] = event:GetInt( 'vote_option' .. i )
            if vote[i] > 0 then
                buf[i] = vote[i]
            end
        end
        potentialVotes = event:GetInt( 'potentialVotes' )
        voteidx = event:GetInt( 'voteidx' )
        votesArr[voteidx] = string.format( '\x01[%s\x01]', table.concat( buf, '/' ) )
        -- print( votesArr[voteidx] )
    end

    if event:GetName() == 'vote_cast' then
        local vote_option, team, entidx, voteidx
        vote_option = event:GetInt( 'vote_option' ) + 1 -- ??? volvo why.
        team = event:GetInt( 'team' )
        entidx = event:GetInt( 'entityid' )
        voteidx = event:GetInt( 'voteidx' )

        local ent = entities.GetByIndex( entidx )
        if client.GetLocalPlayerIndex() == entidx then
            meVotedOption = voteidx << vote_option
        end

        local fmt, tfchat, tfparty, tfconsole
        fmt =
            string.format( '%d {DOT}•\x01 |\x05%s\x01 {ENT}%s\x01', voteidx, options[vote_option], client.GetPlayerNameByIndex( entidx ) )

        tfchat = '\x01' .. interp( fmt, {
            ENT = GetTeamColor( ent:GetTeamNumber() ):colorCode(),
            DOT = (function()
                if not meVotedOption or team ~= 0 and team ~= entities.GetLocalPlayer():GetTeamNumber() and (meVotedOption >> vote_option) ~= voteidx then
                    return '\x01'
                end
                return meVotedOption & ~(voteidx << vote_option) == 0 and '\x089EE09EFF' or '\x08FF6663FF'
            end)()
         } )

        client.ChatPrintf( tfchat )
        PartySay( tfconsole )

    end
end

-- region:
-- LuaFormatter off 
local lua_callbacks = { 
    { 'FireGameEvent',  on_vote},
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
