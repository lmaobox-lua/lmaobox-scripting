-- i hereby claim the throne of the best vote revealer
--[[ 
    vote revealer.lua | Test Build | Moonverse#9320 is looking for comments and suggestions
    https://github.com/LewdDeveloper/lmaobox-scripting 
]] -- 
callbacks.Unregister( 'DispatchUserMessage', 'usermessage_observer' )
callbacks.Unregister( 'FireGameEvent', "event_observer" )

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
    local rgba = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    return rgba
    -- string.format( "0x%06x", rgba )
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

local chatPrintf = function( sep, ... )
    local final = text_builder( sep, ... )
    client.ChatPrintf( final )
end

-- #endregion utils

local vote_type = {
    [0] = "Yes",
    "No"
 }

local team_name = {
    [0] = "Unassigned",
    [1] = "Spectator",
    [2] = "Red",
    [3] = "Blu"
 }

local to_team_name = (function( entityindex )
    local team_number = entityindex:GetTeamNumber()
    return team_name[team_number]
end)

local class_name = {
    [1] = 'Scout',
    [3] = 'Soldier',
    [7] = 'Pyro',
    [4] = 'Demoman',
    [6] = 'Heavy',
    [9] = 'Engineer',
    [5] = 'Medic',
    [2] = 'Sniper',
    [8] = 'Spy'
 }
local to_class_name = (function( entityindex )
    local class_number = entityindex:GetPropInt( 'm_iClass' )
    return class_name[class_number]
end)

local ReadShort = function( msg ) -- TODO : Bf will update UserMessage methods
    return msg:ReadByte() + (msg:ReadByte() << 8)
end
-- https://wiki.alliedmods.net/Tf2_voting
-- note : xref MsgFunc_[usermessage]
-- this table could be inaccurate
local vote_create_failed_t = { "VOTE_FAILED_GENERIC", "VOTE_FAILED_TRANSITIONING_PLAYERS",
                               "VOTE_FAILED_TRANSITIONING_PLAYERS", "VOTE_FAILED_RATE_EXCEEDED",
                               "VOTE_FAILED_YES_MUST_EXCEED_NO", "VOTE_FAILED_QUORUM_FAILURE",
                               "VOTE_FAILED_ISSUE_DISABLED", "VOTE_FAILED_MAP_NOT_FOUND",
                               "VOTE_FAILED_MAP_NAME_REQUIRED", "VOTE_FAILED_ON_COOLDOWN", "VOTE_FAILED_TEAM_CANT_CALL",
                               "VOTE_FAILED_WAITINGFORPLAYERS", "VOTE_FAILED_PLAYERNOTFOUND",
                               "VOTE_FAILED_CANNOT_KICK_ADMIN", "VOTE_FAILED_SCRAMBLE_IN_PROGRESS",
                               "VOTE_FAILED_SPECTATOR", "VOTE_FAILED_NEXTLEVEL_SET", "VOTE_FAILED_MAP_NOT_VALID",
                               "VOTE_FAILED_CANNOT_KICK_FOR_TIME", "VOTE_FAILED_CANNOT_KICK_DURING_ROUND",
                               "VOTE_FAILED_VOTE_IN_PROGRESS", "VOTE_FAILED_KICK_LIMIT_REACHED",
                               "VOTE_FAILED_KICK_DENIED_BY_GC" }
local vote_call_vote_failed_t = {
    [0] = "VOTE_FAILED_GENERIC",
    [1] = "VOTE_FAILED_TRANSITIONING_PLAYERS",
    [2] = "VOTE_FAILED_RATE_EXCEEDED",
    [3] = "VOTE_FAILED_YES_MUST_EXCEED_NO",
    [4] = "VOTE_FAILED_QUORUM_FAILURE",
    [5] = "VOTE_FAILED_ISSUE_DISABLED",
    [6] = "VOTE_FAILED_MAP_NOT_FOUND",
    [7] = "VOTE_FAILED_MAP_NAME_REQUIRED",
    [8] = "VOTE_FAILED_FAILED_RECENTLY",
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
    [19] = "VOTE_FAILED_MODIFICATION_ALREADY_ACTIVE"
 }
-- DO NOT MODIFY local Variables in function as it has to be IN-ORDER
-- format whatever you like, just do not modify it's order
local msg_func = {}
-- local k_MAX_VOTE_NAME_LENGTH = 256
msg_func[CallVoteFailed] = function( msg )
    local nReason = msg:ReadByte()
    local nTime = msg:ReadByte() + (msg:ReadByte() << 8) -- how much time left before it can be voted again
    --print( nReason, vote_call_vote_failed_t[nReason] )
    chatPrintf( ' ', "\x01", vote_call_vote_failed_t[nReason], ",", nTime, "seconds left" )
    -- print_console_color( rgba( 25, 0, 255, 255 ), ' | ', 'nReason ' .. nReason, 'nTime ' .. nTime )
    -- todo : invest further
    return msg:Reset()
