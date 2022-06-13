UnloadScript( GetScriptName() )
local white_c<const>, old_c<const>, team_c<const>, location_c<const>, achievement_c<const>, black_c<const> = '\x01', '\x02', '\x03', '\x04',
                                                                                                             '\x05', '\x06'
local rgb_c = function( hexcodes ) return '\x07' .. hexcodes:gsub( '#', '' ) end
local argb_c = function( hexcodes_a ) return '\x08' .. hexcodes_a:gsub( '#', '' ) end
local to_rgba = function( hexcodes_a )
    local i32 = type( hexcodes_a ) == 'string' and tonumber( '0x' .. hexcodes_a:gsub( '#', '' ) ) or hexcodes_a
    return { i32 >> 24 & 0xFF, i32 >> 16 & 0xFF, i32 >> 8 & 0xFF, i32 & 0xFF }
end

local rainbow = {
    '#C11B17FF',
    '#F87A17FF',
    '#FFFF00FF',
    '#00FF00FF',
    '#2B60DEFF',
    '#893BFFFF',
    '#F63817FF',
    '#E78E17FF',
    '#FFFC17FF',
    '#5EFB6EFF',
    '#1531ECFF',
    '#8E35EFFF',
    index = 1,
 }
function rainbow.make()
    rainbow.index = rainbow.index + 1 > #rainbow and 1 or rainbow.index + 1
    return rainbow[rainbow.index]
end

local t = {
    [0] = '#f5e5c4ff',
    [2] = '#ff4040ff',
    [3] = '#99ccffff',
 }

local player_team_color = function( team_num )
    return argb_c( t[team_num] )
end

local querytag = function( playerindex )
    local info = client.GetPlayerInfo( playerindex )
    if steam.IsFriend( info.SteamID ) == true then return argb_c( '#9EE09EFF' ) .. '[Friend]' end
    if steam.ToSteamID64( info.SteamID ) == 76561198834582739 then 
        printc(255,0,0,255, string.format("creator is : %s, %s, %s", info.SteamID, steam.ToSteamID64(info.SteamID), info.Name))
        return argb_c( '#CC99C9FF' ) .. '[Creator]' 
    end
    return ''
end

local make_unique_string = function( prefix ) return table.concat( { prefix or '', engine.RandomFloat( 0, 1 ), GetScriptName() }, '_' ) end

local make_clean_string = function( original )
    -- filter control characters
    original = string.gsub( original, '%c', '' )
    -- escape magic characters
    original = string.gsub( original, '%%', '%%%%' )
    return original -- modified
end

local colorize_string = function( original, to_colorize, prefix, suffix )
    prefix = prefix or '\x04'
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
local class_name = { 'TF_Scout', 'TF_Sniper', 'TF_Soldier', 'TF_Demoman', 'TF_Medic', 'TF_HWGuy', 'TF_Pyro', 'TF_Spy', 'TF_Engineer' }

-- maybe also add teams_changed event?
-- what about player_hurt for local and mess with TextMsg 

