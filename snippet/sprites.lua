---@region signature
--- This file is part of the lmaobox Scripting API.
--- @class module
local sprite
local renderer, texture = {}, {}
---@endregion

local function round(n)
    return math.floor(n + 0.5)
end

local function pow_of_two(height, width)
    local nheight, nwidth
    for i = 1, 32 do
        nwidth = (1 << i)
        if nwidth >= width then
            break
        end
    end
    for i = 1, 32 do
        nheight = (1 << i)
        if nheight >= width then
            break
        end
    end
    return nwidth, nheight
end

local function hsl_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l

    l = (max + min) / 2

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        if l > 0.5 then
            s = d / (2 - max - min)
        else
            s = d / (max + min)
        end
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

local function hsv_to_rgb(h, s, v) -- values in ranges: [0, 360], [0, 1], [0, 1]
    local r = math.min(math.max(3 * math.abs(((h) / 180) % 2 - 1) - 1, 0), 1)
    local g = math.min(math.max(3 * math.abs(((h - 120) / 180) % 2 - 1) - 1, 0), 1)
    local b = math.min(math.max(3 * math.abs(((h + 120) / 180) % 2 - 1) - 1, 0), 1)
    local k1 = (v * (1 - s)) * 255
    local k2 = v * 255 - k1
    return math.floor(k1 + k2 * r), math.floor(k1 + k2 * g), math.floor(k1 + k2 * b) -- values in ranges: [0, 1], [0, 1], [0, 1]
end

function texture.circle()

end

function texture.gradient_rect()

end

function texture.hsv_color_wheel(width, height, radius)
    width, height, radius = 256, 256, 127.5
    local cx, cy = width / 2, height / 2
    local t, pixel = {}, 1
    for x = 1, width do
        for y = 1, height do
            local dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= radius * radius then
                local h = math.deg(math.atan(dx, dy))
                local s = (dx * dx + dy * dy) ^ 0.5 / radius
                local v = 1
                local r, g, b = hsv_to_rgb(h, s, v)
                t[pixel] = string.char(r, g, b, 255)
            else
                t[pixel] = string.char(255, 255, 255, 0)
            end
            pixel = pixel + 1
        end
    end
    return draw.CreateTextureRGBA(table.concat(t), width, height)
end

function texture.hsv_color_slider(width, height)
    width, height = 256, 256
    local t, pixel = {}, 1
    for y = 1, height do
        local r, g, b = hsl_to_rgb(0, 0, 1 - y * (1 / height))
        for x = 1, width do
            t[pixel] = string.char(r, g, b, 255)
            pixel = pixel + 1
        end
    end
    return draw.CreateTextureRGBA(table.concat(t), width, height)
end

local id = texture.hsv_color_wheel()


callbacks.Register('Draw', function()
    draw.SetFont(21)
    local r, g, b = hsl_to_rgb(0.1, 1, 1)

    draw.Color(100, 100, 100, 255)
    draw.TexturedRect(id, 250, 250, 250 + 255, 250 + 255)

    -- draw.FilledRect(250, 250, 250 + 255, 250 + 255)

end)
