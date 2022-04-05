local calc = {}
calc.x_to_left = function( x )
    x = x - x
end
calc.y_to_top = function( y )
    y = y - y
end
calc.x_to_right = function( x )
    x = x + x
end
calc.y_to_bottom = function( y )
    y = y + y
end
local t = {
    indicies = 0, -- elements to iterate
    [1] = {}, -- x: width
    [2] = {}, -- y: height
    [3] = {} -- text: lookup table
 }
function t:set_text( ... )
    self[3] = { ... }
    self.indicies = #{ ... }
end
function t:calc_text_size( font )
    draw.SetFont( font )
    local indicies, text_arr = self.indicies, self[3]
    local px, py = 0, 0
    for i = 1, indicies, 1 do
        local x, y = draw.GetTextSize( text_arr[i] )
        px, py = px + x
        self[1][i] = px
    end
end

local font = draw.CreateFont( "Verdana", 16, 800 )

t:set_text( "AA", "FL", "DT", "BT", "PING" )
t:calc_text_size( font )

callbacks.Unregister( "Draw", "2d_indicator" )
callbacks.Register( "Draw", "2d_indicator", function()

end )

local drag = function()

end

--- You get the idea 
-- LuaFormatter off
local text_height_to_bottom = function( a, b ) return b + a end
local text_width_to_right = function( a, b ) return b + a end
local text_height_to_top = function( a, b ) return  b - a end
local text_width_to_left = function( a, b ) return  b - a end
-- LuaFormatter on

-- @param : va_args: text
-- @return renderer_text: table
local renderer_text = function( ... )
    local t = {
        [1] = {}, -- x: width
        [2] = {}, -- y: height
        [3] = { ... }, -- text: string
        [4] = {} -- font: integer
     }

    -- @param font: integer
    -- @param width_direction: function, height_direction: function
    -- @return width: table, height: table 
    function t:cache_text_offset( font, width_direction, height_direction )
        draw.SetFont( font )
        local render_width, render_height, text_arr = 0, 0, self[3]
        local x, y = 0, 0
        for i = 1, #text_arr, 1 do
            local v = text_arr[i]
            render_width, render_height = draw.GetTextSize( v )
            x = type( width_direction ) == "function" and width_direction( render_width, x ) or 0
            y = type( height_direction ) == "function" and height_direction( render_height, y ) or 0
            self[1][i], self[2][i] = x, y
        end
        return self[1], self[2]
    end

    function t:cache_text_offset_mult_font( width_direction, height_direction )
        local render_width, render_height, text_arr = 0, 0, self[3]
        local x, y = 0, 0
        local font = 0
        for i = 1, #text_arr, 1 do
            local v = text_arr[i]
            font = type( self[4][i] ) == "number" and self[4][i]
            draw.SetFont( font )
            render_width, render_height = draw.GetTextSize( v )
            x = type( width_direction ) == "function" and width_direction( render_width, x ) or 0
            y = type( height_direction ) == "function" and height_direction( render_height, y ) or 0
            self[1][i], self[2][i] = x, y
        end
        return self[1], self[2]
    end

    return t
end
