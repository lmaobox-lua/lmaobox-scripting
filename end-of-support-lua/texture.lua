local struct = require "struct"
local unpack = unpack or table.unpack

local struct_buffer_mt = {
    __index = {
        seek = function( self, seek_val, seek_mode )
            if seek_mode == nil or seek_mode == "CUR" then
                self.offset = self.offset + seek_val
            elseif seek_mode == "END" then
                self.offset = self.len + seek_val
            elseif seek_mode == "SET" then
                self.offset = seek_val
            end
        end,
        unpack = function( self, format_str )
            local unpacked = { struct.unpack( format_str, self.raw, self.offset ) }

            if self.size_cache[format_str] == nil then
                self.size_cache[format_str] = struct.pack( format_str, unpack( unpacked ) ):len()
            end
            self.offset = self.offset + self.size_cache[format_str]

            return unpack( unpacked )
        end
     }
 }

local function struct_buffer( raw )
    return setmetatable( {
        raw = raw,
        len = raw:len(),
        size_cache = {},
        offset = 1
     }, struct_buffer_mt )
end

local function parseRawImage( binary, width )
    local bin, data = struct_buffer( binary ), {}
    repeat
        data[#data + 1] = bin:unpack( 'I' )
    until (bin.offset >= bin.len)
    return data
end

local filename = engine.GetGameDir() .. '\\raw.data'
local rawImage = io.open( filename, 'rb' )
local content = rawImage:read( 'a' )
rawImage:close()

local image1 = parseRawImage( string.char(255, 30, 40, 200):rep(200) )
for i, b in ipairs( image1 ) do
    local a, g, b, r = b >> 24 & 0xFF, b >> 16 & 0xFF, b >> 8 & 0xFF, b & 0xFF
    print( string.format( '[%d] red: %d, green: %d, blue: %d, alpha: %d', i, r, g, b, a ) )
end

callbacks.Register( 'Draw', function()
    local w, h = draw.GetScreenSize()
    draw.Color( 255, 255, 255, 255 )

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
