local hasMenuLib, MenuLib = pcall( require, 'Menu' ) -- not a big fan of this library but it works nicely.
-- local hasMsgPack, MsgPack = pcall( require, 'msgpack' )
local hasJson, Json = pcall( require, 'json' )
local template = "\n* [%s] is missing, download and put the file in lmaobox lua folder:\n%s"
assert( hasMenuLib, template:format( template, 'Menu.lua', 'https://github.com/lnx00/Lmaobox-LUA/blob/main/Menu.lua' ) )
-- assert( hasMsgPack, string.format(template, 'msgpack.lua', 'https://github.com/kieselsteini/msgpack/blob/master/msgpack.lua') )
assert( hasJson, template:format( template, 'json.lua', 'https://github.com/rxi/json.lua/blob/master/json.lua' ) )

-- forward declare
local function guiUpdate()
end

local function pretty_json( json_text, line_feed, indent, ac )
    json_text = tostring( json_text )
    line_feed, indent, ac = tostring( line_feed or "\n" ), tostring( indent or "\t" ), tostring( ac or " " )

    local i, j, k, n, r, p, q = 1, 0, 0, #json_text, {}, nil, nil
    local al = string.sub( ac, -1 ) == "\n"

    for x = 1, n do
        local c = string.sub( json_text, x, x )

        if not q and (c == "{" or c == "[") then
            r[i] = p == ":" and (c .. line_feed) or (string.rep( indent, j ) .. c .. line_feed)
            j = j + 1
        elseif not q and (c == "}" or c == "]") then
            j = j - 1
            if p == "{" or p == "[" then
                i = i - 1
                r[i] = string.rep( indent, j ) .. p .. c
            else
                r[i] = line_feed .. string.rep( indent, j ) .. c
            end
        elseif not q and c == "," then
            r[i] = c .. line_feed
            k = -1
        elseif not q and c == ":" then
            r[i] = c .. ac
            if al then
                i = i + 1
                r[i] = string.rep( indent, j )
            end
        else
            if c == '"' and p ~= "\\" then
                q = not q and true or nil
            end
            if j ~= k then
                r[i] = string.rep( indent, j )
                i, k = i + 1, j
            end
            r[i] = c
        end
        p, i = c, i + 1
    end

    return table.concat( r )
end

-- region: serialization 
local function read( filename )
    local file = io.open( filename, "r" )
    if not file then
        return
    end
    local content = file:read( 'a' )
    file:close()
    return content
end
local function write( filename, mode, content )
    local file = io.open( filename, mode )
    local errmsg = file:write( content )
    file:close()
    return errmsg
end
-- todo
local function update( filename, content )
    return write( filename, 'a+', content )
end
local function overwrite( filename, content )
    return write( filename, 'w', content )
end
-- endregion:

MODE_HOLD = 1
MODE_TOGGLE = 2
MODE_RELEASE = 3

local scriptfolder = engine.GetGameDir():gsub( '[^\\/]+$', '' )
local menufont = menufont or {}
local sidefont = sidefont or
                     draw.CreateFont( 'Verdana', 25, 900, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE | FONTFLAG_ANTIALIAS )

local gui_path_text = {
    lower = {},
    upper = {},
    normal = {}
 }

local InputMap = {}
for i = 0, 9 do
    InputMap[i + 1] = tostring( i )
end
for i = 65, 90 do
    InputMap[i - 54] = string.char( i )
end

local dispatch_button_name = function( button )
    if button ~= nil then
        return InputMap[button]
    end
end

local extendGui
extendGui = { {
    path = 'backtrack',
    hotkey = KEY_0,
    mode = MODE_TOGGLE
    -- pressed = '' -- new shit
 }, {
    path = 'fake latency',
    hotkey = nil,
    mode = MODE_TOGGLE
 }, {
    path = 'anti aim',
    hotkey = nil,
    mode = MODE_TOGGLE
 }, {
    path = 'prefer medics',
    hotkey = nil,
    mode = MODE_TOGGLE
 } }

local datafilename = scriptfolder .. "menutoggle.json"
local content = read( datafilename )

if not content then
    overwrite( datafilename, pretty_json( json.encode( extendGui ) ) )
else
    extendGui = json.decode( content ) or extendGui
end

local keybinds = {}

