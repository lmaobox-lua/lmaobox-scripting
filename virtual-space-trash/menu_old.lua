--- region: font
local fontids = {}
local function create_font( name, size, weight, flags )
    -- size [0, ..999] ≈ 0x3ff , weight [0, ..900] ≈ 0x3ff , flags [0, ..0xfff]
    flags = flags or FONTFLAG_CUSTOM | FONTFLAG_ANTIALIAS
    if not fontids[name] then
        fontids[name] = {}
    end
    local pckg = size << 22 | weight << 12 | flags
    if not fontids[name][pckg] then
        fontids[name][pckg] = draw.CreateFont( name, size, weight, flags )
    end
    return fontids[name][pckg]
end

--- region: input
local virtual_key_poll = {}

---@link https://github.dev/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/public/inputsystem/InputEnums.h#L73
---@link https://github.dev/lua9520/source-engine-2018-hl2_src/blob/master/public/inputsystem/ButtonCode.h#L51
local virtual_key_codes = {
    ['char'] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
                 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3',
                 '4', '5', '6', '7', '8', '9', '/', '*', '-', '+', '\n', '.', '[', ']', ';', '\'', '`', ',', '.', '/',
                 '\\', '-', '=', '\n', ' ', '\b', '\t', 'capslock', 'numlock', 'esc', 'scrolllock', 'insert', 'delete',
                 'home', 'end', 'pageup', 'pagedown', 'break', 'left shift', 'right shift', 'left alt', 'right alt',
                 'left control', 'right control', 'left windows', 'right windows', 'app', 'up', 'left', 'down', 'right',
                 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12', 'capslock', 'numlock',
                 'scrolllock' }
 }

local function map_virtual_key( button, fmt )
    if not fmt then
        fmt = 'char'
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

local function hit_test( x1, y1, x2, y2, x, y )
    if not x or not y then
        x, y = table.unpack( input.GetMousePos() )
    end
    return (x >= x1 and x <= x2) and (y >= y1 and y <= y2)
end

--- region: menu - core

-- todo : return mouse cursor to user when menu hit_test == false 
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

local function remove( self )

end

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

local function font( self, fontid )
    self.title.font = fontid
    return self
end

local function text( self, text )
    self.title.text = tostring( text )
    return self
end

local function style( self, style )
    self.style = style
    return self
end

local function set_cursor( self, enable )
    input.SetMouseInputEnabled( enable )
end

---
--- shape
--- 

-- todo: should this be metatable?
local widget_renderer = {
    ['button'] = function( self )
        draw.SetFont( self.title.font )
        draw.Text( self.x, self.y, self.title.text )
    end,
    ['label'] = function( self )
        draw.SetFont( self.title.font )
        draw.Text( self.x, self.y, self.title.text )
    end
 }

--- 
--- color, spacing 
---
local style = {
    ['menu'] = {
        background = { 30, 30, 30, 200 },
        widget_y_offset = 4,
        text = { 255, 255, 255, 255 }
     }
 }
for k, t in pairs( style ) do
    for k, v in pairs( t ) do
        if type( v ) == 'table' then
            setmetatable( t[k], {
                __index = {
                    apply = function( self )
                        draw.Color( table.unpack( self ) )
                    end
                 }
             } )
        end
    end
end

---
--- generic ui state
--- 
local state = {
    normal = 1 << 1,
    focus = 1 << 2,
    selected = 1 << 3,
    hover = 1 << 4,
    pressed = 1 << 5,
    hidden = 1 << 6,
    offscreen = 1 << 7
 }

local function render( self )
    local x, y, width, height, style = self.x, self.y, self.width, self.height, self.style['menu']
    style.background:apply()
    draw.FilledRect( x, y, x + width, y + height )
    style.text:apply()
    draw.SetFont( self.title.font )
    draw.Text( x, y, self.title.text )
    -- self.widget_renderer['menu']( self )
    local addx, addy = x + 5, y + self.title.tall + 4
    for i, self in ipairs( self.widget ) do
        draw.SetFont( self.title.font )
        draw.Text( self.x, self.y, self.title.text )
    end
end

local function input( self )
    for i, self in ipairs( self.widget ) do
        -- do hit test

        -- if menu open and a MOUSE1 is registered, save mousepos
    end
