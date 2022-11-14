-- external
local fs = require "filewrap"
local json = require "dkjson"
-- utilities
local e_parse, e_texture, e_input, e_color
-- library
local e_datafile, e_varstorage, e_config
local egui, e_api, e_const, e_element_list, e_renderable
local e_widget, e_window
-- classes
local e_VGUITexture, e_GuiObject, e_UNKConfigObject

---@alias parse
e_parse = {}

function e_parse.C_to_boolean(value)
    return (value ~= 0 and value) and 1 or 0
end

--- shallow copy table keys to another table
---@param from table
---@param to   table
---@return boolean
function e_parse.shallow_copy(from, to)
    for k, v in pairs(from) do
        to[k] = v
    end
    return true
end

--- construct a keytable value with value
---@param size number
---@param ...  any
function e_parse.va_list(size, ...)
    local arg = {...}
    local t = {}
    for i = 1, size do
        t[arg[math.ceil(size / 2) + i + 1] or i] = arg[i]
    end
    return t
end

--- pack 4 unsigned bytes to unsigned int
---@param byte number
---@param byte number
---@param byte number
---@param byte number
function e_parse.uint32(...)
    local arg = {...}
    local u32 = 0
    local size = 4
    for i = 1, size, 1 do
        u32 = u32 | (arg[i] & 0xff) << (size - i) * 8
    end
    return u32
end

--- unpack unsigned int to 4 unsigned bytes
--- @param u32 number
function e_parse.to_byte(u32)
    local arg = {}
    local size = 4
    for i = size, 1, -1 do
        table.insert(arg, u32 >> ((size - i) * 8))
    end
    return arg
end

---@alias texture
---@class e_VGUITexture
e_texture = {}
e_VGUITexture = {}

function e_texture.pow_of_two(height, width)
    local nheight, nwidth
    for i = 1, 32 do
        nwidth = (1 << i)
        if nwidth >= width then
            break
        end
    end
    for i = 1, 32 do
        nheigh = (1 << i)
        if nheight >= width then
            break
        end
    end
    return nwidth, nheight
end

---
---@param texture_id number
---@param width number
---@param height number
---@return e_VGUITexture
function e_texture.new(texture_id, width, height)
    local self = {
        texture_id = texture_id,
        width = width,
        height = height,
        uint32_color = 0xffffffff
    }
    setmetatable(self, {
        __index = {
            material = assert(materials.Find("__vgui_texture_" .. self.texture_id)),
            delete = e_VGUITexture.delete,
            coord = e_VGUITexture.coord,
            set_material_var_flag = e_VGUITexture.set_material_var_flag,
            set_shader_param = e_VGUITexture.set_shader_param
        }
    })
end

function e_VGUITexture.delete(self)
    return draw.DeleteTexture(self.texture_id)
end

function e_VGUITexture.coord(self, x, y)
    return x, y, self.width + x, self.height + y
end

function e_VGUITexture.set_material_var_flag(self, flag, set)
    return self.material:SetMaterialVarFlag(flag, set)
end

function e_VGUITexture.set_shader_param(self, param, value)
    return self.material:SetShaderParam(param, value)
end

---@alias input
e_input = {}

e_input.timer = 0
e_input.click_count = 0

function e_input.mouse_in_bound(self)
    local mx, my, width, height
    mx, my = input.GetMousePos()
    width, height = e_config.cursor.width, e_config.cursor.height
    return ((mx + width >= self.x) and (mx <= self.X + self.width) and (my + height >= self.Y) and
               (my <= self.y + self.height));
end

function e_input.mouse_state(self)
    local just_click, inactive, jammed
    just_click = input.IsButtonPressed(self.key)
    inactive = input.IsButtonReleased(self.key)
    jammed = input.IsButtonDown(self.key)

    if not input.IsMouseInputEnabled() then
        return "disabled"
    end

    if just_click then
        if e_input.timer < os.clock() + e_const.cursor.single_click_delay then
            e_input.timer = os.clock() + e_const.cursor.single_click_delay
        end
        e_input.click_count = e_input.click_count + 1
        if e_input.click_count == 1 then
            return "singleclick"
        else
            e_input.click_count = 0
            return "doubleclick"
        end
    end

    if e_input.timer < os.clock() + e_const.cursor.single_click_delay then
        e_input.click_count = 0
    end

    if inactive then
        return "released"
    end

    if jammed then
        return "held"
    end
