local char = string.char

-- Use the HSB to RGB conversion formula to convert to the appropriate format.
-- The range of the input parameters is H: [0, 100], S: [0, 100], B: [0, 100].
-- The range of all output values is [0, 255]
local function hsb_to_rgb( h, s, b )
    s, b = s / 100, b / 100
    local function k( n )
        return (n + h / 60) % 6
    end
    local function f( n )
        return math.abs( b * (1 - s * math.max( 0, math.min( k( n ), 4 - k( n ), 1 ) )) )
    end
    return math.floor( 255 * f( 5 ) ), math.floor( 255 * f( 3 ) ), math.floor( 255 * f( 1 ) )
end

local function map( value, start1, stop1, start2, stop2 )
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
end

local width, height = 2 ^ 8, 2 ^ 8
local pixels, pixels2 = {}, {}
local hue = 200
for i = 1, width do
    for j = 1, height do
        local sat = math.floor( map( i, 1, width, 100, 0 ) )
        local bri = math.floor( map( j, 1, height, 100, 0 ) )
        local r, g, b = hsb_to_rgb( hue, sat, bri )
        pixels[#pixels + 1] = char( r, g, b, 255 )
    end
end

local width2, height2 = 32, 2 ^ 8
for i = 1, width2 do
    for j = 1, height2 do
        local h, s, bri = math.floor( map( i, 0, width2, 0, 100 ) ) * 3.6, 100, 100
        local r, g, b = hsb_to_rgb( h, s, bri )
        pixels2[#pixels2+1] = char( r, g, b, 255 )
    end
end


local img1 = draw.CreateTextureRGBA( table.concat( pixels ), width, height )
local img2 = draw.CreateTextureRGBA( table.concat( pixels2 ), width2, height2 )

callbacks.Register( 'Draw', function()
    ---
    local w, h = draw.GetScreenSize()
    local w, h = w // 2, h // 2
    draw.Color( 255, 0, 0, 255 )
    -- draw.FilledRect( w, h, w + width, h + height )
    draw.Color( 255, 255, 255, 255 )
    draw.TexturedRect( img1, w, h, w + width, h + height )
    draw.TexturedRect( img2, w, h, w + width2, h + height2 )
end )
