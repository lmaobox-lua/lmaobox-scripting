local menuLib = {}
local guiFlags = {
    -- visibility logic
    SHOW_INGAME = 1 << 1,
    SHOW_ON_SCREENSHOT = 1 << 2, -- clean screenshots
    SHOW_ON_MAIN_MENU = 1 << 3,
    SHOW_ON_GAMEUI = 1 << 4, -- still show when obstructed by scoreboard ui, cancelselect..
    SHOW_ON_CONSOLEUI = 1 << 5,
    STYLE_SHOW_ALL = 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5,
    STYLE_SHOW = 1 << 1 | 1 << 3 | 1 << 4 | 1 << 5 ^ 1 << 2,

    -- element flags
    ELEM_AUTOSIZING = 1 << 1,
    ELEM_DRAGABLE = 1 << 2,
    ELEM_DPI_SCALE = 1 << 3,
    ELEM_CUSTOM_FONT = 1 << 4,

    -- element state
    STATE_INACTIVE = 1 << 0,
    STATE_NORMAL = 1 << 1,
    STATE_HOVER = 1 << 2,
    STATE_PRESS = 1 << 3
 }

for k, v in pairs( guiFlags ) do
    _G.k = v
end

local mouse1_active, cursor_x, cursor_y
local element_pressed_unique, window_pressed_unique

local menuLib_mt = {
    __index = {
        SetState = function()

        end,
        SetFont = function()

        end,
        Color = function()

        end,
        Begone = function()

        end
     }
 }

local menuLib_style = {
    Window = {
        background = '',
        border = '',
    }
}

local menuLib_control = {
    Window = function( elem_unique, text, flag, width, height )

    end,
    Button = function( text, width, height )

    end,
    Keybind = function( text, button )

    end,
    Label = function( text )

    end,
    Colorpicker = function( text )

    end, 
    overrideStyle = function( name )
        
    end
 }

menuLib.Unload = function()
    for k, v in pairs( guiFlags ) do
        _G.k = undef
    end
    STYLE_SHOW_ALL = undef
    STYLE_SHOW = undef
    UnloadScript( GetScriptName() )
end
return menuLib

