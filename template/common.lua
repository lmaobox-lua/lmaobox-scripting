-- region: print+color library
-- @param red, green, blue, alpha [0-255]
-- @return #RRGGBBAA
local to_hex = function( r, g, b, a )
    a = (0x100 <= a) and 255 or a
    local hex = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    return ("#%08x"):format( hex )
end
-- @param #RRGGBBAA
-- @return table: red, green, blue, alpha 
local to_rgba = function( hex_eight )
    local integer = tonumber( "0x" .. hex_eight:sub( 2, #hex_eight ) )
    local r, g, b, a
    a = integer & 0xFF
    r = integer >> 24 & 0xFF
    g = integer >> 16 & 0xFF
    b = integer >> 8 & 0xFF
    return { r, g, b, a }
end

local print_console = function( sep, ... )
    sep = (sep and #sep < 4) and sep or " "
    return print( table.concat( { ... }, sep ) )
end

local print_console_color = function( rgba, sep, ... )
    local r, g, b, a = table.unpack( rgba )
    sep = (sep and #sep < 4) and sep or " "
    return printc( r, g, b, a, table.concat( { ... }, sep ) )
end

-- region: test module: color library
print_console( " | ", "[1]", "[2]", "[3]", "Omega" )
print_console_color( to_rgba( "#4af3ffff" ), nil, "hello" )
print_console_color( to_rgba( "#285828ff" ), ", ", "magestic", "core", "value", "sastify" )
-- endregion: test module: color library

-- region: print+color library

-- region: callback library (adv.)
local insert_name_callback = {}

function insert_name_callback:iterate_and_call( id, ... )
    local s = self.id
    if (type( s ) == "table") then
        for k, v in pairs( s ) do
            local va_args = { ... }
            local status, ret = type( s[k] ) == "function" and pcall( s[k], table.unpack(va_args) )
            if not status then
                ret = table.pack( ret )
                printLuaTable( ret )
            end
        end
    end
end

insert_name_callback.unbind = function( id, unique )
    local s = insert_name_callback[id]
    if type( s ) ~= "table" then
        print(
            table.concat( { ".unbind fails to remove callback:", tostring( unique ), "table: ", tostring( id ) }, " " ) )
        return
    end
    s[unique] = undef
    return true
end

insert_name_callback.bind = function( id, unique, callback )
    local s = insert_name_callback[id]
    if type( s ) ~= "table" then
        print( table.concat( { ".bind fails to create callback:", tostring( unique ), "table: ", tostring( id ) }, " " ) )
        return
    end
    if (type( unique ) == 'function') then
        callback = unique
        unique = tostring( math.randomseed( os.time() ) )
    end
    s[unique] = callback

    -- LuaFormatter off
    local method = {}
    function method:unbind() return insert_name_callback.unbind( id, unique ) end
    function method:invoke(...) return callback(table.unpack({...})) end
    -- LuaFormatter on
    return method
end

-- region: test callback library
insert_name_callback[0] = {}
insert_name_callback.bind( nil, nil, nil ) -- test fail check
local v = insert_name_callback.bind( 0, "hello", function( msg )
    print( msg )
end )
v:invoke( 'hello world' )
v:unbind()
insert_name_callback.bind( 0, function()
end )
printLuaTable( insert_name_callback )
-- assert ( value or condition statement, [ message of the error] )
-- endregion: test callback library

--[[local insert_name_callback = {}

insert_name_callback.unbind = function( id, unique )
    local s = insert_name_callback[id]
    if type( s ) ~= "table" then
        print(
            table.concat( { ".unbind fails to remove callback:", tostring( unique ), "table: ", tostring( id ) }, " " ) )
        return
    end
    s[unique] = undef
    return true
end

insert_name_callback.bind = function( id, unique, callback )
    local s = insert_name_callback[id]
    if type( s ) ~= "table" then
        print( table.concat( { ".bind fails to create callback:", tostring( unique ), "table: ", tostring( id ) }, " " ) )
        return
    end
    if (type( unique ) == 'function') then
        callback = unique
        unique = tostring( math.randomseed( os.time() ) )
    end
    s[unique] = callback

    return unique
end]] --

-- endregion: callback library

--[[
    https://www.lua.org/pil/2.2.html
    Conditionals (such as the ones in control structures) consider false and nil as false and anything else as true. 
    Beware that, unlike some other scripting languages, Lua considers both zero and the empty string as true in conditional tests
]]