end

-- todo : render and input should not be here?
local component = {
    position = position,
    size = size,
    font = font,
    text = text,
    remove = remove,
    render = render,
    input = input
 }

---
--- proxy table
---
local function text_mt( title, optional_font )
    optional_font = optional_font or create_font( "Verdana", 16, 600, 0x200 )
    -- LuaFormatter off
    local text_obj = { text = tostring(title), font = optional_font }
    local proxy = {} 
    draw.SetFont( optional_font )
    text_obj['wide'], text_obj['tall'] = draw.GetTextSize( text_obj['text'] )
    -- LuaFormatter on
    setmetatable( proxy, {
        __index = text_obj,
        __newindex = function( self, k, v )
            if k == 'font' or k == 'text' then
                -- wonder if there's a better solution, like using key table again?
                if text_obj[k] == v then
                    return
                end
                text_obj[k] = v
                draw.SetFont( text_obj['font'] )
                -- todo: change this to wide, tall
                text_obj['wide'], text_obj['tall'] = draw.GetTextSize( text_obj['text'] )
            end
        end,
        __pairs = function( self )
            local k
            return function( t, k )
                local v
                k, v = next( t, k )
                if nil ~= v then
                    return k, v
                end
            end, text_obj, nil
        end
     } )
    return proxy
end

local function container_mt( self, x, y )
    local container_obj = {
        x = x,
        y = self.title.tall + y
     }
    local container_mt = {}
    setmetatable( container_mt, {
        __index = container_obj,
        __newindex = function( self, k, v )
            -- k == 1 or item > k
            if container_obj[k] and v ~= nil then
                -- how do i modify x and y without cancer
                -- if we remove the first element, we must set position as base
                -- if we remove the n element, set position as n  (n.y - n.title.tall)
            end
            if container_obj[k] and v == nil then
                container_obj[k] = nil
                return
            end
            if k ~= 'x' or k ~= 'y' then
                -- todo: recalc if value is deleted (nil)
                container_obj[k] = v
                container_obj[k]['x'] = container_obj['x']
                container_obj[k]['y'] = container_obj['y']
                container_obj['y'] = container_obj['y'] + container_obj[k].title['tall']
            end
        end,
        __len = function()
            return #container_obj
        end
     } )
    return container_mt
end

---
--- control template 
---

-- todo: add approximate X and approximate Y
local function label_t( self, title, optional_font )
    local new = {
        title = text_mt( title, optional_font ),
        state = 0
     }
    setmetatable( new, {
        __index = component
     } )
    table.insert( self.widget, new )
    return new
end

local function button_t( self, title, width, height, optional_font, ... )
    local new = {
        title = text_mt( title, optional_font ),
        state = 0
     }
    setmetatable( new, {
        __index = component
     } )
    table.insert( self.widget, new )
    return new
end

local control = {
    button = button_t,
    label = label_t
 }

-- todo: add default_value before optional_font

local function menu_open_share_reference( allowed )

end

-- kinda wanted the title text to have a logo color then white text game name and in the right corner is date since release build
-- Bless dead game                                                    2d | 3:53 AM
-- What a bless you don't waste time coding this shit for a dead game 
-- todo : remove title argument, call it unique instead (which mean you handle menu style) and unique is used as id
local function menu( self, title, x, y, width, height, optional_font )
    -- LuaFormatter off
    local new = { title = text_mt( title, optional_font ), x = x, y = y, width = width, height = height, style = style , state = 0 }
    new.widget = container_mt( new, x, y )
    -- LuaFormatter on
    local clone = {}
    for k, v in pairs( component ) do
        clone[k] = v
    end
    for k, v in pairs( control ) do
        clone[k] = v
    end
    setmetatable( new, {
        __index = clone,
        __close = function( self )
        end
     } )
    return new
end

callbacks.Unregister( 'SendStringCmd', '' )
callbacks.Register( 'SendStringCmd', '', function()
end )

return setmetatable( {
    hit_test = hit_test,
    get_held_time = get_held_time,
    map_virtual_key = map_virtual_key,
    create_font = create_font,
    import = nil,
    export = nil,
    create = menu,
    remove = remove
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
