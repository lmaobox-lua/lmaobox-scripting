---@param File Attribute Constants
---@link https://docs.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
FILE_ATTRIBUTE_ARCHIVE = 0x20
FILE_ATTRIBUTE_COMPRESSED = 0x800
FILE_ATTRIBUTE_DEVICE = 0x40
FILE_ATTRIBUTE_DIRECTORY = 0x10
FILE_ATTRIBUTE_ENCRYPTED = 0x4000
FILE_ATTRIBUTE_HIDDEN = 0x2
FILE_ATTRIBUTE_INTEGRITY_STREAM = 0x8000
FILE_ATTRIBUTE_NORMAL = 0x80
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 0x2000
FILE_ATTRIBUTE_NO_SCRUB_DATA = 0x20000
FILE_ATTRIBUTE_OFFLINE = 0x1000
FILE_ATTRIBUTE_READONLY = 0x1
FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = 0x400000
FILE_ATTRIBUTE_RECALL_ON_OPEN = 0x40000
FILE_ATTRIBUTE_REPARSE_POINT = 0x400
FILE_ATTRIBUTE_SPARSE_FILE = 0x200
FILE_ATTRIBUTE_SYSTEM = 0x4
FILE_ATTRIBUTE_TEMPORARY = 0x100
FILE_ATTRIBUTE_VIRTUAL = 0x10000
FILE_ATTRIBUTE_PINNED = 0x80000
FILE_ATTRIBUTE_UNPINNED = 0x100000
INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF

local attribute_text = {
    [FILE_ATTRIBUTE_ARCHIVE] = 'archive',
    [FILE_ATTRIBUTE_COMPRESSED] = 'compressed',
    [FILE_ATTRIBUTE_DIRECTORY] = 'directory',
    [FILE_ATTRIBUTE_ENCRYPTED] = 'encrypted',
    [FILE_ATTRIBUTE_HIDDEN] = 'hidden',
    [FILE_ATTRIBUTE_NOT_CONTENT_INDEXED] = 'indexed',
    [FILE_ATTRIBUTE_NORMAL] = 'normal',
    [FILE_ATTRIBUTE_OFFLINE] = 'offline',
    [FILE_ATTRIBUTE_READONLY] = 'readonly',
    [FILE_ATTRIBUTE_REPARSE_POINT] = 'reparse_point',
    [FILE_ATTRIBUTE_SPARSE_FILE] = 'sparse',
    [FILE_ATTRIBUTE_SYSTEM] = 'system',
    [FILE_ATTRIBUTE_TEMPORARY] = 'temporary',
    [FILE_ATTRIBUTE_VIRTUAL] = 'virtual',
    [FILE_ATTRIBUTE_DEVICE] = 'device',
    [FILE_ATTRIBUTE_INTEGRITY_STREAM] = 'integrity',
    [FILE_ATTRIBUTE_NO_SCRUB_DATA] = 'scrub_data',
    [FILE_ATTRIBUTE_PINNED] = 'pinned',
    [FILE_ATTRIBUTE_UNPINNED] = 'unpinned',
    [FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS] = 'recall_on_data_access',
    [FILE_ATTRIBUTE_RECALL_ON_OPEN] = 'recall_on_open'
 }

local function string_format( ... )
    return GetScriptName():match( '[^\\/]+$' ) .. ' - ' .. string.format( ... )
end

local function get_script_host()
    return select( 3, pcall( debug.getlocal, 4, 1 ) ) or GetScriptName()
end

--- 

