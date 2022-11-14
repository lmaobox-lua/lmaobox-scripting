LoadScript([[C:\Users\mayakey\AppData\Local\lbox\lua\luapath.lua]])
local luapath, where = require('luapath')
assert(package.loaded['luapath'])

local function HSVtoRGB(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function hsv_to_rgb(h, s, v) -- values in ranges: [0, 360], [0, 1], [0, 1]
    local r = math.min(math.max(3 * math.abs(((h) / 180) % 2 - 1) - 1, 0), 1)
    local g = math.min(math.max(3 * math.abs(((h - 120) / 180) % 2 - 1) - 1, 0), 1)
    local b = math.min(math.max(3 * math.abs(((h + 120) / 180) % 2 - 1) - 1, 0), 1)
    local k1 = (v * (1 - s)) * 255
    local k2 = v * 255 - k1
    return math.floor(k1 + k2 * r), math.floor(k1 + k2 * g), math.floor(k1 + k2 * b) -- values in ranges: [0, 1], [0, 1], [0, 1]
end

local function circle_color_picker(w, h, r, flag)
    local id
    local t, i = {}, 1
    w = w or 256
    h = h or 256
    r = r or 128 - 0.5
    --  x-axis coordinate of a center point
    --  y-axis coordinate of a center point
    local cx, cy = w / 2, h / 2
    for x = 1, w do
        for y = 1, h do
            local dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r * r then
                local h = math.deg(math.atan(dx, dy))
                local s = (dx * dx + dy * dy) ^ 0.5 / r
                local v = 1
                local r, g, b = hsv_to_rgb(h, s, v)
                t[i] = string.char(r, g, b, 255)
            else
                t[i] = string.char(255, 255, 255, 0)
            end
            i = i + 1
        end
    end
    id = draw.CreateTextureRGBA(table.concat(t), w, h)
    return id
end

local id = circle_color_picker()

callbacks.Register('Draw', function()
    draw.SetFont(21)
    draw.Color(255, 255, 255, 255)
    draw.TexturedRect(id, 250, 250, 250 + 256, 250 + 256)
end)
