package.loaded['dkjson'] = nil
local dkjson, msgpack = require "dkjson", require "msgpack"

local encode_one, decode_one = dkjson.encode, dkjson.decode
local json_encode = function( ... )
    local data, varargs, ok = {}, { ... }
    for i = 1, #varargs do
        ok, data[i] = pcall( encode_one, varargs[i] )
        if not ok then
            return nil, 'cannot encode dkjson'
        end
    end
    if #data > 1 then
        return "[" .. table.concat( data, ',' ) .. "]"
    end
    return data[1]
end
local json_decode = function( data )
    local val = decode_one( data )
    if not val then
        return nil, 'cannot decode dkjson'
    end
    return table.unpack( val ) or val
end

local to_serialize = {
    what = {
        "omg",
        this = "is",
        1298
     },
    name = 'G2G',
    arr = { 1, 2, 3, 4, 5, 6, { 'trolled' } }
 }

--[[
do
    local f = assert( io.tmpfile() ) -- 'r+' mode
    f:setvbuf( 'no' )
    f:write( string.rep( ' ', f:seek( 'end' ) ) ) -- or use 'w' mode
    f:write( dkjson.encode( to_serialize ) )
    f:seek( 'set' )
    print( f:read( 'all' ), f:seek( 'end' ) )
end

do
    local f = assert( io.tmpfile() ) -- 'r+' mode
    f:setvbuf( 'no' )
    f:write( string.rep( ' ', f:seek( 'end' ) ) ) -- or use 'w' mode
    f:write( msgpack.encode( to_serialize ) )
    f:seek( 'set' )
    print( f:read( 'all' ), f:seek( 'end' ) )
end
]]

do
    local parent_dir = engine.GetGameDir():gsub( '[^\\/]+$', '' )
    --local f<close> = assert( io.open( parent_dir .. '/playerlist.official.json', 'r' ) )
    --local raw = f:read( 'all' )
    --local serialized = decode_one( raw )
    local f2<close> = assert( io.open( parent_dir .. '/rules.beta.json', 'r' ) )
    local raw = f2:read( 'all' )
    local serialized = decode_one( raw )
    printLuaTable( serialized )
    --[[table.insert(serialized.players, {
        attributes = { 'add-by-nil' },
        steamid = '[U:1:1337]',
        last_seen = {
            player_name = 'add-by-nil',
            time = os.time(os.date("!*t"))
        }
    })
    local data = dkjson.encode( serialized, {
        indent = true
     } )
    f2:write( data )]]
end
