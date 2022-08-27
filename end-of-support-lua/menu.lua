---
--- making a graphic user interface is pain
--- 
local preload -- forward declaration

-- https://github.dev/lua9520/source-engine-2018-hl2_src/blob/master/inputsystem/key_translation.cpp#L705
-- https://lmaobox.net/lua/Lua_Constants/
local input_key_name = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I",
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
input_key_name[-1], input_key_name[0] = "[invalid]", ''

local ok, key_event = pcall( require, 'menu@key_event_cache' )
if type( key_event ) ~= 'table' then
    key_event = {}
end

--- https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/public/inputsystem/InputEnums.h
local input_event_t = {
    Pressed = 1,
    Released = 2,
    DoubleClicked = 3,
    Scrolled = 4
 }

local max_delay = 250
-- simulate input_event since we don't have access 
-- todo ask 'blackfire' for CInputSystem::GetEventData(). 
---@param <table> input_button
local function capture_input( self )
    local status
    local button = self.button
    local pressed, press, rel = input.IsButtonDown( button ), input.IsButtonPressed( button ),
        input.IsButtonReleased( button )
    if pressed then
        status = input_event_t.Pressed
        if press == self.press then
            if not self.press_start then
                self.press_start = os.clock() * 1000
            end
            self.held = os.clock() * 1000 - self.press_start
        end
    end
    if rel > press then
        status = input_event_t.Released
        self.press_start = nil
        self.held = 0
    end
    if press == rel and press - self.press_old < press then
        self.press_old = 0
        self.press_start = os.clock() * 1000
        status = input_event_t.Scrolled
        pressed = true
    end
    if pressed and self.press ~= press then
        if (os.clock() * 1000 - self.double_tap_start) <= max_delay then
            status = input_event_t.DoubleClicked
        else
            self.double_tap_start = os.clock() * 1000 + max_delay
        end
    end
    if self.press ~= press then
        self.press_old = self.press
        self.press = press
    end
    if self.release ~= rel then
        self.release_old = self.release
        self.release = rel
    end
    return status, self.held, input_key_name[button]
end

local function new_input( code )
    if type( code ) ~= 'number' then
        return
    end
    key_event[code] = {
        button = code,
        press = 0,
        release = 0,
        held = 0,
        press_old = 0,
        release_old = 0,
        double_tap_start = 0,
        press_start = nil
     }
    local mt = setmetatable( key_event[code], {
        __index = {
            capture_input = capture_input
         },
        __tostring = function( self )
            if not self.key_name then
                self.key_name = input_key_name[self.button]
            end
            return self.key_name
        end
     } )
    return mt
end

local function get_current_fastest_input()
    -- todo find out if limit is 109
    local tbl = {}
    for i = 1, 109 do
        local pressed = input.IsButtonDown( i )
        if pressed then
            tbl[input.IsButtonPressed( i )] = i
        end
    end
    return tbl[next( tbl, nil )]
end

-- not supporting ? " " all sort of that yet
local rawdata, queuetext = {}, {}
local function lmaobox_get_text_from_input()
    for i = 1, 109 do
        local pressed, press = input.IsButtonDown( i ), input.IsButtonPressed( i )
        if pressed and rawdata[i] ~= press then
            rawdata[i] = press
            if i == KEY_BACKSPACE then
                table.remove( queuetext, #queuetext )
            else
                if input_key_name[i] == 'SPACE' then
                    table.insert( queuetext, ' ' )
                elseif input_key_name[i] == 'ENTER' then
                    --table.insert( queuetext, '\n' )
                else
                    table.insert( queuetext, input_key_name[i] )
                end
            end
        end
    end
    print(#queuetext)
    return queuetext
end

callbacks.Register( 'Unload', function()
    -- preload()
end )

local function preload()
    package.loaded['menu@key_event_cache'] = key_event
end

--- 
local key_h = new_input( MOUSE_5 )
local new_key = nil
callbacks.Register( 'Draw', function()
    -- print( input.IsButtonPressed( MOUSE_WHEEL_UP ) )
    draw.SetFont( 3 )
    draw.Color( 0, 0, 0, 255 )
    draw.FilledRect( 200, 200, 400, 300 )
    draw.Color( 255, 255, 255, 255 )
    draw.Text( 200, 200, 'Press MOUSE_5 to define new key!' )
    draw.Text( 220, 220, string.format( 'Current Key: %s', new_key ) )
    local input = key_h:capture_input()
    if input == 3 then
        print( 'double clicked.' )
    end
    if input == 1 then
        new_key = new_input( get_current_fastest_input() ) or new_key
    end
    if new_key then
        local input = new_key:capture_input()
        if input == 2 then
            draw.Text( 250, 250, 'Inactive!' )
        end
        if input == 3 then
            draw.Text( 250, 250, 'double tapping!' )
        end
    end
    print( table.concat( lmaobox_get_text_from_input() ) )


    -- print( key_h:capture_input() )
end )

callbacks.Register( 'SendStringCmd', function( cmd )
    local str = cmd:Get()
    -- printc(255, 0, 255, 255, str, #str)
    -- cmd:Set('')
    UnloadScript( GetScriptName() )
    LoadScript( GetScriptName() )
end )

-- update after every 66 frames
--  globals.FrameCount() % (1 // globals.TickInterval()) == 0