end

---@alias widget
---@class e_GuiObject
e_widget = {}
e_GuiObject = {}

function e_GuiObject.get_color(self)
    return e_parse.va_list(4, e_parse.to_byte(self.uint32_color), "red", "green", "blue", "alpha")
end

function e_GuiObject.set_color(self, ...)
    local new_color = e_parse.uint32({...})
    local alpha = e_parse.va_list(4, e_parse.to_byte(new_color))[4]
    if not alpha then
        return
    end
    self.uint32_color = new_color
    e_GuiObject.set_invisible(self, (alpha <= 0))
end

function e_GuiObject.get_name(self)
    return self.name
end

function e_GuiObject.set_name(self, value)
    self.name = value
end

function e_GuiObject.set_invisible(self, value)
    if value then
        -- e_renderable
    end
end

function e_GuiObject.remove()
end

---
--- renderer
--- 
function e_widget.draw(self)
    return e_widget[self.type](self)
end

function e_widget.texture(self)

end

---@alias enum
e_const = {}

e_const.window = {
    Default = 0,
    DragInBackground = 1 << 0,
    NoDrag = 1 << 1,
    NoTitle = 1 << 2,
    NoDpiScale = 1 << 3
}

e_const.run_mode = {
    Reactive = 0,
    Continous = 1
}

---@alias config
--- different between each script
e_config = {}

e_config.window = {
    normal = e_const.window.Default,
    width = 704,
    height = 576
}

e_config.run_mode = e_const.run_mode.reactive
e_config.need_refresh_delay = 1 -- in second(s)

e_config.cursor = {
    width = 50,
    height = 50,
    single_click_delay = 0.4 -- in second(s)
}

e_config.widget_color = {
    ["text active"] = e_parse.uint32(255, 255, 255, 255),
    ["text inactive"] = e_parse.uint32(235, 235, 228, 255)
}

---@alias interface
egui = {}

e_element_list = {
    id = 0
}

e_api = {
    _AUTHOR = "Moonverse",
    _VERSION = 1,
    _NAME = "isurface gui for Lmaobox (L stands for loser)"
}
e_parse.shallow_copy(e_const, e_parse)

function e_api.input()
    for k, v in pairs(e_renderable) do
        if e_renderable[k].event and e_input.in_bound(k) then

        end
    end
end

function e_api.render_with_debug()
    local count, now
    count = 0
    now = os.clock()
    for k, v in pairs(e_renderable) do
        e_widget.draw(k)
        count = count + 1
    end
    return count, os.clock() - now
end

function e_api.register_ui_callback(varname)
end

function e_api.reference(varname)

end

function egui.new(parent, group, value)
    if not e_element_list[parent] then
        e_element_list[parent] = {}
    end
    if not e_element_list[parent][group] then
        e_element_list[parent][group] = {}
    end
    e_element_list.id = e_element_list.id + 1
    table.insert(e_element_list[parent][group], value)
    return e_element_list.id
end

function e_api.button(parent, name, callback)
    local e_control = egui.new(parent, "egui.button", name)
    e_control:add_event('on_click', callback)
    return e_control
end

function e_api.checkbox(parent, varname, name, value)
    local e_control = egui.new(parent, "egui.button", name)
    local keyvalue = e_datafile.find(name)
    if not keyvalue then
        e_datafile.new(name, value)
    else
        e_control:set_value(value)
    end
    e_control:add_event('on_click')
    return e_control
end

function e_api.colorpicker(parent, varname, name, red, green, alpha)
end

function e_api.editbox(parent, varname, value)
end

function e_api.groupbox(parent, name, x, y, width, height)
end

function e_api.keybox(parent, varname, name, vgui_key)
end

function e_api.listbox(parent, varname, height, options)
end

function e_api.multibox(parent, name)
end

function e_api.reference(path)
end

function e_api.slider(parent, varname, value, min, max, step)
end

function e_api.tab(parent, varname, name)
end

function e_api.window(varname, name, x, y, height, flags)
end

function e_api.text(parent, text)
end

function e_api.xml(value)
end

return e_api
