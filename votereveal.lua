local config = {}

config.Voting = {
    annouce_vote_issue = 0,
    annouce_voter = 0,
    auto_callvote = 0,
    auto_voteoption = 0
 }

local localizeCache = {}

local function Localize( key, ... )
    local varargs, localized = { ... }, client.Localize( key )

    if localized == nil or localized:len() < 1 then
        print( string.format( 'Cannot localize key: %s', key ))
        return key
    end

    if not localizeCache[key] then
        local index = 0
        localizeCache[key] = localized:gsub( '%%[acdglpsuwx%[%]]%d', function( capture )
            index = index + 1
            ---@author: Moonverse#9320 2022-07-21 00:00:33
            -- So, in lbox there's an unexplainable behavior on `print`, `printc` and `ChatPrintf`
            -- the game crashes if i don't prefix string with "%%" 
            -- note it doesn't happen with `engine.Notification`
            -- so, if you know what that is, report it to bf and tell me about it.
            return varargs[index] or string.format( '%%%s', capture )
        end )
    end

    return localizeCache[key]
end

-- i wrote this, i don't know why would i wrote this, but here we are
--- textmsg, all, team, party, console, notification
local function Announcer( msg, maxlen )
    if maxlen then
        msg = msg:sub( 1, maxlen )
    end
    local msgFiltered = (function()
        local binary, filter, offset = { string.byte( msg, 1, msg:len() ) }, {}, 1
        repeat
            local val = binary[offset]
            if val >= 1 and val <= 6 then
                offset = offset + 1
            elseif val == 7 then
                offset = offset + 6
            elseif val == 8 then
                offset = offset + 8
            else
                filter[#filter+1] = string.char(val)
                offset = offset + 1
            end
        until (offset == #binary)
        return table.concat(filter)
    end)()
    local announce = { '\x01' .. msg, msgFiltered, msgFiltered:gsub( '"', "'" ) }
    function announce:ChatPrintf()
        client.ChatPrintf( self[1] )
        return self
    end
    function announce:all()
        client.ChatSay( self[2] )
        return self
    end
    function announce:team()
        client.ChatTeamSay( self[2] )
        return self
    end
    function announce:party()
        client.Command( string.format( 'tf_party_chat %q', self[3] ), true )
        return self
    end
    function announce:console( red, green, blue, alpha )
        printc( red or 255, green or 255, blue or 255, alpha or 255, self[2] )
        return self
    end
    return announce
end

callbacks.Register( 'DispatchUserMessage', function( msg )
    local id, sizeOfData, offset
    id = msg:GetID()
    sizeOfData = msg:GetDataBytes()

    if id == VoteStart then
        local team, voteidx, entidx, disp_str, details_str, target
        team = msg:ReadByte()
        voteidx = msg:ReadInt( 32 )
        entidx = msg:ReadByte()
        disp_str = msg:ReadString( 64 )
        details_str = msg:ReadString( 64 )
        target = msg:ReadByte() >> 1

        local ent
        ent = entities.GetByIndex( entidx )

        local plain_str = Localize( disp_str, '\x02' .. details_str )

        if config.Voting.annouce_vote_issue then
            
        end

        return
    end

end )
