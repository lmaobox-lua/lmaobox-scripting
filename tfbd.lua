local version = '0.1-beta'
local dkjson = assert( require "dkjson", 'get dkjson: \"http://dkolf.de/src/dkjson-lua.fsl/home\" ' )
local msgpack = assert( require "msgpack", 'get msgpack: \"https://github.com/kieselsteini/msgpack\"' )
local json_encode, json_decode, msgpack_encode, msgpack_decode = dkjson.encode, dkjson.decode, msgpack.encode_one,
    msgpack.decode_one

local function crc32( s, lt )
    -- return crc32 checksum of string as an integer
    -- use lookup table lt if provided or create one on the fly
    -- if lt is empty, it is initialized.
    lt = lt or {}
    local b, crc, mask
    if not lt[1] then -- setup table
        for i = 1, 256 do
            crc = i - 1
            for _ = 1, 8 do -- eight times
                mask = -(crc & 1)
                crc = (crc >> 1) ~ (0xedb88320 & mask)
            end
            lt[i] = crc
        end
    end

    -- compute the crc
    crc = 0xffffffff
    for i = 1, #s do
        b = string.byte( s, i )
        crc = (crc >> 8) ~ lt[((crc ~ b) & 0xFF) + 1]
    end
    return ~crc & 0xffffffff
end

---

local ok, bot_detector_cache = pcall( require, 'bot_detector_cache' )
if type( bot_detector_cache ) ~= 'table' then
    bot_detector_cache = {}
end
local ok, bot_detector_data_name = pcall( require, 'bot_detector_data_name' )
if type( bot_detector_data_name ) ~= 'table' then
    bot_detector_data_name = {}
end

local function open_and_parse( filename )
    local checksum, file, raw
    file = assert( io.open( filename, 'r' ), 'cannot read ' .. filename )
    raw = file:read( 'all' )
    io.close( file )
    checksum = crc32( raw )
    if bot_detector_cache[checksum] ~= nil then
        return bot_detector_cache[checksum]
    end
    local content = json_decode( raw )
    if not content.players then
        print( filename .. ': cannot find players in database.' )
        return nil
    end
    bot_detector_cache[checksum] = content
    return bot_detector_cache[checksum]
end

local bot_detector_instance, ignore_list_instance, party_member = {}, { steam.GetSteamID() }, {}

local function find_suspect( name, steamid3 )
    local player_priority = playerlist.GetPriority( steamid3 )
    local already_found = {}

    -- avoid these ppl (they may be listed but we idc cause we play with them :thumbsup: )
    -- hardcoded for now, will include exclude list later

    if ignore_list_instance[steamid3] then
        goto skip
    end

    if gui.GetValue( 'ignore steam friends' ) == 1 and steam.IsFriend( steamid3 ) then
        goto skip
    end

    if gui.GetValue( 'Lobby Members' ) == 1 and party_member[steamid3] then
        goto skip
    end

    -- in external database
    for i, source in ipairs( bot_detector_instance ) do
        if already_found[steamid3] then
            goto skip
        end

        if not bot_detector_data_name[i] then
            bot_detector_data_name[i] = source.file_info.update_url:match( '[^\\/]+$' )
                :match( 'playerlist%.([^.]+)%.json' ) -- was playerlist%.(.*)%.json
        end

        for j, db in ipairs( source.players ) do
            if db.steamid == steamid3 then
                client.ChatPrintf( string.format( '\7FEB144%s\1 was found in \7ccccff%s\1 : \7CC99C9%s, priority: %d\1',
                    name, bot_detector_data_name[i], table.concat( db.attributes, ', ' ), player_priority ) )
                goto found
            end
        end
    end

    -- in lmaobox playerlist (%localappdata)
    -- this could be further expanded if we have a gui 
    -- like marking them with specific color
    if player_priority > 0 then
        client.ChatPrintf( string.format( '\7FEB144%s\1 is a flat earth beliver: \7CC99C9priority: %d\1', name,
            player_priority ) )
        goto found
    end

    -- custom rules check
    -- Actually, this is one part i could not directly C+P, since lua use gsub instead of regex

    goto skip
    ::found::
    already_found[steamid3] = 0
    engine.PlaySound( 'ui/system_message_alert.wav' )
    ::skip::
end

---  

--- todo: Constants, Cleaning io methods, dealing with versions

local parent_dir = engine.GetGameDir():gsub( '[^\\/]+$', '/' )
local attributes = filesystem.GetFileAttributes( parent_dir .. 'tf2_bot_detector' )
if attributes == 0xFFFFFFFF or attributes & 0x10 == 0 then
    assert( filesystem.CreateDirectory( parent_dir .. 'tf2_bot_detector' ),
        'Cannot create a new folder' .. parent_dir .. 'tf2_bot_detector' )
end

local config = {
    version = version,
    database = { 'playerlist.official.json', 'playerlist.biglist.json' },
    out_playerlist = "playerlist.custom.json"
 }
local function write_config( config )
    local f = io.open( 'tf2_bot_detector/tfbd.json', 'w' )
    f:write( json_encode( config, {
        indent = true
     } ) )
    io.close( f )
end

local f = io.open( 'tf2_bot_detector/tfbd.json', 'r' )
if not io.type( f ) then
    write_config( config )
else
    local content = json_decode( f:read( 'all' ) )
    io.close( f )
    config = type( content ) == 'table' and content or config
end

-- BF, WHEN CAN I GET FUCKING DIRECTORY ITERATOR.!!!! INTERNET TOO ARGH
for i, filename in ipairs( config.database ) do
    bot_detector_instance[#bot_detector_instance + 1] = open_and_parse( parent_dir .. 'tf2_bot_detector/' .. filename )
end

---

local function on_client_connect()
    if clientstate.GetClientSignonState() == 6 then
        client.ChatPrintf( '\x01[\x07ff3f3fL\x0799ccffb\x05o\x07ffb200x\1] \x0740ff40 Omg is that tf2 bot detector!' )
        for i, steamid3 in ipairs( party.GetMembers() ) do
            party_member[steamid3] = 0
        end
        for i = 1, globals.MaxClients() do
            local player_info = client.GetPlayerInfo( i )
            if player_info.UserID == 0 or player_info.IsBot == true then
                goto e
            end
            local name, steamid3 = player_info.Name, player_info.SteamID
            find_suspect( name, steamid3 )
            ::e::
        end
        callbacks.Unregister( 'Draw', '' )
    end
end

callbacks.Register( 'FireGameEvent', function( e )
    local event = e:GetName()

    if event == 'game_newmap' then
        callbacks.Register( 'Draw', on_client_connect )
        return
    end

    if event == 'player_connect_client' then
        local name, index, userid, steamid3, bot
        name = e:GetString( 'name' )
        index = e:GetInt( 'index' )
        userid = e:GetInt( 'userid' )
        steamid3 = e:GetString( 'networkid' )
        bot = e:GetInt( 'bot' )
        if bot == 0 then
            find_suspect( name, steamid3 )
        end
        return
    end

    if event == 'party_updated' then
        for i, steamid3 in ipairs( party.GetMembers() ) do
            party_member[steamid3] = 0
        end
    end
end )

callbacks.Register( 'Unload', function()
    package.loaded['bot_detector_cache'] = bot_detector_cache
    package.loaded['bot_detector_data_name'] = bot_detector_data_name
end )

--- 

on_client_connect()
playerlist.SetPriority( 'STEAM_1:1:21822830', 10 ) -- hello pazer
