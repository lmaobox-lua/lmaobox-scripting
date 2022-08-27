local localizeCache = {}

local function Localize( key, ... )
    local varargs = { ... }
    if not localizeCache[key] then
        localizeCache[key] = client.Localize( key )
        if not localizeCache[key] then
            print( string.format( 'Cannot localize key: %q', key ) )
            return key
        end
    end
    local localized_safe, i = localizeCache[key], 0 -- use in print, ChatPrintf
    local localized, j = localized_safe, 0 -- use in Notification
    localized_safe = localized_safe:gsub( '%%[acdglpsuwx%[%]]%d', function( capture )
        i = i + 1
        return varargs[i] or string.format( '%%%s', capture )
    end )
    localized = localized:gsub( '%%[acdglpsuwx%[%]]%d', function( capture )
        j = j + 1
        return varargs[j] or capture
    end )
    return localized_safe, localized 
end

callbacks.Register( 'DispatchUserMessage', function( um )
    local id, data_bytes = um:GetID(), um:GetDataBytes()

    if id == SayText2 then
        local index, is_text_chat, chat_type, player_name, chat_text
        index = um:ReadByte()
        is_text_chat = um:ReadByte() -- if set to 1, GetFilterForString gets called
        chat_type = um:ReadString( 64 ) -- used in ReadLocalizedString
        player_name = um:ReadString( 64 )
        chat_text = um:ReadString( 64 )

    end

end )

