local table_gen = require( 'table_gen' )
local json = require( 'json' )
local msgpack = require( 'msgpack' )
-- client.Command( 'exec vote', true )
local config = {}

config.Voting = {
    annouce_vote_issue = 0,
    annouce_voter = 0,
    auto_callvote = 0,
    auto_voteoption = 0,
    vote_end = 0
 }

local localizeCache = {}

local function Localize( key, ... )
    local varargs, localized = { ... }, client.Localize( key )

    if localized == nil or localized:len() < 1 then
        print( string.format( 'Cannot localize key: %q', key ) )
        return key
    end

    if not localizeCache[key] then
        local index = 0
        localizeCache[key] = localized:gsub( '%%[acdglpsuwx%[%]]%d', function( capture )
            index = index + 1
            ---@author: Moonverse#9320 2022-07-21 00:00:33
            -- So, in lbox there's an unexplainable behavior on `print`, `printc` and `ChatPrintf`
            -- the game crashes if i don't pcix string with "%%" 
            -- note it doesn't happen with `engine.Notification`
            -- so, if you know what that is, report it to bf and tell me about it.
            return varargs[index] or string.format( '%%%s', capture )
        end )
    end

    return localizeCache[key]
end

local function Announce( text, bit )
end

local vote_failed_t = {
    [0] = '#GameUI_vote_failed',
    [3] = '#GameUI_vote_failed_yesno',
    [4] = '#GameUI_vote_failed_quorum'
 }

local UNASSIGNED, SPECTATOR, TEAM_RED, TEAM_BLU = 0, 1, 2, 3
local team_color = {
    [UNASSIGNED] = 0xF6D7A7ff,
    [SPECTATOR] = 0xcfcfc4ff,
    [TEAM_RED] = 0xff6663ff,
    [TEAM_BLU] = 0x9EC1CFff
 }
local team_name = {
    [0] = 'UNASSIGNED',
    'SPECTATOR',
    'RED',
    'BLU'
 }

local options_str, options_voteidx_str, count, voted, info = {}, {}, {}, {}, {}

