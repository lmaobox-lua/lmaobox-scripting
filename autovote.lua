-- type in console : ``lua vote = 1`` means auto vote yes, ``lua vote = 2`` means auto vote no
local t = {
    ['option yes'] = 1,
    ['option no'] = 2,
    ['off'] = nil
 }

_G.vote = t[gui.GetValue( 'Auto Voting' )] -- ONCE

if not _G.vote then
    printc( 255, 0, 0, 255, 'autovote.lua _G.vote is nil, consider reading src or enable Auto Voting and reload script' )
end

local g_voteidx = nil

local options = { 'Yes', 'No' }

callbacks.Register( 'FireGameEvent', 'lboxfixwhen_1', function( event )
    if event:GetName() == 'vote_options' then
        for i = 1, event:GetInt( 'count' ) do
            options[i] = event:GetString( 'option' .. i )
        end
    end

    if event:GetName() == 'vote_cast' then
        local vote_option, team, entityid, voteidx
        vote_option = event:GetInt( 'vote_option' ) + 1 -- ??? consistency
        team = event:GetInt( 'team' )
        entityid = event:GetInt( 'entityid' )
        voteidx = event:GetInt( 'voteidx' )
        g_voteidx = voteidx
    end
end )

callbacks.Register( 'SendStringCmd', 'lboxfixwhen_2', function( cmd )
    local input = cmd:Get()
    if input:find( 'vote option' ) then
        cmd:Set( input:gsub( 'vote', '%1 ' .. g_voteidx ) )
    end
end )

callbacks.Register( 'DispatchUserMessage', 'lboxfixwhen_3', function( msg )
    if msg:GetID() == VoteStart then
        local team, voteidx, entidx, disp_str, details_str, target
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        entidx = msg:ReadByte()
        disp_str = msg:ReadString( 64 )
        details_str = msg:ReadString( 64 )
        target = msg:ReadByte() >> 1

        local ent0, ent1 = entities.GetByIndex( entidx ), entities.GetByIndex( target )
        local me = entities.GetLocalPlayer()
        local voteint = _G.vote

        if ent0 ~= me and ent1 ~= me and type( voteint ) == 'number' then

            -- vote no if target is friend
            voteint = (function()
                local playerinfo = client.GetPlayerInfo( target )
                if steam.IsFriend( playerinfo.SteamID ) == true then
                    return 2
                end

                local members = party.GetMembers()
                for i, steamid in ipairs( members ) do
                    if steamid == playerinfo.SteamID then
                        return 2
                    end
                end

                return voteint
            end)()

            client.ChatPrintf( string.format( '\x01Voted %s "vote option%d" (\x05%s\x01)', options[voteint], voteint,
                disp_str ) )
            client.Command( string.format( 'vote %d option%d', voteidx, voteint ), true )
        end
    end
end )

