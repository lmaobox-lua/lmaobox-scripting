UnloadScript( GetScriptName() )
local loaded, msghelper = pcall( require, 'lbox/usermessage_template' )
msghelper.self_unload_module()

local white_c<const>, old_c<const>, team_c<const>, location_c<const>, achievement_c<const>, black_c<const> = '\x01', '\x02', '\x03', '\x04',
                                                                                                             '\x05', '\x06'
local rgb_c = function( hexcodes ) return '\x07' .. hexcodes:gsub( '#', '' ) end
local argb_c = function( hexcodes_a ) return '\x08' .. hexcodes_a:gsub( '#', '' ) end
local to_rgba = function( hexcodes_a )
    local i32 = type( hexcodes_a ) == 'string' and tonumber( '0x' .. hexcodes_a:gsub( '#', '' ) ) or hexcodes_a
    return { i32 >> 24 & 0xFF, i32 >> 16 & 0xFF, i32 >> 8 & 0xFF, i32 & 0xFF }
end
local color_matrix = { '#C11B17FF', '#F87A17FF', '#FFFF00FF', '#00FF00FF', '#2B60DEFF', '#893BFFFF', '#F63817FF', '#E78E17FF', '#FFFC17FF',
                       '#5EFB6EFF', '#1531ECFF', '#8E35EFFF' }
local i = 1

local c_chat_type = {
    -- coach?
    ['TF_Chat_Team_Loc'] = nil,
    ['TF_Chat_Team'] = nil,
    ['TF_Chat_Team_Dead'] = nil,
    ['TF_Chat_Spec'] = nil,
    ['TF_Chat_All'] = nil,
    ['TF_Chat_AllDead'] = nil,
    ['TF_Chat_AllSpec'] = nil,
    ['TF_Chat_Coach'] = nil,
    ['TF_Name_Change'] = nil, -- #TF_Name_Change
    ['TF_Class_Change'] = nil, -- game event, only print in chat during competitive
    ['TF_Chat_Party'] = undef, -- game event
    default = function() return false end,
 }

local make_clean_string = function( any )
    -- filter control characters
    any = string.gsub( any, '%c', '' )
    -- escape magic characters
    any = string.gsub( any, '%%', '%%%%' )
    return any
end