local finalize_vote = function( voteidx, team, text )
    printc( 0, 255, 0, 255,
        string.format( 'Vote Ended ( index: %d, server: %s, begin at: %s, map: %s )', voteidx, info[voteidx][1],
            info[voteidx][2], info[voteidx][3] ) )

    if text then
        local rgba = team_color[team]
        printc( rgba >> 24 & 0xFF, rgba >> 16 & 0xFF, rgba >> 8 & 0xFF, rgba & 0xFF,
            string.format( '[%s] %s', team_name[team], text ) )
    end

    if voted[voteidx] then
        local result, rows = {}, {}

        for t, arr in pairs( voted[voteidx] ) do
            for i, v in ipairs( arr ) do
                rows[#rows + 1] = v
            end
        end

        local sheet = table_gen( rows, { "Team", "Name", "SteamID", "Option" }, {
            style = "Markdown (Github)"
         } )
        print( sheet )

        for i, option in ipairs( count[voteidx] ) do
            if option > 0 and i <= 5 then
                result[#result + 1] = (options_voteidx_str[voteidx][i] or 'option' .. i) .. ": " .. option
            end
        end

        print( "- " .. table.concat( result, ', ' ) )
        options_voteidx_str[voteidx], count[voteidx], voted[voteidx], info[voteidx] = nil, nil, nil, nil
    end
end

callbacks.Register( 'FireGameEvent', function( event )
    local eventname = event:GetName()

    if eventname == 'vote_options' then -- server doesn't return voteidx
        for i = 1, event:GetInt( 'count' ) do
            options_str[i] = event:GetString( 'option' .. i )
        end
        return
    end

    if eventname == 'vote_changed' then
        local option, voteidx
        voteidx = event:GetInt( 'voteidx' )
        for j = 1, 5 do
            count[voteidx][j] = event:GetInt( 'vote_option' .. j )
        end
        count[voteidx][#count + 1] = event:GetInt( 'potentialVotes' )
        return
    end

    if eventname == 'vote_cast' then
        local option, team, entidx, voteidx
        option = event:GetInt( 'vote_option' ) + 1
        team = event:GetInt( 'team' )
        entidx = event:GetInt( 'entityid' )
        voteidx = event:GetInt( 'voteidx' )

        local playerinfo, teamname = client.GetPlayerInfo( entidx ), team_name[team] or team
        if not voted[voteidx] then
            options_voteidx_str[voteidx], count[voteidx], voted[voteidx] = options_str, {}, {}
            info[voteidx] = { engine.GetServerIP(), os.date( '%Y-%m-%d %H:%M:%S' ),
                              engine.GetMapName():gsub( '.bsp$', '.nav' ) }
        end
        voted[voteidx][team] = voted[voteidx][team] or {}
        table.insert( voted[voteidx][team],
            { teamname, playerinfo.Name, playerinfo.SteamID, options_voteidx_str[voteidx][option] or option } )
        return
    end

    if eventname == 'client_disconnect' then
        for i in pairs( voted ) do
            finalize_vote( i )
        end
    end

end )

callbacks.Register( 'DispatchUserMessage', function( msg )
    local id, sizeOfData, offset
    id = msg:GetID()
    sizeOfData = msg:GetDataBytes()

    if id == CallVoteFailed then
        local reason, time
        reason = msg:ReadByte()
        time = msg:ReadInt( 16 )
        
        return
    end

    if id == VoteStart then
        local team, voteidx, entidx, disp_str, details_str, target
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        entidx = msg:ReadByte()
        disp_str = msg:ReadString( 64 )
        details_str = msg:ReadString( 64 )
        target = msg:ReadByte() >> 1

        local playerinfo, teamname = client.GetPlayerInfo( entidx ), team_name[team] or team
        local rgba = team_color[team]
        local text = Localize( disp_str, '\x05' .. details_str .. '\x01' )
        printc( 0, 255, 0, 255, string.format( 'Vote Started ( index: %d, from: %s | %s )', voteidx, playerinfo.Name,
            playerinfo.SteamID ) )
        printc( rgba & 0xFF, rgba >> 24 & 0xFF, rgba >> 16 & 0xFF, rgba >> 8 & 0xFF, string.format( '[%s] %s', teamname,
            text:gsub( "\7......", "" ):gsub( "\8........", "" ):gsub( '%c', ' ' ) ) )
        Announce( string.format( '\8%d %s', team_color[team], text ), config.Voting.annouce_vote_issue )
        if config.announce_voter then

        end
        return
    end

    if id == VotePass then
        local team, voteidx, disp_str, details_str
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        disp_str = msg:ReadString( 256 )
        details_str = msg:ReadString( 256 )

        local text = Localize( disp_str, details_str )
        Announce( string.format( '\8%d %s', team_color[team], text ), config.Voting.vote_end )
        return finalize_vote( voteidx, team, text )
    end

    if id == VoteFailed then
        local team, voteidx, reason
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        reason = msg:ReadByte()

        local text = Localize( vote_failed_t[reason] )
        Announce( string.format( '\8%d %s', team_color[team], text ), config.Voting.vote_end )
        return finalize_vote( voteidx, team, text )
    end

end )

--print( msgpack.decode( msgpack.encode( "abc", config ) ) )
--print( json.decode( json.encode( "a", config ) ) )

--[[
    https://github.com/sapphyrus/table_gen.lua
-- require the file
local table_gen = require "table_gen"

local headings = {"Country", "Capital", "Population", "Language"}
local rows = {
	{"USA", "Washington, D.C.", "237 million", "English"},
	{"Sweden", "Stockholm", "10 million",	"Swedish"},
	{"Germany", "Berlin", "82 million", "German"}
}

-- generate the table. Last argument are the options, or if a string, the style option
local table_out = table_gen(rows, headings, {
	style = "Markdown (Github)"
})

-- Print it to console
print(table_out)

-- output:
-- | Country |     Capital      | Population  | Language |
-- |---------|------------------|-------------|----------|
-- | USA     | Washington, D.C. | 237 million | English  |
-- | Sweden  | Stockholm        | 10 million  | Swedish  |
-- | Germany | Berlin           | 82 million  | German   |

"Vote_RestartGame"		"Restart Game"
"Vote_Kick"				"Kick"
"Vote_ChangeLevel"		"Change Map"
"Vote_NextLevel"			"Next Map"
"Vote_ExtendLevel"			"Extend Current Map"
"Vote_ScrambleTeams"		"Scramble Teams"
"Vote_ChangeMission"		"Change Mission"
"Vote_Eternaween"			"Eternaween"
"Vote_TeamAutoBalance_Enable"		"Enable Team AutoBalance"
"Vote_TeamAutoBalance_Disable"	"Disable Team AutoBalance"
"Vote_ClassLimit_Enable"			"Enable Class Limits"
"Vote_ClassLimit_Disable"			"Disable Class Limits"
"Vote_PauseGame"			"Pause Game"

]]
