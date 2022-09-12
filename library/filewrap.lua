local _base_dir = engine.GetGameDir():gsub( '[^\\/]+$', '' ) -- fuck lmaobox #1
local attribute_text = {
    [1]       = "readonly",
    [2]       = "hidden",
    [4]       = "system",
    [16]      = "device",
    [32]      = "archive",
    [128]     = "normal",
    [256]     = "temporary",
    [512]     = "sparse",
    [1024]    = "reparse_point",
    [2048]    = "compressed",
    [4096]    = "offline",
    [8192]    = "indexed",
    [16384]   = "encrypted",
    [32768]   = "integrity",
    [65536]   = "virtual",
    [131072]  = "scrub_data",
    [262144]  = "recall_on_open",
    [524288]  = "pinned",
    [1048576] = "unpinned",
    [4194304] = "recall_on_data_access"
 }

--- hello bad actor i copied your code: https://github.com/sapphyrus
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

local function is_dir( filename )
    local attrib = filesystem.GetFileAttributes( filename )
    if attrib ~= 0xFFFFFFFF and attrib & 0x10 ~= 0 then
        return true
    end
    return false
end

local function is_file( filename )
    local attrib = filesystem.GetFileAttributes( filename )
    if attrib ~= 0xFFFFFFFF and attrib & 0x10 == 0 then
        return true
    end
    return false
end

local function create_dir( filename )
    return is_dir( filename ) or filesystem.CreateDirectory( filename )
end

local function create_file( filename )
    if not is_file( filename ) then
        local f = io.open( filename, 'w' )
        assert( f, string.format( 'cannot open file : %s (mode: w)', _base_dir .. filename ) )
        f:close()
        return true
    end
    return true
end

local function open( filename, mode )
    if type( mode ) ~= 'string' then
        mode = 'r'
    end
    return assert( io.open( filename, mode ) )
end

local function write( filename, contents, textorBinary )
    local mode = textorBinary and 'w' or 'wb'
    local f = open( filename, mode )
    f:write( contents )
    f:close()
    return true
end

-- fuck lmaobox #2 
--  + blackfire for broken SetFileAttributes
local function remove( filename )
    if is_dir( filename ) then
        filesystem.SetFileAttributes( filename, filesystem.GetFileAttributes( filename ) & ~0x10 )
    end
    return os.remove( filename )
end

local function attribute_info( filename )
    local u, attrib = {}, filesystem.GetFileAttributes( filename )
    if attrib == 0xFFFFFFFF then
        return 'invalid'
    end
    if attrib & 0x10 == 0 then
        u[#u + 1] = 'file'
    end
    for enum, text in pairs( attribute_text ) do
        if (attrib & enum) ~= 0 then
            u[#u + 1] = text .. " (" .. enum .. ")"
        end
    end
    return table.concat( u, ', ' )
end

-- another methods is to self invoke debug.getlocal, 4, 1 to retrieve loadedname
local unload = function( self, soft )
    for k, n in pairs( package.loaded ) do
        if n == self then
            if not soft then
                setmetatable( self, {
                    __mode = 'kv'
                 } )
            end
            package.loaded[k] = nil
        end
    end
end

local base_dir = setmetatable( {}, {
    __index = function( self )
        return _base_dir
    end,
    __call = function( self, newval )
        local ret, _, source = pcall( debug.getlocal, 4, 1 )
        if ret then
            if newval then
                self[source] = newval
                return true
            end
            return self[source]
        end
        return nil
    end
 } )

local t = {
    crc32 = crc32,
    is_dir = is_dir,
    is_file = is_file,
    create_dir = create_dir,
    create_file = create_file,
    open = open,
    write = write,
    attribute_info = attribute_info,
    remove = remove
 }
return setmetatable( {}, {
    __index = function( self, key )
        if key == 'unload' then
            return function( fmt )
                return unload( self, fmt == 'soft' and true )
            end
        elseif key == 'base_dir' then
            return base_dir
        end
        return function( filename, ... )
            filename = _base_dir .. filename
            return t[key]( filename, ... )
        end
    end
 } )
