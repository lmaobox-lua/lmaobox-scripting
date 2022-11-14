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
            if dx * dx + dy * dy <= r * r then
                local h = math.deg(math.atan(dx, dy))
                local s = (dx * dx + dy * dy) ^ 0.5 / r
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


