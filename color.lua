-- Over extremely complicated library for color codes transfer
local Color_t = {
    rgba_color_type = 1,
    hex_color_type = 2,
    hsv_color_type = 3
 }

local function hsl_to_rgb( h, s, L )
    h = h / 360
    local m1, m2
    if L <= 0.5 then
        m2 = L * (s + 1)
    else
        m2 = L + s - L * s
    end
    m1 = L * 2 - m2

    local function _h2rgb( m1, m2, h )
        if h < 0 then
            h = h + 1
        end
        if h > 1 then
            h = h - 1
        end
        if h * 6 < 1 then
            return m1 + (m2 - m1) * h * 6
        elseif h * 2 < 1 then
            return m2
        elseif h * 3 < 2 then
            return m1 + (m2 - m1) * (2 / 3 - h) * 6
        else
            return m1
        end
    end

    return _h2rgb( m1, m2, h + 1 / 3 ), _h2rgb( m1, m2, h ), _h2rgb( m1, m2, h - 1 / 3 )
end

local function rgb_to_hsl( r, g, b )
    -- r, g, b = r/255, g/255, b/255
    local min = math.min( r, g, b )
    local max = math.max( r, g, b )
    local delta = max - min

    local h, s, l = 0, 0, ((min + max) / 2)

    if l > 0 and l < 0.5 then
        s = delta / (max + min)
    end
    if l >= 0.5 and l < 1 then
        s = delta / (2 - max - min)
    end

    if delta > 0 then
        if max == r and max ~= g then
            h = h + (g - b) / delta
        end
        if max == g and max ~= b then
            h = h + 2 + (b - r) / delta
        end
        if max == b and max ~= r then
            h = h + 4 + (r - g) / delta
        end
        h = h / 6;
    end

    if h < 0 then
        h = h + 1
    end
    if h > 1 then
        h = h - 1
    end

    return h * 360, s, l
end

-- thanks @leodeveloper for helping me with regex
local Color = {}
Color.__index = Color

Color.hex_to_dec = function( hex )
    return tonumber( '0x' .. hex:gsub( "^#", "" ):gsub( "^0x", "" ) )
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
    a = (256 <= a) and 255 or a
    local hex = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a
    --[[ 
            '0x%06x':format( hex ) -> '0xRRGGBBAA'
            '#%06x':format( hex ) -> '#RRGGBBAA'
            '%06x':format( hex ) -> 'RRGGBBAA'
            -- this is wrong, 08x for padding is correct
            -- pasted COLOR library
        ]] --
    self.hex = (to_string_format .. "%06x"):format( hex )
    return self.hex
end

function Color:hex_to_rgba( to_string_format )
    local hex = self.hex
    local r, g, b, a
    if (#hex == 4) then
        r, g, b, a = self.hex_to_dec( hex:sub( 1, 2 ) ), self.hex_to_dec( hex:sub( 2, 3 ) ),
            self.hex_to_dec( hex:sub( 3, 4 ) ), self.hex_to_dec( hex:sub( 4, 4 ) )
    else
        r, g, b, a = self.hex_to_dec( hex:sub( 1, 2 ) ), self.hex_to_dec( hex:sub( 3, 4 ) ),
            self.hex_to_dec( hex:sub( 5, 6 ) ), self.hex_to_dec( hex:sub( 7, 8 ) ) or 255
    end

    if (to_string_format) then
        self.rgba = table.concat( { r, g, b, a }, ', ' )
        return self.rgba
    end
    self.rgba = { r, g, b, a }
    return self.rgba
end

function Color:get_value()
    return self.rgba or self.hex
end

-- @param color_type : number
-- @param to_string_format : optional
function Color:to_hex( color_type, to_string_format )
    local s = type( color_type ) == "number" and Color[tostring( Color_t )]()
end

-- #region constructor
-- rgb / rbga colors
-- rgb percentage
Color.rgba = function( r, g, b, a )
    local self = setmetatable( {}, Color )
    self.rgba = { r, g, b, (a or 255) }
    return self
end

-- six-digit / eight-digit hex color codes
Color.hex = function( hex )
    local self = setmetatable( {}, Color )
    hex = hex:gsub( "^#", "" ):gsub( "^0x", "" ) -- # == 0x
    self.hex = hex
    return self
end

-- decimal to heximal
Color.dec = function( dec )
    return Color.hex( ("%06x"):format( dec ) )
end

-- #endregion constructor

local print_console_color = function( color, ... )
    local r, g, b, a = table.unpack( color )
    return printc( r, g, b, a, ... )
end

local rgba_color = Color.rgba( 255, 255, 255, 255 )
printLuaTable( rgba_color )
print_console_color( rgba_color:get_value(), rgba_color:rgba_to_hex( '0x' ) )

local hex_color = Color.hex( '#fdfe' ) -- -> #ffddffee
printLuaTable( hex_color )
print_console_color( hex_color:hex_to_rgba(), hex_color:hex_to_rgba( '' ) )

local dec_color = Color.dec( 0xcfeeaaf2 )
printLuaTable( dec_color )
print_console_color( dec_color:hex_to_rgba(), dec_color:hex_to_rgba( '' ) )