end

msg_func[VoteStart] = function( msg )
    local m_nVoteTeamIndex = msg:ReadByte() -- Is this a team-only vote?
    local m_iVoteCallerIdx = msg:ReadByte() -- Entity calling the vote
    local display_str = msg:ReadString( 256 )
    local detail_str = msg:ReadString( 256 )
    local m_bIsYesNoVote = msg:ReadByte()
    local iTargetEntIndex = msg:ReadByte()

    --[[print_console_color( rgba( 100, 70, 255, 255 ), ' | ', initiator:GetName(), to_team_name( initiator ), display_str,
        detail_str )
    print_console_color( rgba( 25, 0, 255, 255 ), ' | ', 'm_nVoteTeamIndex ' .. m_nVoteTeamIndex,
        'm_iVoteCallerIdx ' .. m_iVoteCallerIdx, 'm_bIsYesNoVote ' .. m_bIsYesNoVote,
        'iTargetEntIndex ' .. iTargetEntIndex )]]
    local initiator = entities.GetByIndex( m_iVoteCallerIdx )

    if (#detail_str > 0) then
        detail_str = ": " .. detail_str
    end

    chatPrintf( ' ', "\x03", "[", team_name[m_nVoteTeamIndex], "]", initiator:GetName(), "\x01 casted", "\x05",
        display_str, detail_str )
    return msg:Reset()
end

msg_func[VotePass] = function( msg )
    local m_nVoteTeamIndex = msg:ReadByte()
    local passed_str = msg:ReadString( 256 )
    local detail_str = msg:ReadString( 256 )

    if (#detail_str > 0) then
        detail_str = ": " .. detail_str
    end

    chatPrintf( ' ', "\x01", "[", team_name[m_nVoteTeamIndex], "]", "\x05", passed_str, detail_str )

    -- print_console_color( rgba( 25, 0, 255, 255 ), ' | ', 'm_nVoteTeamIndex ' .. m_nVoteTeamIndex,'passed_str ' .. passed_str, 'detail_str ' .. detail_str )
    return msg:Reset()
end

msg_func[VoteFailed] = function( msg )
    local m_nVoteTeamIndex = msg:ReadByte()
    local nReason = msg:ReadByte()
    nReason = nReason + 1 -- EDGE CASE : In Lua, table starts at 1
    -- print_console_color( Color( 25, 0, 255, 255 ), ' | ', 'm_nVoteTeamIndex ' .. m_nVoteTeamIndex, 'nReason ' .. nReason )

    chatPrintf( ' ', "\x01", "[", team_name[m_nVoteTeamIndex], "]", "\x05", vote_call_vote_failed_t[nReason] )
    return msg:Reset()
end

msg_func[VoteSetup] = function( msg )
    local nIssueCount
    -- todo : invest further
    return msg:Reset()
end

local usermessage_observer = function( proton )
    local id, data_bits, data_bytes = proton:GetID(), proton:GetDataBits(), proton:GetDataBytes()
    -- print( 'usermessage captured: ' .. id )
    local s = type( msg_func[id] ) == "function" and msg_func[id]( proton )
end

local event_observer = function( event )
    --[[    byte	vote_option	which option the player voted on
            short	team	[Ed: Usually -1, but team-specific votes can be 2 for RED or 3 for BLU]
            long	entityid	entity id of the voter ]] --
    if (event:GetName() == "vote_cast") then
        local vote_option = event:GetInt( 'vote_option' )
        local team = event:GetInt( 'team' )
        local entityindex = event:GetInt( 'entityid' )
        local entity = entities.GetByIndex( entityindex )
        -- print_console_color( rgba( 25, 0, 255, 255 ), ' | ', 'vote_option ' .. vote_option, 'team ' .. team, 'entityid ' .. entityindex )

        chatPrintf( ' ', "\x03", entity:GetName(), "\x01 voted", "\x05", vote_type[vote_option] ) -- I should have string.format it all
    end

    --[[    byte	count	Number of options - up to MAX_VOTE_OPTIONS [ed: 5]
                    string	option1	
                    string	option2	
                    string	option3	
                    string	option4	
                    string	option5	]] --
    if (event:GetName() == "vote_options") then
        local count
        local option1, option2, option3, option4, option5
    end
end

local OnStartup = (function()
    -- https://wiki.teamfortress.com/wiki/Voting
    ---print_console_color( rgba( 25, 0, 255, 255 ), "hello world" )
    callbacks.Register( 'FireGameEvent', 'event_observer', event_observer )
    callbacks.Register( 'DispatchUserMessage', 'usermessage_observer', usermessage_observer )
end)()

--[[
    \x01 - White color
    \x02 - Old color
    \x03 - Player name color
    \x04 - Location color
    \x05 - Achievement color
    \x06 - Black color
    \x07 - Custom color, read from next 6 characters as HEX
    \x08 - Custom color with alpha, read from next 8 characters as HEX
]]
