local IntegerColor = function( p )
    local color, rainbow, parsed = {}, {}, false

    -- internal
    color.__rgba, color.__hexa, color.__hsla = nil, nil, nil

    --[[
        'rgba(255, 0, 0, 255)'
        'hsla(0, 100%, 50%, 1)'
        'hexa(#ff0000ff)'
    ]]

    local constructor = {}
    constructor.rgba = function( red, green, blue, alpha )
        intern.rgba = { red, green, blue, alpha }
        return color
    end
    constructor.hsla = function( hue, saturation, lightness, alpha ) intern = { 0 } end
    constructor.hexa = function( hex )
        local byte = tonumber( '0x' .. hex )
        color.__rgba = { byte >> 24 & 0xFF, byte >> 16 & 0xFF, byte >> 8 & 0xFF, byte & 0xFF }
        return color
    end
    constructor.rainbow = function( timer, alpha ) end

    -- opaque
    constructor.rgb = function( red, green, blue ) return constructor.rgba( red, green, blue, 255 ) end
    constructor.hsl = function( hue, saturation, lightness ) return constructor.hsla( hue, saturation, lightness, 1 ) end
    constructor.hex = function( hex ) return constructor.hexa( ('%06xff'):format( hex ) ) end

    for key, func in pairs( constructor ) do
        if string.find( p, key, 1, true ) then
            local args = {}
            local contains_float_point = key == 'hsla'
            p:gsub( '(%(.-%))',
                    function( c )
                for matched in c:gsub( '%G', '' ):gmatch( '([^()#,]+)' ) do args[#args + 1] = tonumber( matched ) end
            end )
            return func( table.unpack( args ) )
        end
    end

    if not parsed then return end

    -- converter
    color.rgba = function() end
    color.hexa = function() end
    color.argbByte = function() end
    color.hsla = function() end

    -- stringify
    color.out_table = function() end
    color.out_string = function() end

    color.print = function() end -- printc

    --
    color.brightness_mode = function() end
    color.is_dark = function() end
    color.is_light = function() end
    color.darken = function() end
    color.lighten = function() end

    color.mix = function() end
    color.rotate = function() end

    --
    rainbow.darken = function() end
    rainbow.lighten = function() end
    rainbow.reverse = function() end
    rainbow.print = function() end
end

IntegerColor( string.format( 'rgb(%s, %s, %s, %s)', math.random( 255 ), math.random( 255 ), math.random( 255 ), math.random( 255 ) ) )