callbacks.Register( "Draw", "do_input", function()
    for i, tbl in ipairs( extendGui ) do

        if not tbl.hotkey then
            goto continue
        end

        local button_pressed_tick, active = input.IsButtonPressed( tbl.hotkey )

        if not active then
            active = input.IsButtonDown( tbl.hotkey )
        end

        if tbl.mode == MODE_TOGGLE then
            if active and (tbl.button_pressed_tick >> 1) ~= button_pressed_tick then
                tbl.button_pressed_tick = (button_pressed_tick << 1) | (tbl.button_pressed_tick & 1 == 1 and 0 or 1)
                gui.SetValue( tbl.path, tbl.button_pressed_tick & 1 )
                goto continue
            end
        end

        if tbl.mode == MODE_HOLD then
            gui.SetValue( tbl.path, active and 1 or 0 )
            goto continue
        end

        if tbl.mode == MODE_RELEASE then
            gui.SetValue( tbl.path, active and 0 or 1 )
            goto continue
        end

        ::continue::
    end

    for i, v in ipairs( keybinds ) do
        extendGui[i].hotkey = v:GetValue() > 0 and v:GetValue() or nil
    end
end )

local window = MenuLib.Create( 'Keybind', MenuFlags.AutoSize | MenuFlags.NoTitle )
window:AddComponent( MenuLib.Label( "Keybind v0.1 - JSON" ) )
window:AddComponent( MenuLib.Label( datafilename ) )
window.Style.WindowBg = { 25, 25, 25, 225 }
window.Style.Space = 6
window.Style.Outline = true

window:AddComponent( MenuLib.Button( "Reload Script", function()
    local val = json.decode( read( datafilename ) )
    if type( val ) == 'table' then
        UnloadScript( GetScriptName() )
        LoadScript( GetScriptName() )
        print( "reloaded script." )
    end
end, ItemFlags.FullWidth ) )

window:AddComponent( MenuLib.Button( "Open Config File", function()
    os.execute( string.format( [[start "" %q]], datafilename ) )
end, ItemFlags.FullWidth ) )

local keyMap = {}

local function guiUpdate()
    for i, tbl in ipairs( extendGui ) do
        keyMap[tbl.path] = true
        gui_path_text.normal[i] = tbl.path
        gui_path_text.lower[i] = tbl.path:lower()
        gui_path_text.upper[i] = tbl.path:upper()
        tbl.button_pressed_tick = gui.GetValue( tbl.path ) == 1 and 0 or 1
        keybinds[i] = window:AddComponent( MenuLib.Keybind( tbl.path, tbl.hotkey ) )
    end
end
guiUpdate()

local subwindow = MenuLib.Create( 'Keybind Manager', MenuFlags.AutoSize | MenuFlags.Popup )
subwindow.X, subwindow.Y = 30, select(1, draw.GetScreenSize() // 2.5)
subwindow.Style.Space = 3
local showKeyBind = subwindow:AddComponent( MenuLib.MultiCombo( "Show", keyMap, ItemFlags.FullWidth ) )

callbacks.Register( "Draw", "on_draw", function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        -- return
    end

    local x, y = draw.GetScreenSize()
    draw.Color( 255, 255, 255, 255 )

    local lboxfont = gui.GetValue( "font" )
    local lboxUppercase = gui.GetValue( "font uppercase" ) ~= "off"
    local ref = gui.GetValue( "gui color" )
    menufont[lboxfont] = menufont[lboxfont] or draw.CreateFont( lboxfont, 12, 0, FONTFLAG_OUTLINE )
    MenuLib.Font = menufont[lboxfont]
    window.Style.TitleBg = { ref >> 24 & 0xFF, ref >> 16 & 0xFF, ref >> 8 & 0xFF, ref & 0xFF }
    subwindow.Style.TitleBg = { ref >> 24 & 0xFF, ref >> 16 & 0xFF, ref >> 8 & 0xFF, ref & 0xFF }

    draw.SetFont( menufont[lboxfont] )

    local offset = subwindow.Y + 25

    for i, tbl in ipairs( extendGui ) do
        local path = tbl.path
        if not showKeyBind:IsSelected( tbl.path ) then
            goto continue
        end
        local w, h = draw.GetTextSize( path )
        if gui.GetValue( path ) == 1 then
            draw.Color( 0, 255, 0, 255 )
        else
            draw.Color( 255, 255, 255, 255 )
        end
        draw.Text( subwindow.X, offset, lboxUppercase and path:upper() or path )
        draw.Text( subwindow.X - 25, offset, dispatch_button_name( tbl.hotkey ) or 'nil' )
        offset = offset + h
        ::continue::
    end

    --[[
    local ref = gui.GetValue( "gui color" )
    draw.Color( ref >> 24 & 0xFF, ref >> 16 & 0xFF, ref >> 8 & 0xFF, ref & 0xFF )
    draw.FilledRect( 20, y // 2 - 6, x // 2, y // 2 )
    draw.Color( 0, 0, 0, 200 )
    draw.FilledRect( 20, y // 2, x // 2, offset )]]

end )

callbacks.Register( "Unload", function()
    _G.menufont = menufont
    _G.sidefont = sidefont
    MenuLib.RemoveMenu( window )
    MenuLib.RemoveMenu( subwindow )
end )

