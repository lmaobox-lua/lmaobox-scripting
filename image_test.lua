local struct = require "struct"

local function unsigned_pack( ... )
    local v = { ... }
    local len, i = #v, 0
    for j = len, 1, -1 do
        i = i | math.floor( v[len - j + 1] ) << ((8 * (j - 1)) & 0xFF)
    end
    return i
end

local function unsigned_unpack( i )
    local size, unsigned = math.floor( (math.log( i, 2 ) / 8) + 1 ), {}
    for j = size, 1, -1 do
        unsigned[#unsigned + 1] = i >> ((j * 8) - 8) & 0xFF
    end
    return unsigned
end

local power_of_two_greater_or_equal_to = function( N )
    if (N & (N - 1) == 0) then
        return N, 'number is already power of 2'
    end
    N = N - 1
    N = N | N >> 1
    N = N | N >> 2
    N = N | N >> 4
    N = N | N >> 8
    N = N | N >> 16
    N = N + 1
    return N
end

-- Credits: https://github.com/sapphyrus/
-- use checksum so we dont have to keep the whole thing in memory
local function crc32( s, lt )
    -- return crc32 checksum of string as an integer
    -- use lookup table lt if provided or create one on the fly
    -- if lt is empty, it is initialized.
    lt = lt or {}
    local b, crc, mask
    if not lt[1] then -- setup table
        for i = 1, 256 do
            crc = i - 1
            for _ = 1, 8 do -- eight times
                mask = -(crc & 1)
                crc = (crc >> 1) ~ (0xedb88320 & mask)
            end
            lt[i] = crc
        end
    end

    -- compute the crc
    crc = 0xffffffff
    for i = 1, #s do
        b = string.byte( s, i )
        crc = (crc >> 8) ~ lt[((crc ~ b) & 0xFF) + 1]
    end
    return ~crc & 0xffffffff
end

local function va_args( func, ... )
    local args = { ... }
    for i = 1, #args do
        args[i] = func( args[i] )
    end
    return table.unpack( args )
end

local image_mt = {
    __index = {
        --- todo.....
        get_texture_size = 0,
        get_texture_id = 0,
        get_raw_data = 0,
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
            local unpacked = { string.unpack( format_str, self.content, self.offset ) }

            if self.size_cache[format_str] == nil then
                self.size_cache[format_str] = string.pack( format_str, table.unpack( unpacked ) ):len()
            end
            self.offset = self.offset + self.size_cache[format_str]

            return table.unpack( unpacked )
        end
     }
 }

local function struct_buffer( content )
    return setmetatable( {
        content = content,
        len = content:len(),
        size_cache = {},
        offset = 1
     }, image_mt )
end

-- http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html
local png_magic = '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A'
local channel = {
    [0] = 1,
    [2] = 3,
    [4] = 2,
    [6] = 4
 }

local function load_png( content )
    local buf = struct_buffer( content )
    local self = {}

    assert( buf:unpack( 'c8' ) == png_magic, 'invalid file signature' )

    buf:seek( 4 ) -- chunk length / padding (?)
    assert( buf:unpack( 'c4' ) == 'IHDR', 'invalid IHDR chunk' )
    self.width, self.height, self.bit_depth, self.color_type, self.compression, self.filter, self.interlace =
        buf:unpack( '>IIbbbbb' )
    self.channels = channel[self.color_type]

    -- missing PLTE (optional)

    buf:seek( 4 )
    self.idat = {
        r = {},
        g = {},
        b = {},
        a = {}
     }
    local len, chunk = buf:unpack( '>I' ), buf:unpack( 'c4' )
    assert( chunk == 'IDAT', 'invalid IDAT chunk' )
    while chunk == 'IDAT' do
        buf:seek( len )
        buf:seek( 4 )
        len = buf:unpack( '>I' )
        chunk = buf:unpack( 'c4' )
    end

    assert( chunk == 'IEND', 'something went wrong while parsing IDAT' )
    -- buf:seek( -8 )
    -- todo port from someonepng
    return self
end

local function texture( raw, width, height )
    local x, y = va_args( power_of_two_greater_or_equal_to, height, width )
    for i = 1, x do
        for j = 1, y do
            -- logic to apply transparent background....
        end
    end
    print( height, width )
end

local f<close> = io.open( engine.GetGameDir() .. '//data.png', 'rb' )
local d = f:read( 'all' )
local p = load_png( d )
printLuaTable(p)

-- https://www.nayuki.io/page/png-file-chunk-inspector#:~:text=A%20PNG%20file%20is%20composed,depend%20on%20the%20chunk%20type.