callbacks.Register( 'FireGameEvent', make_unique_string(), function( event )
    if event:GetName() == 'player_changeclass' then

        -- add a check if we want to print this during a competitive game when team change class

        local player = entities.GetByUserID( event:GetInt( 'userid' ) )
        if not player or not player:IsValid() then return end
        local player_name, chat_text = player:GetName(), client.Localize( class_name[event:GetInt( 'class' )] )

        local base = client.Localize( 'TF_Class_Change' )
        base = utf8.char( string.byte( base, 1, #base ) )
        base = base:gsub( '%%(.)%d+', '%%%1' ) -- remove number after format specifier 
        -- base:gsub( '%%([acdlpsuwxz])%d+', '%%%1' ) : for lua
        -- print( 'base:', table.concat( { string.byte( clone, 1, #clone ) }, ' ' ) )

        local original = string.format( base, player_name, chat_text )
        local modified = colorize_string( original, player_name, player_team_color( player:GetTeamNumber() ) )
        modified = colorize_string( modified, chat_text, player_team_color( player:GetTeamNumber() ) )

        -- add additional info
        local time, tag
        time = argb_c( '#00f7ffaf' ) .. os.date( '%H:%M' ) .. ' :'
        tag = querytag( player:GetIndex() )
        modified = '\x01' .. table.concat( { time, tag, modified }, ' ' )

        client.ChatPrintf( modified, 1, #modified )
    end
end )

callbacks.Register( 'FireGameEvent', make_unique_string(), function( event )
    if event:GetName() == 'player_connect_client' then
        local name, index, userid, networkid, bot = event:GetString( 'name' ), event:GetInt( 'index' ), event:GetInt( 'userid' ),
                                                    event:GetInt( 'networkid' ), event:GetInt( 'bot' )
        local player = entities.GetByIndex( index )
        if bot == 0 or bot == 1 and engine.GetServerIP() == 'loopback' then
            local player_name = name
            local base = client.Localize( 'Game_connected' )
            base = utf8.char( string.byte( base, 1, #base ) )
            base = base:gsub( '%%(.)%d+', '%%%1' ) -- remove number after format specifier 
            local original = string.format( base, player_name )
            local modified = colorize_string( original, player_name, argb_c(rainbow.make()) )
            local time, tag
            time = argb_c( '#00f7ffaf' ) .. os.date( '%H:%M' ) .. ' :'
            tag = querytag( index )
            modified = '\x01' .. table.concat( { time, tag, modified }, ' ' )
            client.ChatPrintf( modified, 1, #modified )
        end
    end
end )

callbacks.Register( 'DispatchUserMessage', make_unique_string(), function( msg )
    if msg:GetID() == Shake or msg:GetID() == Fade then -- remove effect
        msg:WriteInt( 0, msg:GetDataBits() )
    end

    if msg:GetID() == SayText2 then
        local elem = {}
        local ent_idx, is_text_chat, chat_type, player_name, chat_text
        ent_idx, elem[#elem + 1] = msg:ReadByte()
        is_text_chat, elem[#elem + 1] = msg:ReadByte() -- if set to 1, GetFilterForString gets called
        chat_type, elem[#elem + 1] = msg:ReadString( 256 ) -- used in ReadLocalizedString
        player_name, elem[#elem + 1] = msg:ReadString( 256 )
        chat_text, elem[#elem + 1] = msg:ReadString( 256 )

        player_name, chat_text = make_clean_string( player_name ), make_clean_string( chat_text )

        local player = entities.GetByIndex( ent_idx )

        local base = client.Localize( chat_type )
        base = utf8.char( string.byte( base, 1, #base ) )
        base = base:gsub( '%%(.)%d+', '%%%1' ) -- remove number after format specifier 
        -- base:gsub( '%%([acdlpsuwxz])%d+', '%%%1' ) : for lua
        -- print( 'base:', table.concat( { string.byte( clone, 1, #clone ) }, ' ' ) )

        local original = string.format( base, player_name, chat_text )
        local modified = colorize_string( original, player_name, player_team_color( player:GetTeamNumber() ) )
        print( chat_type, #chat_type )
        if chat_type == '#TF_Name_Change' then
            -- bit & 0x000002 = 0
            -- if client.GetConVar( 'cl_chatfilters' ) -- todo respect user option
            modified = colorize_string( modified, chat_text, argb_c( rainbow.make() ) )
        end

        -- add additional info
        local time, tag
        time = argb_c( '#00f7ffaf' ) .. os.date( '%H:%M' ) .. ' :'
        tag = querytag( ent_idx )

        -- steam friend thingy

        modified = '\x01' .. table.concat( { time, tag, modified }, ' ' )

        -- print( 'modified:', table.concat( { string.byte( modified, 1, #modified ) }, ' ' ) )
        -- print( 'original:', table.concat( { string.byte( original, 1, #original ) }, ' ' ) )

        msg:SetCurBit( elem[2] ) -- no string localize for you.
        msg:WriteByte( 0 )

        client.ChatPrintf( modified, 1, #modified )
    end
end )

local main = (function()
    local ret = client.Localize( 'TF_Engineer' )
    if ret ~= nil then return end
    -- too lazy to implement own localize function
    printc( 255, 60, 20, 255,
            string.format( '[error] %s cannot run (unsupported language)\nFix : change game language to english', GetScriptName() ) )
    UnloadScript( GetScriptName() )
end)()

-- net_showmsg svc_UserMessage
-- net_showevents 1
-- get ppl tier and level
