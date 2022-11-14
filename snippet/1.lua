---@class color
e_color = {}

function e_color.guess()
end

function e_color.rgba(red, green, blue, alpha)

end

---
function e_GuiObject.set_text( value )

end

function e_GuiObject.set_description( value )

end

function e_GuiObject.set_open_key(value)
end

function e_GuiObject.set_pos( x, y )
end

function e_GuiObject.set_size( width, height )
end



--- 

function egui.render()
    for k, v in pairs(e_renderable) do
        e_GuiObject.draw(e_renderable)
    end
end

-- todo
local e_api = {}
function e_api.texture(pathOrRGBA888Data, width, height)
    local texture_id
    if not (width and height) then
        texture_id = draw.CreateTexture(pathOrRGBA888Data)
    else
        texture_id = draw.CreateTextureRGBA(pathOrRGBA888Data, width, height)
    end
    assert(texture_id)
    e_api.new(e_texture.new(texture_id, draw.GetTextureSize(texture_id)), "EGUI.Texture")
end

function e_api.button(parent, name, callback)
end

function e_api.checkbox(parent, varname, name, value)
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

-- todo
function e_api.multibox(parent, name)
end

-- todo
function e_api.reference( path )
end

function e_api.slider(parent, varname, value, min, max, step)
end

-- todo
function e_api.tab(parent, varname, name)
end

function e_api.window(varname, name, x, y, height, flags)
end

function e_api.text(parent, text)
end

-- todo
function e_api.xml()
end


local e_api = {}
function e_api.datafile(filename)
    local jsondata, contents
    contents = fs.read(filename)
    if #contents > 0 then
        jsondata = json.decode(contents)
    else
        jsondata = json.encode( )
    end
    print("Cannot find file: ", filename)
    return
end