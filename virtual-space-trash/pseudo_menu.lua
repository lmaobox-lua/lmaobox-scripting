-- 
-- menu library for lmaobox 5.4
-- 
-- 
local json = require 'dkjson.lua'
-- local color = require 'color.lua'

--- module

local font_cache = {}
local function font_cache( fontname, height, weight, flag )
    -- use bitwise to store h w f
    if not font_cache[fontname] then
        draw.CreateFont( fontname, height, weight, flag )
    end
end

local image_cache = {}
local function image_to_mem()
    -- store in _G or package.loaded
end

local function image_to_disk()
    local f = io.open( '', 'a+' )
    if not f then
        f = assert( io.open( '', 'w' ) )
    end
    -- local data = json.decode()
    -- ...
end

--- private 

local button_name_1 = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I",
                        "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "PAD_0",
                        "PAD_1", "PAD_2", "PAD_3", "PAD_4", "PAD_5", "PAD_6", "PAD_7", "PAD_8", "PAD_9", "PAD_DIVIDE",
                        "PAD_MULTIPLY", "PAD_MINUS", "PAD_PLUS", "PAD_ENTER", "PAD_DECIMAL", "LBRACKET", "RBRACKET",
                        "SEMICOLON", "APOSTROPHE", "BACKQUOTE", "COMMA", "PERIOD", "SLASH", "BACKSLASH", "MINUS",
                        "EQUAL", "ENTER", "SPACE", "BACKSPACE", "TAB", "CAPSLOCK", "NUMLOCK", "ESCAPE", "SCROLLLOCK",
                        "INSERT", "DELETE", "HOME", "END", "PAGEUP", "PAGEDOWN", "BREAK", "LSHIFT", "RSHIFT", "LALT",
                        "RALT", "LCONTROL", "RCONTROL", "LWIN", "RWIN", "APP", "UP", "LEFT", "DOWN", "RIGHT", "F1",
                        "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "CAPSLOCKTOGGLE",
                        "NUMLOCKTOGGLE", "SCROLLLOCKTOGGLE", "MOUSE_LEFT", "MOUSE_RIGHT", "MOUSE_MIDDLE", "MOUSE_4",
                        "MOUSE_5", "MOUSE_WHEEL_UP", "MOUSE_WHEEL_DOWN" }

local button_name_2 = {}
for i = 1, KEY_LAST do
    button_name_2[i] = string.char( i + 64 )
end

local function translate_input( button, format )
    if not format then
        return button_name_1[button]
    end
end

local function get_input_name_order( format )
    local smallest_tick, j = {}, {}
    for button = 1, MOUSE_WHEEL_DOWN do
        local active, tick = input.IsButtonDown( button ), input.IsButtonPressed( button )
        if active then
            smallest_tick[tick] = button
        end
    end
    for tick, button in pairs( smallest_tick ) do
        j[#j + 1] = translate_input( j, format )
    end
    return j
end

local clock = {}
local function get_held_time( button )
    local active = input.IsButtonDown( button )
    if not clock[button] then
        clock[button] = os.clock()
        return 0
    end
    if clock[button] and active then
        return os.clock() - clock[button]
    else
        clock[button] = nil
    end
end

local function is_input_active( button )
end

--- public api 

local function label( self, tab, name )

end

local function button( self, tab, name, clicked )

end

local function combobox( self, tab, name, mode, ... )

end

local function slider( self, tab, name, slider_init )

end

local function input( self, tab, name )

end

local function hotkey( self, tab, name, hotkey_init )

end

local function color_picker( self, tab, name, HEX8 )

end

local function tab( self, name, x, y, width, height )

end

local function reference( self, tab, name )

end

local function save()
end

local widget_type = {
    label = function( x, y, text )
        draw.Text( x, y, text )
    end,
    button = function( x, y, text )
        draw.Text( x, y, text )
        draw.FilledRect( x, y, x + 20, y + 20 )
        if is_input_active( '' ) then
            -- callback()
        end
    end
 }

local function render( self )
    -- precache x, y here 
    -- ..
    for i, c in ipairs( self.widget:len() ) do
        widget_type[c]()
    end
end

local function instance( name, x, y, width, height, font )
    local menu = {
        name = name,
        x = x,
        y = y,
        width = width,
        height = height,
        font = font,
        visible = true,
        widget = {},
        object = {},
        render = render
     }
    setmetatable( menu, {

        __call = function( self, new_widget )
            self.widget = new_widget
            return true
        end,

        __tostring = function( self )
            return json.encode( self.widget, {
                indent = true
             } )
        end,

        __index = {
            label = label,
            button = button,
            combobox = combobox,
            slider = slider,
            input = input,
            hotkey = hotkey,
            color_picker = color_picker,
            tab = tab,
            reference = reference
         },

        __len = function( self )
            return #self.widget
        end,

        __close = function()

        end
     } )
    setmetatable( menu.widget, {
        __newindex = function()

        end
     } )

    return menu
end

return {
    menu = instance
 }

-- https://www.freetool.dev/color-code-converter

