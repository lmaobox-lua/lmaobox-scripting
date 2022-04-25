-- aid common tasks with "neglectable" (foreshadow) performance cost

-- region: print+color library
-- @param red, green, blue, alpha [0-255]
-- @return #RRGGBBAA
local to_hexcodes = function( r, g, b, a )
    a = (0x100 <= a) and 255 or a
    local hex = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    return ("#%08x"):format( hex )
end
-- @param #RRGGBBAA
-- @return table: red, green, blue, alpha 
local to_rgba = function( hexcodes_a )
    local integer = tonumber( "0x" .. hexcodes_a:sub( 2, #hexcodes_a ) )
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

local print_console_color = function( hex, sep, ... )
    local r, g, b, a = table.unpack( to_rgba( hex ) )
    sep = (sep and #sep < 4) and sep or " "
    return printc( r, g, b, a, table.concat( { ... }, sep ) )
end

-- region: test module: color library
print_console( " | ", "[1]", "[2]", "[3]", "Omega" )
print_console_color( "#4af3ffff", nil, "hello" )
print_console_color( "#285828ff", ", ", "magestic", "core", "value", "sastify" )
-- endregion: test module: color library

-- region: print+color library

-- region: custom formatter
local localize_and_format = function( key, ... )
    local text = key
    local va_args, order = { ... }, {}
    text = (text:gsub( '%%s(%d+)', "%%%1"))
    text = text:gsub( '%%(%d+)', function( i )
        table.insert( order, va_args[tonumber( i )] )
        return '%s'
    end )
    print( text )
    text = string.format( text, table.unpack( order ) )
    return text
end

local test_localize_and_format = (function()
    local example = "%s3 killed %s1, but %s2 refragged for %1s"
    local text = localize_and_format( example, "cool", "stuff", "bro", "xd")
    local text_1 = string.format( example, "cool", "stuff", "bro", "xd")
    print( "with custom fmt: " .. text )
    print( "with string.format: ", text_1 )
end)
-- endregion: custom formatter

-- region: callback library (adv.)
local insert_name_callback = {}

function insert_name_callback:iterate_and_call( id, ... )
    local s = self.id
    if (type( s ) == "table") then
        for k, v in pairs( s ) do
            local va_args = { ... }
            local status, ret = type( s[k] ) == "function" and pcall( s[k], table.unpack( va_args ) )
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

-- region: delay call using timer as callbacks.Register('Draw')

-- endregion: delay call using timer as callbacks.Register('Draw')

--[[
    https://www.lua.org/pil/2.2.html
    Conditionals (such as the ones in control structures) consider false and nil as false and anything else as true. 
    Beware that, unlike some other scripting languages, Lua considers both zero and the empty string as true in conditional tests
]]
