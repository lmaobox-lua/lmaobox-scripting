-- thanks @leodeveloper for helping me with regex
local Color_t = {
    rgba_color_type = 1,
    hex_color_type = 2,
    hsv_color_type = 3
 }

--[[
-- @param color_type
-- @param to_string_format (optional)
function Color:to_hex( color_type, to_string_format )
    local s = type( color_type ) == "number" and Color[tostring( color_type )]()
end
 ]]

local Color = {}
Color.__index = Color

Color.hex_to_dec = function( hex )
    return tonumber( '0x' .. hex )
end

-- @param to_string_format (optional)
-- @return hexadecimal color codes
function Color:rgba_to_hex( to_string_format )
    --[[ rgba_to_hex 
            -- The integer form of RGBA is 0xRRGGBBAA
            -- Hex for red is 0xRR000000, Multiply red value by 0x1000000(16777216) to get 0xRR000000
            -- Hex for green is 0x00GG0000, Multiply green value by 0x10000(65536) to get 0x00GG0000
            -- Hex for blue is 0x0000BB00, Multiply blue value by 0x100(256) to get 0x0000BB00
            -- Hex for alpha is 0x00000AA, thus no need to multiply
    ]] -- 

    local r, g, b, a = table.unpack( self.rgba )
    a = (0x100 <= a) and 255 or a
    local hex = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    if not (to_string_format) then
        self.hex = hex
    else
        --[[ 
            '0x%06x':format( hex ) -> '0xRRGGBBAA'
            '#%06x':format( hex ) -> '#RRGGBBAA'
            '%06x':format( hex ) -> 'RRGGBBAA'
        ]] --
        self.hex = (to_string_format .. "%06x"):format( hex )
    end
    return self.hex
end

function Color:rrggbbaa_to_rgba( to_string_format )
    local hex = type( self.hex ) == "string" and tonumber( self.hex:gsub( "^#", "" ):gsub( "^0x", "" ) ) or
                    type( self.hex ) == "number" and self.hex
    local r, g, b, a = hex_to_dec( hex:sub( 1, 2 ) ), hex_to_dec( hex:sub( 3, 4 ) ), hex_to_dec( hex:sub( 5, 6 ) ),
        hex_to_dec( hex:sub( 7, 8 ) )

    if not (to_string_format) then
        self.rgba = table.concat( { '\'' .. r .. '\'', '\'' .. g .. '\'', '\'' .. b .. '\'', '\'' .. a .. '\'' }, ', ' )
    else
        self.rgba = { r, g, b, a }
    end

    return self.rgba
end

Color.rgba = function( r, g, b, a )
    local self = setmetatable( {}, Color )
    self.rgba = { r, g, b, a }
    return self
end

Color.rrggbbaa = function( hex )
    local self = setmetatable( {}, Color )
    hex = hex:gsub( "^#", "0x" ):gsub( "^0x", "0x" )
    local hex = type( hex ) == "string" and tonumber( hex:gsub( "^#", "0x" ):gsub( "^0x", "0x" ), 10 ) or type( hex ) ==
                    "number" and hex
    self.hex = hex
    return self
end

local rgba_color = Color.rgba( 255, 255, 255, 255 )
printLuaTable( rgba_color )
print( rgba_color:rgba_to_hex( '0x' ) )

local hex_color = Color.rrggbbaa( '#ffffffff' )
printLuaTable( hex_color )
print( hex_color:rrggbbaa_to_rgba() )
