--- region: wrapper
local draw_SetFont = setmetatable( { nil }, {
    __call = function( self, font_id )
        if self[1] ~= font_id then
            draw.SetFont( font_id )
            self[1] = font_id
        end
    end
 } )

local draw_Color = setmetatable( { nil }, {
    __call = function( self, r, g, b, a )
        local rgba = (a & 0xFF) << 24 | (r & 0xFF) << 16 | (g & 0xFF) << 8 | (b & 0xFF)
        if self[1] ~= rgba then
            self[1] = rgba
            draw.Color( r, g, b, a )
        end
    end
 } )

--- region: font
local font_ids = {}
local function create_font( name, size, weight, flags )
    -- size [0, ..999] ≈ 0x3ff , weight [0, ..900] ≈ 0x3ff , flags [0, ..0xfff]
    flags = flags or FONTFLAG_CUSTOM | FONTFLAG_ANTIALIAS
    if not font_ids[name] then
        font_ids[name] = {}
    end
    local pckg = size << 22 | weight << 12 | flags
    if not font_ids[name][pckg] then
        font_ids[name][pckg] = draw.CreateFont( name, size, weight, flags )
    end
    return font_ids[name][pckg]
end

--- region: input
local virtual_key_poll = {}

---@link https://github.dev/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/public/inputsystem/InputEnums.h#L73
---@link https://github.dev/lua9520/source-engine-2018-hl2_src/blob/master/public/inputsystem/ButtonCode.h#L51
local virtual_key_codes = {
    ['char'] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
                 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3',
                 '4', '5', '6', '7', '8', '9', '/', '*', '-', '+', '\n', '.', '[', ']', ';', '\'', '`', ',', '.', '/',
                 '\\', '-', '=', '\n', ' ', '\b', '\t', '', '', '', '', '', '\b', '', '', '', '', '', '', '', '', '',
                 '', '', '', '', '', '', '', '', '', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11',
                 'f12', '', '', '' },
    ['key'] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
                'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'pad_0', 'pad_1', 'pad_2',
                'pad_3', 'pad_4', 'pad_5', 'pad_6', 'pad_7', 'pad_8', 'pad_9', 'pad_divide', 'pad_multiply',
                'pad_minus', 'pad_plus', 'pad_enter', 'pad_decimal', 'left bracket', 'right bracket', 'semicolon',
                'apostrophe', 'backquote', 'comma', 'period', 'slash', 'backslash', 'minus', 'equal', 'enter', 'space',
                'backspace', 'tab', 'capslock', 'numlock', 'escape', 'scrolllock', 'insert', 'delete', 'home', 'end',
                'pageup', 'pagedown', 'break', 'left shift', 'rshift', 'left alt', 'right alt', 'left control',
                'right control', 'left win', 'right win', 'app', 'up', 'left', 'down', 'right', 'f1', 'f2', 'f3', 'f4',
                'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12', 'capslock', 'numlock', 'scrolllock', 'mouse_left',
                'mouse_right', 'mouse_middle', 'mouse_4', 'mouse_5', 'mouse_wheel_up', 'mouse_wheel_down' }
 }

local function map_virtual_key( button, fmt )
    if not fmt then
        fmt = 'key'
    end
    return virtual_key_codes[fmt][button]
end

local function get_held_time( button )
    if not input.IsButtonDown( button ) then
        virtual_key_poll[button] = nil
        return 0
    end
    if not virtual_key_poll[button] then
        virtual_key_poll[button] = os.clock()
    end
    return os.clock() - virtual_key_poll[button]
end

local function hit_test( x, y, x1, y1, mx, my )
    if not mx or not my then
        mx, my = table.unpack( input.GetMousePos() )
    end
    return (mx >= x and mx <= x1) and (my >= y and my <= y1)
end

--- region: datafiles

local variables = {
    ['main'] = {
        ['about'] = {
            ['version'] = 0,
            ['author'] = 'Moonverse#9320'
         }
     }
 }
-- todo : get('main', 'about', 'version')

--- region: menu - core

-- todo : (high priority) re-positioning widget/container's element when a key is removed/edited/control's font/shape edited. (note nothing will adjust if user decided to mess with :positon() and :size() )
-- todo : (will do) include input / control states
-- todo : add optional_default_value as an argument before optional_font
-- todo : (low priority) improve button_name_map_jank
-- todo : include shape for controls, main window
-- todo : allow other user to define their custom style (color) , control (shape) in their userscript .. means other script wouldn't be affected
-- todo : (low priority) add cross script reference: add an ui path and another script can only get/set value
-- todo : label, button, hotkey, vertical-stack, horizontal-stack, check box, single & multiple drop-down , color picker, dividier (no value)
-- todo : set() and get() value for controls
-- todo : (low) textbox + menu command line interface using StringCmd

