-- This script will override some menu options, use at risks
local daFont = draw.CreateFont( 'Small Fonts', 12, 500, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE )
local hasMenuLib, MenuLib = pcall( require, 'Menu' ) -- mfw too lazy for own ui
local hasMsgPack, MsgPack = pcall( require, 'msgpack' )
assert( hasMenuLib,
        '\n* [Menu.lua] is missing, download and put the file in lmaobox lua folder:\nhttps://github.com/lnx00/Lmaobox-LUA/blob/main/Menu.lua ' )
assert( hasMsgPack,
        '\n* [msgpack.lua] is missing, download and put the file in lmaobox lua folder:\nhttps://github.com/kieselsteini/msgpack/blob/master/msgpack.lua' )

-- TODO : rewrite this so i can understand
-- m_ButtonPressedTick
MODE_HOLD = 1
MODE_TOGGLE = 2
MODE_RELEASE = 3
local hotkey_codes, hotkey_pressed_tick = {}, {}

local function unregister_hotkey( button )
    hotkey_codes[button] = nil
    hotkey_pressed_tick[button] = nil
end

local function register_hotkey( button, inputstate, active )
    hotkey_codes[button] = inputstate or MODE_HOLD
    hotkey_pressed_tick[button] = (active == true or active == 1 or active == 'on') and 0 or 1
end

local function is_hotkey_active( button )
    if not button then
        return
    end

    local inputstate, packed = hotkey_codes[button], hotkey_pressed_tick[button]
    local button_pressed_tick, being_press = input.IsButtonPressed( button )
    being_press = input.IsButtonDown( button ) -- waiting for fix from bf.

    if inputstate == MODE_HOLD then
        return being_press
    end

    if inputstate == MODE_RELEASE then
        return not being_press
    end

    if inputstate == MODE_TOGGLE then
        if (packed >> 1) ~= button_pressed_tick then
            hotkey_pressed_tick[button] = (button_pressed_tick << 1) | (packed & 1 == 0 and 1 or 0)
        end
    end

    return (hotkey_pressed_tick[button] & 1) -- == 1
end

local filename = engine.GetGameDir() .. '\\..\\lol.msgpack' -- for some reason toggle.msgpack doesn't work and i gone a bit crazyz with dje code
local file = io.open( filename, 'r' )
local content = MsgPack.decode_one( file and file:read( 'a' ) or nil )

local gui_path = content or {
    ['backtrack'] = KEY_NONE,
    ['fake latency'] = KEY_NONE,
    ['anti aim'] = KEY_NONE,
    ['prefer medics'] = KEY_NONE
 }

local menu = MenuLib.Create( 'KEYBIND', MenuFlags.AutoSize )
local h, w = draw.GetScreenSize()
menu:SetPosition( h // 4, w // 4 )
menu:AddComponent( MenuLib.Label( 'Backup your lmaobox config before trying out.' ) )
menu:AddComponent( MenuLib.Label( string.format( 'datafile: %s', filename ) ) )

local keyBindInstance, keyBindCached = {}, {}
for path, button in pairs( gui_path ) do
    table.insert( keyBindInstance, menu:AddComponent( MenuLib.Keybind( path, button ) ) )
end

local textbox = menu:AddComponent( MenuLib.Textbox( 'gui path' ) )

menu:AddComponent( MenuLib.Button( 'Add', function()
    if #textbox:GetValue() > 2 then
        table.insert( keyBindInstance, menu:AddComponent( MenuLib.Keybind( textbox:GetValue(), KEY_NONE ) ) )
        gui_path[textbox:GetValue()] = KEY_NONE
        local datafile = io.open( filename, 'w' )
        datafile:write( MsgPack.encode_one( gui_path ) )
        textbox:SetValue( '' )
    end
end ) )
menu:AddComponent( MenuLib.Button( 'Remove', function()
    menu:RemoveComponent( keyBindInstance[#keyBindInstance] )
    table.remove( keyBindInstance )
    table.remove( gui_path )
    local datafile = io.open( filename, 'w' )
    datafile:write( MsgPack.encode_one( gui_path ) )
end ) )

callbacks.Register( 'Draw', function()

    draw.SetFont( daFont )

    local w, h = draw.GetScreenSize()
    local midW, midH = w // 2, h // 2 + 30
    local offset = midH

    for i, Keybind in ipairs( keyBindInstance ) do
        local val = Keybind:GetValue()
        if val == 0 then
            goto continue
        end
        if keyBindCached[i] ~= val then
            if keyBindCached[i] then
                unregister_hotkey( keyBindCached[i] )
            end

            register_hotkey( val, MODE_TOGGLE, gui.GetValue( Keybind.Label ) )
            keyBindCached[i] = val
        end

        local keystate = is_hotkey_active( val )
        if keystate then
            gui.SetValue( Keybind.Label, keystate )
            draw.Color( 255, 255, 255, 255 )
            if gui.GetValue( Keybind.Label ) == 1 then
                draw.Color( 0, 255, 0, 255 )
            end

            local textW, textH = draw.GetTextSize( Keybind.Label )
            draw.Text( 50, offset, Keybind.Label )
            offset = offset + select( 2, draw.GetTextSize( Keybind.Label ) )
        end
        ::continue::
    end

end )

callbacks.Register( 'Unload', function()
    -- Remove our menu before unloading the script
    MenuLib.RemoveMenu( menu )
end )
