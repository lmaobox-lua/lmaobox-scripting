Print = 1 << 1
ChatPrintf = 1 << 2
ChatSay = 1 << 3
ChatTeamSay = 1 << 4
ChatParty = 1 << 5

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
local function Announcer( msg )
    local announce = { '\x01' .. msg, msg:gsub("[\x01-\x06].", ""):gsub("\x07......", ""):gsub("\x08........", "") }
    announce[3] = announce[2]:gsub( '"', "'" )
    function announce:ChatPrintf()
        client.ChatPrintf( self[1] )
        return self
    end
    function announce:ChatSay()
        client.ChatSay( self[2] )
        return self
    end
    function announce:ChatTeamSay()
        client.ChatTeamSay( self[2] )
        return self
    end
    function announce:ChatParty()
        client.Command( string.format( 'tf_party_chat %q', self[3] ), true )
        return self
    end
    function announce:Print( red, green, blue, alpha )
        printc( red or 255, green or 255, blue or 255, alpha or 255, self[2] )
        return self
    end
    function announce:band( x1 )
        if x1 & ChatPrintf == 1 then self:ChatPrintf() end
        if x1 & ChatSay == 1 then self:ChatSay() end
        if x1 & ChatTeamSay == 1 then self:ChatTeamSay() end
        if x1 & Print == 1 then self:Print() end
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

        local plain_str = Localize( disp_str, '\x05' .. details_str )
        Announcer(plain_str):ChatPrintf()
        return
    end

end )