local function position( self, x, y )
    if x then
        self.x = x
    end
    if y then
        self.y = y
    end
    return self
end

local function size( self, width, height )
    if width then
        self.width = width
    end
    if height then
        self.height = height
    end
    return self
end

local function font( self, id )
    self.title.font = id
    return self
end

local function visible( self )

end

local function text( self, text )
    self.title.text = tostring( text )
    return self
end

local function color( self )
end

local function set( self )
end

local function get( self )
end

local function remove( self )

end

local state, style, shape

state = {
    normal = 1 << 1,
    focus = 1 << 2,
    selected = 1 << 3,
    hover = 1 << 4,
    pressed = 1 << 5,
    hidden = 1 << 6,
    offscreen = 1 << 7
 }

style = {
    -- LuaFormatter off
    ['default-dark'] = {
        ['border']        = 0,
        ['background']    = 0,
        ['text']          = 0,
        ['text-hover']    = 0,
        ['text-selected'] = 0,
        ['button']        = 0
     }
    -- LuaFormatter on
 }

shape = {
    -- LuaFormatter off
    ['menu'] = function( self ) 
        draw_Color      ( self.color )
        draw.FilledRect ( self.x, self.y, self.x1, self.y1 )
    end,
    ['label'] = function( self )
        draw_Color      ( self.text.color )
        draw_SetFont    ( self.text.font )
        draw.Text       ( self.text.x, self.text.y, self.text.str )
    end,
    ['button'] = function( self )
        draw_Color      ( self.color )
        draw.FilledRect ( self.x, self.y, self.x1, self.y1 )
        draw_Color      ( self.text.color )
        draw_SetFont    ( self.text.font )
        draw.Text       ( self.text.x, self.text.y, self.text.str )
    end
     -- LuaFormatter on
 }

local function render( self )
    local x, y = self.x, self.y
end

local function input( self )
    local x, y = table.unpack( input.GetMousePos() )

end

local control_mt = {
    position = position,
    size = size,
    font = font,
    text = text,
    visible = visible,
    color = color,
    get = get,
    set = set,
    input = input,
    render = render,
    remove = remove
 }

local function text( str, font )
    font = font or create_font( "Tahoma", 13, 400, FONTFLAG_DROPSHADOW )
    local text = {
        str = tostring( str ),
        font = font
     }
    return setmetatable( {}, {
        __index = text,
        __newindex = function( self, k, v )
            if text[k] and text[k] ~= v then
                text[k] = v
                draw_SetFont( text['font'] )
                self['wide'], self['tall'] = draw.GetTextSize( text['str'] )
            end
        end
     } )
end

local function vertical_stack( self, x, y, width, height )
    local stack = {
        x = x,
        y = y,
        x1 = x + width,
        y1 = y + height,
        width = width,
        height = height,
        map = {
            ['x'] = {},
            ['y'] = {}
         }
     }
    return setmetatable( {}, {
        __index = stack,
        __newindex = function( self, k, v )
            if stack[k] then

            else
                local i = #self
                stack.map['x'][i] = stack.map['x'][i - 1] + v['width']
                stack.map['y'][i] = stack.map['y'][i - 1] + v['height']
                v['x'] = stack.map['x'][i]
                v['y'] = stack.map['y'][i]
                self[i] = v
            end
        end
     } )
end

local menu_mt = setmetatable( {
    newdesign = 0,
    newstyle = 0,
    shareable = function( self, unique )
        variables:add( self )
    end,
    cursor = function( self, v )
        input.SetMouseInputEnabled( v )
    end,
    text = text,
    vertical_stack,
    vertical_stack
 }, {
    __index = control_mt
 } )

local function menu( self, title, x, y, width, height, _style )
    local menu = {
        title = text( title, font ),
        x = x,
        y = y,
        x1 = x + width,
        y1 = y + height,
        width = width,
        height = height,
        style = style['default-dark'],
        state = 0
     }
    setmetatable( menu, {
        __index = menu_mt,
        __close = function( self )
            -- delete reference
        end
     } )
    return menu
end

local function include( resource, val )
    if resource == 'style' then
        return
    end

    if resource == 'shape' then
        return
    end

    if resource == 'virtualkeymap' then
        return
    end
end

return setmetatable( {
    hit_test = hit_test,
    get_held_time = get_held_time,
    map_virtual_key = map_virtual_key,
    create_font = create_font,
    import = nil,
    export = nil,
    create = menu,
    reference = nil,
    remove = remove,
    include = include
 }, {
    __name = "Moonverse's Menu",
    __call = menu,
    __close = function( self )
        for k, v in pairs( package.loaded ) do
            if self == v then
                package.loaded[k] = nil
                UnloadScript( GetScriptName() )
            end
        end
    end
 } )