local colorize_string = function( original, to_colorize, prefix, suffix )
    prefix = prefix or '\x03'
    suffix = suffix or '\x01'
    local m, original = {}, original:gsub( '\x02', '' )
    local i, j = original:find( to_colorize, 1, true )
    j = j + 1
    for index = 1, #original do
        if index == i then m[#m + 1] = prefix end
        if index == j then m[#m + 1] = suffix end
        m[#m + 1] = original:sub( index, index )
    end
    return table.concat( m )
end
-- CHAT_FILTER_NAMECHANGE
callbacks.Register( 'DispatchUserMessage', function( usermessage )
    if usermessage:GetID() == SayText2 then
        local elem = {
            [0] = 0,
         } -- first variable is 0, and last variable is n - 1, writing after last variable will overflow original message
        local ent_idx, is_text_chat, chat_type, player_name, chat_text
        ent_idx, elem[#elem + 1] = usermessage:ReadByte()
        is_text_chat, elem[#elem + 1] = usermessage:ReadByte() -- if set to 1, GetFilterForString gets called
        chat_type, elem[#elem + 1] = usermessage:ReadString( 256 ) -- used in ReadLocalizedString
        player_name, elem[#elem + 1] = usermessage:ReadString( 256 )
        chat_text, elem[#elem + 1] = usermessage:ReadString( 256 )

        player_name, chat_text = make_clean_string( player_name ), make_clean_string( chat_text )

        local base = client.Localize( chat_type )
        base = base:gsub( '%%(.)%d+', '%%%1' ) -- remove number after format specifier 
        -- base:gsub( '%%([acdlpsuwxz])%d+', '%%%1' ) : for lua
        -- print( 'base:', table.concat( { string.byte( clone, 1, #clone ) }, ' ' ) )

        local original = string.format( base, player_name, chat_text )
        local modified = colorize_string( original, player_name, argb_c( '#db2525ff' ) )
        print(chat_type, #chat_type)
        if chat_type == '#TF_Name_Change' then 
            modified = colorize_string( modified, chat_text, argb_c( '#db2525ff' ) )
        end

        --print( 'modified:', table.concat( { string.byte( clone, 1, #clone ) }, ' ' ) )
        --print( 'original:', table.concat( { string.byte( original, 1, #original ) }, ' ' ) )
        -- filter control characters except color codes but \x02
        usermessage:SetCurBit( elem[2] )
        usermessage:WriteByte( 0 )
        client.ChatPrintf( modified )
    end

    if usermessage:GetID() == VoiceSubtitle then
        -- cl_showtextmsg 0
        local elem = {
            [0] = 0,
         }
        local client, voicemenu, item, pszSubtitle
        client, elem[#elem + 1] = usermessage:ReadByte()
        voicemenu, elem[#elem + 1] = usermessage:ReadByte()
        item, elem[#elem + 1] = usermessage:ReadByte()
        -- need a custom voicemenu item dict
    end

    if usermessage:GetID() == 5 then
        local elem = {
            [0] = 0,
         }
        local client, chat_text
        client, elem[#elem + 1] = usermessage:ReadByte()
        chat_text, elem[#elem + 1] = usermessage:ReadString( 256 )
        usermessage:SetCurBit( 0 )
        usermessage:WriteByte( 4 )
        usermessage:WriteString( '\x01hello \x03 world\n flying is real' )
        print( string.format( 'client: %s, chat_text: %s', client, chat_text ) )
        --[[
            #define HUD_PRINTNOTIFY		1
#define HUD_PRINTCONSOLE	2
#define HUD_PRINTTALK		3
#define HUD_PRINTCENTER		4 -- interesting
        ]]
    end

    if usermessage:GetID() == PlayerLoadoutUpdated then local ent_idx end

    -- print( usermessage:GetID() )
end )

-- for localserver, enter console: net_showmsg svc_UserMessage

callbacks.Register( 'FireGameEvent', function( event )
    -- print( event:GetName() )
    -- https://wiki.alliedmods.net/Generic_Source_Server_Events
    if event:GetName() == 'player_connect_client' then
        local name, index, userid, networkid, bot
        name = event:GetString( 'name' )
        index = event:GetInt( 'index' )
        userid = event:GetInt( 'userid' )
        networkid = event:GetInt( 'networkid' )
        bot = event:GetInt( 'bot' )

        print( name, index, userid, networkid, bot )
    end
end )

local chck = (function( s )
    local cl_language, translated = select( 3, client.GetConVar( 'cl_language' ) ), client.Localize( s ) -- Steam3Client().SteamApps()->GetCurrentGameLanguage()
    assert( translated and #translated > 0,
            string.format( 'client.Localize(%q) failed on %q, change game language to "english"', s, cl_language ) )
end)( 'TF_Scout' )

local ChatFilters = {
    CHAT_FILTER_NONE = 0, -- 0 << 0
    CHAT_FILTER_JOINLEAVE = 0x000001, -- 1 << 0
    CHAT_FILTER_NAMECHANGE = 0x000002, -- 1 << 1
    CHAT_FILTER_PUBLICCHAT = 0x000004, -- 1 << 1
    CHAT_FILTER_SERVERMSG = 0x000008, -- 1 << 2
    CHAT_FILTER_TEAMCHANGE = 0x000010, -- 1 << 3
    CHAT_FILTER_ACHIEVEMENT = 0x000020, -- 1 << 4
 } -- no way to modify code, oof
-- https://code.tutsplus.com/articles/understanding-bitwise-operators--active-11301
-- net_showevents 1
