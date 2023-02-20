local buttons_name, buttons_name_size
local buttons, MOUSE_5 = {}, 111
local recent_text_code, recent_text_at, poll_tick = 0, 0, 0

---@region buttons code translation
do
    local steam_controller_buttons, steam_controller_buttons_axis, steam_controller_buttons_virtual, index
    buttons_name = {
        "0", -- KEY_0,
        "1", -- KEY_1,
        "2", -- KEY_2,
        "3", -- KEY_3,
        "4", -- KEY_4,
        "5", -- KEY_5,
        "6", -- KEY_6,
        "7", -- KEY_7,
        "8", -- KEY_8,
        "9", -- KEY_9,
        "a", -- KEY_A,
        "b", -- KEY_B,
        "c", -- KEY_C,
        "d", -- KEY_D,
        "e", -- KEY_E,
        "f", -- KEY_F,
        "g", -- KEY_G,
        "h", -- KEY_H,
        "i", -- KEY_I,
        "j", -- KEY_J,
        "k", -- KEY_K,
        "l", -- KEY_L,
        "m", -- KEY_M,
        "n", -- KEY_N,
        "o", -- KEY_O,
        "p", -- KEY_P,
        "q", -- KEY_Q,
        "r", -- KEY_R,
        "s", -- KEY_S,
        "t", -- KEY_T,
        "u", -- KEY_U,
        "v", -- KEY_V,
        "w", -- KEY_W,
        "x", -- KEY_X,
        "y", -- KEY_Y,
        "z", -- KEY_Z,
        "KP_INS", -- KEY_PAD_0,
        "KP_END", -- KEY_PAD_1,
        "KP_DOWNARROW", -- KEY_PAD_2,
        "KP_PGDN", -- KEY_PAD_3,
        "KP_LEFTARROW", -- KEY_PAD_4,
        "KP_5", -- KEY_PAD_5,
        "KP_RIGHTARROW", -- KEY_PAD_6,
        "KP_HOME", -- KEY_PAD_7,
        "KP_UPARROW", -- KEY_PAD_8,
        "KP_PGUP", -- KEY_PAD_9,
        "KP_SLASH", -- KEY_PAD_DIVIDE,
        "KP_MULTIPLY", -- KEY_PAD_MULTIPLY,
        "KP_MINUS", -- KEY_PAD_MINUS,
        "KP_PLUS", -- KEY_PAD_PLUS,
        "KP_ENTER", -- KEY_PAD_ENTER,
        "KP_DEL", -- KEY_PAD_DECIMAL,
        "[", -- KEY_LBRACKET,
        "]", -- KEY_RBRACKET,
        "SEMICOLON", -- KEY_SEMICOLON,
        "'", -- KEY_APOSTROPHE,
        "`", -- KEY_BACKQUOTE,
        ",", -- KEY_COMMA,
        ".", -- KEY_PERIOD,
        "/", -- KEY_SLASH,
        "\\", -- KEY_BACKSLASH,
        "-", -- KEY_MINUS,
        "=", -- KEY_EQUAL,
        "ENTER", -- KEY_ENTER,
        "SPACE", -- KEY_SPACE,
        "BACKSPACE", -- KEY_BACKSPACE,
        "TAB", -- KEY_TAB,
        "CAPSLOCK", -- KEY_CAPSLOCK,
        "NUMLOCK", -- KEY_NUMLOCK,
        "ESCAPE", -- KEY_ESCAPE,
        "SCROLLLOCK", -- KEY_SCROLLLOCK,
        "INS", -- KEY_INSERT,
        "DEL", -- KEY_DELETE,
        "HOME", -- KEY_HOME,
        "END", -- KEY_END,
        "PGUP", -- KEY_PAGEUP,
        "PGDN", -- KEY_PAGEDOWN,
        "PAUSE", -- KEY_BREAK,
        "SHIFT", -- KEY_LSHIFT,
        "RSHIFT", -- KEY_RSHIFT,
        "ALT", -- KEY_LALT,
        "RALT", -- KEY_RALT,
        "CTRL", -- KEY_LCONTROL,
        "RCTRL", -- KEY_RCONTROL,
        "LWIN", -- KEY_LWIN,
        "RWIN", -- KEY_RWIN,
        "APP", -- KEY_APP,
        "UPARROW", -- KEY_UP,
        "LEFTARROW", -- KEY_LEFT,
        "DOWNARROW", -- KEY_DOWN,
        "RIGHTARROW", -- KEY_RIGHT,
        "F1", -- KEY_F1,
        "F2", -- KEY_F2,
        "F3", -- KEY_F3,
        "F4", -- KEY_F4,
        "F5", -- KEY_F5,
        "F6", -- KEY_F6,
        "F7", -- KEY_F7,
        "F8", -- KEY_F8,
        "F9", -- KEY_F9,
        "F10", -- KEY_F10,
        "F11", -- KEY_F11,
        "F12", -- KEY_F12,
        "CAPSLOCKTOGGLE", -- KEY_CAPSLOCKTOGGLE,
        "NUMLOCKTOGGLE", -- KEY_NUMLOCKTOGGLE,
        "SCROLLLOCKTOGGLE", -- KEY_SCROLLLOCKTOGGLE,
        -- Mouse
        "MOUSE1", -- MOUSE_LEFT,
        "MOUSE2", -- MOUSE_RIGHT,
        "MOUSE3", -- MOUSE_MIDDLE,
        "MOUSE4", -- MOUSE_4,
        "MOUSE5", -- MOUSE_5,
        "MWHEELUP", -- MOUSE_WHEEL_UP
        "MWHEELDOWN", -- MOUSE_WHEEL_DOWN
        -- Joystick
        "JOY1", -- JOY_1
        "JOY2", -- JOY_2
        "JOY3", -- JOY_3
        "JOY4", -- JOY_4
        "JOY5", -- JOY_5
        "JOY6", -- JOY_6
        "JOY7", -- JOY_7
        "JOY8", -- JOY_8
        "JOY9", -- JOY_9
        "JOY10", -- JOY_10
        "JOY11",
        "JOY12",
        "JOY13",
        "JOY14",
        "JOY15",
        "JOY16",
        "JOY17",
        "JOY18",
        "JOY19",
        "JOY20",
        "JOY21",
        "JOY22",
        "JOY23",
        "JOY24",
        "JOY25",
        "JOY26",
        "JOY27",
        "JOY28",
        "JOY29",
        "JOY30",
        "JOY31",
        "JOY32", -- JOYSTICK_LAST_BUTTON
        "POV_UP", -- JOYSTICK_FIRST_POV_BUTTON
        "POV_RIGHT",
        "POV_DOWN",
        "POV_LEFT", -- JOYSTICK_LAST_POV_BUTTON
        "X AXIS POS", -- JOYSTICK_FIRST_AXIS_BUTTON
        "X AXIS NEG",
        "Y AXIS POS",
        "Y AXIS NEG",
        "Z AXIS POS",
        "Z AXIS NEG",
        "R AXIS POS",
        "R AXIS NEG",
        "U AXIS POS",
        "U AXIS NEG",
        "V AXIS POS",
        "V AXIS NEG", -- JOYSTICK_LAST_AXIS_BUTTON
        "FALCON_NULL", -- NVNT temp Fix for unaligned joystick enumeration
        "FALCON_1", -- NOVINT_FIRST
        "FALCON_2",
        "FALCON_3",
        "FALCON_4",
        "FALCON2_1",
        "FALCON2_2",
        "FALCON2_3",
        "FALCON2_4", -- NOVINT_LAST
    }
    steam_controller_buttons = {
        "SC_A",
        "SC_B",
        "SC_X",
        "SC_Y",
        "SC_DPAD_UP",
        "SC_DPAD_RIGHT",
        "SC_DPAD_DOWN",
        "SC_DPAD_LEFT",
        "SC_LEFT_BUMPER",
        "SC_RIGHT_BUMPER",
        "SC_LEFT_TRIGGER",
        "SC_RIGHT_TRIGGER",
        "SC_LEFT_GRIP",
        "SC_RIGHT_GRIP",
        "SC_LEFT_PAD_TOUCH",
        "SC_RIGHT_PAD_TOUCH",
        "SC_LEFT_PAD_CLICK",
        "SC_RIGHT_PAD_CLICK",
        "SC_LPAD_UP",
        "SC_LPAD_RIGHT",
        "SC_LPAD_DOWN",
        "SC_LPAD_LEFT",
        "SC_RPAD_UP",
        "SC_RPAD_RIGHT",
        "SC_RPAD_DOWN",
        "SC_RPAD_LEFT",
        "SC_SELECT",
        "SC_START",
        "SC_STEAM",
        "SC_NULL",
    }
    steam_controller_buttons_axis = {
        "SC_LPAD_AXIS_RIGHT",
        "SC_LPAD_AXIS_LEFT",
        "SC_LPAD_AXIS_DOWN",
        "SC_LPAD_AXIS_UP",
        "SC_AXIS_L_TRIGGER",
        "SC_AXIS_R_TRIGGER",
        "SC_RPAD_AXIS_RIGHT",
        "SC_RPAD_AXIS_LEFT",
        "SC_RPAD_AXIS_DOWN",
        "SC_RPAD_AXIS_UP",
        "SC_GYRO_AXIS_PITCH_POSITIVE",
        "SC_GYRO_AXIS_PITCH_NEGATIVE",
        "SC_GYRO_AXIS_ROLL_POSITIVE",
        "SC_GYRO_AXIS_ROLL_NEGATIVE",
        "SC_GYRO_AXIS_YAW_POSITIVE",
        "SC_GYRO_AXIS_YAW_NEGATIVE"
    }
    steam_controller_buttons_virtual = {
        "SC_F1",
        "SC_F2",
        "SC_F3",
        "SC_F4",
        "SC_F5",
        "SC_F6",
        "SC_F7",
        "SC_F8",
        "SC_F9",
        "SC_F10",
        "SC_F11",
        "SC_F12"
    }
    index = #buttons_name + 1
    for _, t in ipairs({ steam_controller_buttons, steam_controller_buttons_axis, steam_controller_buttons_virtual }) do
        for __ = 1, 7, 1 do
            for ___, name in ipairs(t) do
                buttons_name[index] = name
                index               = index + 1
            end
        end
    end
    ---@format disable-next
    assert(buttons_name[255] == 'SC_RPAD_DOWN', "assertion failed: expected 'SC_RPAD_DOWN', got '" .. buttons_name[255] .. "' instead")
    buttons_name_size = index