local function status( filename )
    local attrib, buf = filesystem.GetFileAttributes( filename ), {}

    if attrib == INVALID_FILE_ATTRIBUTES then
        return 'file does not exist'
    end

    -- order is maintained since they aren't keys.
    for enum, text in pairs( attribute_text ) do
        if (attrib & enum) ~= 0 then
            buf[#buf + 1] = text
        end
    end
    return table.concat( buf, ', ' )
end

local function is_directory( filename )
    local attributes = filesystem.GetFileAttributes( filename )
    return attributes ~= INVALID_FILE_ATTRIBUTES and (attributes & FILE_ATTRIBUTE_DIRECTORY) ~= 0
end

local function is_file( filename )
    local file = io.open( filename, 'rb' )
    if file then
        io.close( file )
        return true
    end
end

local function directory_recursive_iterator( filename )
end

local function copy_wrapper( from, to, format )
    local file, attributes = io.open( from, 'rb' ), filesystem.GetFileAttributes( from )

    if io.type( file ) == 'file' then
        local new = io.open( to, 'wb' )
        if io.type( new ) == 'file' then
            new:write( file:read( format or 'a' ) )
            new:close()
            file:close()
            -- filesystem.SetFileAttributes( to, attributes )
            return true
        end
    end

    if attributes ~= INVALID_FILE_ATTRIBUTES and (attributes & FILE_ATTRIBUTE_DIRECTORY) ~= 0 then
        filesystem.CreateDirectory( to )
        -- filesystem.SetFileAttributes( to, attributes )
        return true
    end
end

local function copy( from, to, format )
    local ok = pcall( copy_wrapper, from, to, format )
    if not ok then
        local debug = debug.getinfo( 2 )
        return nil, string_format( '%s:%d: %s\n%s', debug.short_src, debug.currentline,
            select( 2, os.rename( from, copy ), format ) )
    end
    return ok
end

local function move( from, to )
    if copy( from, to ) then
        local ok, errmsg = os.remove( from )
        return ok, errmsg
    end
end

local function rename( old, new )
    local ok, errmsg = os.rename( old, new )
    return ok, errmsg
end

local function path( filename )
    return {
        filename = filename,
        -- returns the current working directory
        current_path = function( self )
            return (self.filename:gsub( '[^\\/]+$', '' ))
        end,
        -- composes an absolute path
        absolute_path = function( self )
            return self.filename
        end,
        -- 
        slice = function( self )
            local buf = {}
            for w in self.filename:gmatch( '[^\\/]+' ) do
                buf[#buf + 1] = w
            end
            return buf
        end
     }
end

local function open( filename )
    local mt = {
        __eq = function( la, ra )
            local match = la.filename == ra.filename
            return match
        end,
        __close = function( self )
            printc( 6, 211, 63, 255, string_format( '%s: %s closed', self.filename, self.type ) )
        end,
        __index = {
            -- query file attributes
            status = function( self )
                return status( self.filename )
            end,
            -- close file handle
            close = function( self )
                if io.type( self.file ) == 'file' then
                    return io.close(self.file)
                end
            end,
            set_cur_path = function( self, to )
                if to and self.filename ~= to then
                    local file = io.open( to, 'w' )
                    if file then
                        self:close()
                        self.type = 'file'
                        self.filename = to
                        self.file = io.open( to, 'r+b' )
                        return self
                    end
                    if is_directory( to ) then
                        self:close()
                        self.type = 'directory'
                        self.filename = to
                        return self
                    end
                end
            end,
            -- rename files or directories
            rename = function( self, to )
                self:close()
                local ok, errmsg = rename( self.filename, to )
                if ok then
                    self:set_cur_path( to )
                    return self
                end
                local debug = debug.getinfo( 2 )
                printc( 238, 210, 2, 255,
                    string_format( '%s:%d: %s: %s ', debug.short_src, debug.currentline, errmsg, to ) )
            end,
            -- move files or directories
            move = function( self, to )
                self:close()
                local ok, errmsg = move( self.filename, to )
                if ok then
                    self:set_cur_path( to )
                    return self
                end
                local debug = debug.getinfo( 2 )
                printc( 238, 210, 2, 255,
                    string_format( '%s:%d: %s: %s', debug.short_src, debug.currentline, errmsg, to ) )
            end,
            -- copies files or directories
            copy = function( self, to, format )
                self:close()
                local ok, errmsg = copy( self.filename, to, format )
                if ok then
                    self:set_cur_path( to )
                    return self
                end
                printc( 238, 210, 2, 255, string_format( '%s:%d: %s ', debug.short_src, debug.currentline, errmsg ) )
            end,
            -- an iterator to the contents of the directory
            iterator = function( self, callback )
                return filesystem.EnumerateDirectory( self.filename, callback )
            end,
            -- an iterator to the contents of a directory and its subdirectories
            recursive_iterator = function( self )

            end
         }
     }

    local file = io.open( filename, 'r+b' )
    if io.type( file ) == 'file' then
        return setmetatable( {
            type = 'file',
            filename = filename,
            file = file
         }, mt )
    end

    if is_directory( filename ) then
        return setmetatable( {
            type = 'directory',
            filename = filename
         }, mt )
    end

    -- access denied, file does not exist
    local debug = debug.getinfo( 2 )
    printc( 238, 210, 2, 255, string_format( '%s:%d: %s', debug.short_src, debug.currentline,
        select( 2, pcall( filesystem.GetFileAttributes, filename ) ) ) )
end

return {
    version = '0.0.1',
    date = '2022-07-28 01:42:11',
    open = open,
    path = path,
    is_directory = is_directory,
    is_file = is_file,
    copy = copy,
    move = move,
    rename = rename,
    status = status,
    directory_recursive_iterator = directory_recursive_iterator
 }

--[[
 ------ ---------- ----------- ------------------------- ----------------------- ------------ ------------------------------- --------------------- 
  type   readable   writeable   default position: start   default position: end   must exist   truncate (clear file) on load   Always write to EOF  
 ------ ---------- ----------- ------------------------- ----------------------- ------------ ------------------------------- --------------------- 
  r      x                      x                                                 x                                                                 
  r+     x          x           x                                                 x                                                                 
  w                 x           x                                                                                              x                    
  w+     x          x           x                                                              x                                                    
  a                 x                                     x                                                                    x                    
  a+     x          x                                     x                                                                    x                    
  
  binary mode: "rb", "r+b", "w", "w+", "a", "a+" 
]]
