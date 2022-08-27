--- region: font
local fontids = {}
local function create_font( name, height, weight, flags )
    flags = flags or FONTFLAG_CUSTOM | FONTFLAG_ANTIALIAS
    if not fontids[name] then
        fontids[name] = {}
    end
    local pckg = string.pack( 'HHH', height, weight, flags )
    if not fontids[name][pckg] then
        fontids[name][pckg] = draw.CreateFont( name, height, weight, flags )
    end
    return fontids[name][pckg]
end

--- region: input
local buttontime = {}
local button_name_map_jank = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
                               'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                               '1', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '/', '*', '-', '+', '\n', '.', '',
                               '', ';', '', '', '\\' }
local function get_key_name( button )
    return button_name_map_jank[button]
end
local function get_held_time( button )
    if not input.IsButtonDown( button ) then
        buttontime[button] = nil
        return 0
    elseif not buttontime[button] then
        buttontime[button] = os.clock()
    end
    return os.clock() - buttontime[button]
end

local function hit_test( x1, y1, x2, y2, x, y )
    if not x or not y then
        x, y = table.unpack( input.GetMousePos() )
    end
    return (x >= x1 and x <= x2) and (y >= y1 and y <= y2)
end

--- region: menu - shared variables

--- todo: It's not possible yet, But soon it will (!?)
local variable_shared = {}
local variable_shared_proxy = setmetatable( variable_shared, {
    -- __call = 0,
    __index = variable_shared,
    __newindex = function( self, k, v )

    end
 } )

local function add_shared_item( path )
end

local function reference()
end

--- region: menu - core

local function remove( self )
    for k in next, self, nil do
        rawset( self, k, nil )
    end
    return true -- status
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

local widget_renderer = {
    ['button'] = function( self )

    end,
    ['label'] = function( self )

    end
 }

--- todo, make this easier to use next update.
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

local state = {
    normal = 1 << 1,
    hidden = 1 << 2,
    out_of_bound = 1 << 3,
    hovered = 1 << 4,
    interacted = 1 << 5
 }

local function render( self )
    local x, y, width, height, style = self.x, self.y, self.width, self.height, self.style['menu']
    style.background:apply()
    draw.FilledRect( x, y, x + width, y + height )
    style.text:apply()
    draw.SetFont( self.title.font )
    draw.Text( x, y, self.title.text )

    local addx, addy = x + 5, y + self.title.height + 4
    for i, self in ipairs( self.widget ) do
        draw.SetFont( self.title.font )
        draw.Text( addx, addy, self.title.text )
        addx, addy = addx, addy + self.title.height + 4
    end
end

local function input( self )
    for i, self in ipairs( self.widget ) do

    end
end

local component = {
    position = position,
    size = size,
    font = font,
    text = text,
    reference = reference,
    remove = remove,
    render = render,
    input = input
 }

--- main menu
local function text_mt( title, optional_font )
    optional_font = optional_font or create_font( "Verdana", 16, 600, 0x200 )
    -- LuaFormatter off
    local text_obj = { text = title, font = optional_font, width = -1, height = -1 }
    local text_mt = setmetatable( {}, {
        __index = text_obj,
        __newindex = function( self, k, v )
            if k == 'font' or k == 'text' then
                text_obj[k] = v
                draw.SetFont( text_obj['font'] )
                text_obj['width'], text_obj['height'] = draw.GetTextSize( text_obj['text'] )
            end
        end
    })
    -- LuaFormatter on
    return text_mt
end

-- incorperate with menu....
local function label( self, title, optional_font )
    local new = {
        title = text_mt( title, optional_font ),
        state = 0
     }
    setmetatable( new, {
        __name = "label",
        __index = component
     } )
    table.insert( self.widget, new )
    return new
end

local function button( self, title, width, height, optional_font, ... )
    local new = {
        title = text_mt( title, optional_font ),
        state = 0
     }
    setmetatable( new, {
        __name = 'button',
        __index = component
     } )
    table.insert( self.widget, new )
    return new
end

local control = {
    button = button,
    label = label
 }

local function menu( self, title, x, y, width, height, optional_font )
    -- LuaFormatter off
    local new = { title = text_mt( title, optional_font ), x = x, y = y, width = width, height = height, style = style , state = 0, widget = { x = 0, y = 0 } }
    -- LuaFormatter on
    --- todo: Fix code design
    setmetatable( new.widget, {
        __ipairs = function( self, index )

        end,
     } )
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
            -- only used to delete shared variable and it's.
        end
     } )
    return new
end

return setmetatable( {
    create_font = create_font,
    create = menu,
    remove = remove,
    hit_test = hit_test,
    get_held_time = get_held_time,
    get_key_name = get_key_name
 }, {
    __name = "Moonverse's Menu",
    __call = menu,
    __index = {
        dereference = function( self )
            for k, v in pairs( package.loaded ) do
                if self == v then
                    package.loaded[k] = nil
                    return UnloadScript( GetScriptName() )
                end
            end
        end
     }
 } )

-- for me when i get enough sleep : the code positioning is kind of retarded, fix it, and get more sleep.