end
---@endregion buttons code translation

---@region input handling

---@format disable-next
for code = 1, MOUSE_5 do buttons[code] = { active = false, pressed = false, released = false, pressed_at = -1, released_at = -1 } end

local function handle_input()
    poll_tick = input.GetPollTick()
    for code = 1, MOUSE_5 do
        local button = buttons[code]
        if input.IsButtonDown(code) then
            if not button.active then
                button.active     = true
                button.pressed    = true
                local pressed_at  = select(2, input.IsButtonPressed(code))
                button.pressed_at = pressed_at
                if pressed_at > recent_text_at then
                    recent_text_at   = pressed_at
                    recent_text_code = code
                end
            else
                button.pressed = false
            end
        else
            if button.active then
                button.active      = false
                button.released    = true
                button.released_at = select(2, input.IsButtonReleased(code))
            else
                button.released = false
            end
        end
    end
end

local function is_button_pressed(code)
    return buttons[code].pressed
end

local function is_button_released(code)
    return buttons[code].released
end

local function seconds_since_button_held(code)
    local button = buttons[code]
    if button.active then
        return poll_tick - button.pressed_at
    end
    return -1
end

-- local button_event = { action = nil, tick = nil, code = nil, mouse_x = nil, mouse_y = nil }
-- local post_user_event = {}
-- function post_user_event:set(callback)
--     callback(button_event)
-- end

-- post_user_event:set(function(button)
--     local code = button.code
--     if code >= KEY_0 and code <= KEY_Z then return buttons_name[code] end
--     if code >= KEY_PAD_DIVIDE and code <= KEY_TAB then return buttons_name[code] end
--     return ""
-- end)

---@endregion input handling

---@region renderer 

---@endregion renderer

---@region gui api
local gui = {}
function gui.Text()
    
end
function gui.Button()
    
end
---@endregion gui api

-- immediate mode GUI 
-- https://docs.rs/egui/latest/egui/
-- https://github.com/emilk/egui/blob/master/crates/egui_demo_lib/src/demo/toggle_switch.rs


callbacks.Register("Draw", function ()
    if gui.Button("Reload Script").clicked() then
        LoadScript(GetScriptName())
    end 
end)