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
print_console(" | ", "[1]", "[2]", "[3]", "Omega")
print_console_color( to_rgba( "#4af3ffff" ), nil, "hello" )
print_console_color( to_rgba( "#285828ff" ), ", ", "magestic", "core", "value", "sastify" )
-- endregion: test module: color library

-- region: print+color library
