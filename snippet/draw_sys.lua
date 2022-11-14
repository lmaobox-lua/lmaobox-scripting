-- utilities
local e_parse, e_texture, e_input, e_color
-- library
local e_datafile, e_varstorage, e_config
local egui, e_api, e_const, e_element_list, e_renderable
local e_widget, e_window
-- classes
local e_VGUITexture, e_GuiObject, e_UNKConfigObject

-- external
local inspect = require "inspect"
local fs = {}
local json = require "dkjson"
local e_parse = require "parse"

---@alias texture
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

e_input.last_hit_point = {}
e_input.last_hit_point.x = nil
e_input.last_hit_point.y = nil
e_input.last_hit_point.x1 = nil
e_input.last_hit_point.y1 = nil
e_input.last_mouse_state = nil
e_input.last_recv = 0
e_input.timer = 0
e_input.next_dbl_click = 0
e_input.click_count = 0

function e_input.mouse_in_bound(self)
    local dx, dy, dw, dh
    local x, y, width, height
    dx, dy, dw, dh = input.GetMousePos()[1], input.GetMousePos[2], e_config.cursor.width, e_config.cursor.height
    x, y, width, height = self.x, self.y, self.width, self.height
    return ((dx + dw >= x) and (dx <= x + width) and (dy + dh >= y) and (y <= y + height));
end

function e_input.mouse_state(self)
    local just_click, inactive, jammed
    just_click = input.IsButtonPressed(self.key)
    inactive = input.IsButtonReleased(self.key)
    jammed = input.IsButtonDown(self.key)

    if e_input.timer < os.clock() then
        e_input.click_count = 0
    end

    if e_input.click_count > 1 and e_input.next_dbl_click < os.clock() + e_config.cursor.single_click_delay then
        e_input.next_dbl_click = os.clock() + e_config.cursor.single_click_delay
        e_input.last_mouse_state = "dblclick"
    end

    if jammed then
        if (e_input.last_mouse_state ~= "mousedown") then
            e_input.last_mouse_state = "mousedown"
            e_input.last_hit_point.x = input.GetMousePos()[1]
            e_input.last_hit_point.y = input.GetMousePos()[2]
            e_input.click_count = e_input.click_count + 1
            e_input.timer = os.clock() + e_config.cursor.single_click_delay
            return "mousedown"
        end
        return
    end

    if inactive then
        if (e_input.last_mouse_state ~= "mouseup") then
            e_input.last_mouse_state = "mouseup"
            e_input.last_hit_point.x1 = input.GetMousePos()[1]
            e_input.last_hit_point.y2 = input.GetMousePos()[2]
            return "mouseup"
        end
    end

    if e_input.last_hit_point.x1 == e_input.last_hit_point.x and e_input.last_hit_point.y1 == e_input.last_hit_point.y then
        if (e_input.last_mouse_state ~= "click") then
            e_input.last_mouse_state = "click"
            return "click"
        end
    end

end

function e_input.to_name(self)
    -- todo export this as seperate library
end

---@alias widget
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

function e_GuiObject.get_value()
end

function e_GuiObject.set_value()
    
end

function e_GuiObject.remove()
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
    single_click_delay = 0.3 -- in second(s)
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

e_api = {}
e_parse.shallow_copy(e_const, e_api)

function e_api.do_input()
    for k, v in pairs(e_renderable) do
        if e_renderable[k].event and e_input.in_bound(k) then

        end
    end
end

function e_api.do_render()
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
    e_control:add_event('on_click', function(e)
        e_control:set_value(not e_control:get_value())
    end)
    return e_control
end

print(inspect(e_api))

return e_api
