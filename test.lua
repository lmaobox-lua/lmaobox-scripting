--[[local function interp( s, tab )
    return (s:gsub( s, function( w )
        print("hi")
        for i, s1 in pairs( tab ) do
            local idx0, idx1 = 0, 0
            if type( s1 ) == 'string' then
                local substr_find, replace_with
                substr_find = s1:match( '[^:]+' )
                replace_with = s1:sub( #substr_find + 2, #s1 )
                s = s:gsub( substr_find, function( match )
                    if s:find( match ) > idx1 then
                        idx0, idx1 = s:find( match )
                        return replace_with
                    end
                    return match
                end )
            end
        end
        return s
    end ))
end
getmetatable( '' ).__mod = interp

local name = 'blue hello world world?'
print( name % { 'hello:xd', 'world:\x01->%1<-\x02', 'world:big shit' } )
local expect = 'hello ->world<- big shit'
-- broken]]

local function parseRawImage( binary, maxlen )
    for cur = 1, maxlen do
        binary:sub(cur, cur)
    end
end



local filename = engine.GetGameDir() .. '\\raw.data'
local rawImage = io.open( filename, 'rb' )
local content = rawImage:read( 'a' )
rawImage:close()
local image1 = draw.CreateTextureRGBA( content, 1024, 1024 )
local a  = string.char(
                       255, 255, 255, 255,
                       0, 0, 0, 255,
                       0, 0, 0, 255,
                       0, 0, 0, 255,
                       0, 0, 0, 255,
                       0, 0, 0, 255,
                       255, 255, 255, 255,
                       0, 0, 0, 255,
                       0, 0, 0, 255
                    )

local image2 = draw.CreateTextureRGBA( a, 3, 3)
callbacks.Register( 'Draw', function()
    local w, h = draw.GetScreenSize()
    draw.Color( 255, 255, 255, 255 )
    -- draw.TexturedRect( image1, 0, 0, 200, 200 )
    draw.TexturedRect( image2, w // 2, h // 2, w // 2 + 3, h // 2 + 3 )
end )

--[[
     Image* Create8888Image() const
    {
        uint32 size = 512;
        Image* img = Image::Create(size, size, FORMAT_RGBA8888);
        uint8* _date = img->data;
        for (uint32 i1 = 0; i1 < size; ++i1)
        {
            uint8 blue = 0xFF * i1 / size;
            for (uint32 i2 = 0; i2 < size; ++i2)
            {
                *_date++ = 0xFF * i2 / size; // R channel, 0 to FF horizontally
                *_date++ = 0x00; // G channel
                *_date++ = blue; // B channel, 0 to FF vertically
                *_date++ = 0xFA; // A channel
            }
        }
        return img;
    }

    Image* Create888Image() const
    {
        uint32 size = 512;
        Image* img = Image::Create(size, size, FORMAT_RGB888);
        uint8* _date = img->data;
        for (uint32 i1 = 0; i1 < size; ++i1)
        {
            uint8 blue = 0xFF * i1 / size;
            for (uint32 i2 = 0; i2 < size; ++i2)
            {
                *_date++ = 0xFF * i2 / size; // R channel, 0 to FF horizontally
                *_date++ = 0x00; // G channel
                *_date++ = blue; // B channel, 0 to FF vertically
            }
        }
        return img;
    }
]]
