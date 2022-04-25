local to_rgba = function( hexcodes_a )
    local integer = type( hexcodes_a ) == "string" and tonumber( "0x" .. hexcodes_a:sub( 2, #hexcodes_a ) ) or hexcodes_a
    assert( integer < 4294967295, "hexcodes cannot go over 32bits" )
    local r, g, b, a
    a = integer & 0xFF
    r = integer >> 24 & 0xFF
    g = integer >> 16 & 0xFF
    b = integer >> 8 & 0xFF
    return r, g, b, a
end

-- convert gui team color to rgba
local color_slider_to_rgba = function( path )
    local ref = gui.GetValue( path )
    local r, g, b, a
    if ref == 255 then -- tf2 team color
        if string.find( path, "Blue Team" ) then
            r, g, b, a = 153, 204, 255, 255
        elseif string.find( path, "Red Team" ) then
            r, g, b, a = 255, 64, 64, 255
        end
    elseif ref == -1 then -- white color
        r, g, b, a = 255, 255, 255, 255
    else
        a = ref & 0xFF
        r = ref >> 24 & 0xFF
        g = ref >> 16 & 0xFF
        b = ref >> 8 & 0xFF
    end
    return ref, r, g, b, a
end

callbacks.Unregister( 'Draw', "guiThing" )
callbacks.Register( 'Draw', "guiThing", function()
    local ref, r, g, b, a = color_slider_to_rgba( 'Red Team Color' )
    print( string.format( "ref: %s, rgba: %s, %s, %s, %s", ref, r, g, b, a ) )
end )
