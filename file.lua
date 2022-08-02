--- 
--- SHIT LIB, DO NOT USE!!!
--- YOU HAVE BEEN WARNED.
---

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
--- hi!
---

---@param string: filename
---@return table
local function path( filename )
    filename = filename or get_script_host()
    return {
        filename = filename,
        -- composes an absolute path
        absolute = function( self )
            return self.filename
        end,
        -- returns the current working directory
        current_path = function( self )
            self._current_path = self._current_path or (self.filename:gsub( '[^\\/]+$', '' ))
            return self._current_path
        end,
        -- returns the parent directory
        parent_path = function( self )
            self._parent_path = self._parent_path or (self.filename:gsub( '[^\\/]+$', '' ):gsub( '[^\\/]+$', '' ))
            return self._parent_path
        end,
        -- returns the root drive
        root_name = function( self )
            self._root_name = self._root_name or self.filename:gmatch( '.[^\\/]' )
            return self._root_name
        end,
        -- returns the root directory
        root_path = function()
            self._root_path = self._root_path or self.filename:gmatch( '[^\\/]+' )
            return self._root_path
        end,
        -- returns the array of the part
        part = function( self )
            if self._arr_path then
                return self._arr_path
            end
            self._arr_path = {}
            for w in self.filename:gmatch( '[^\\/]+' ) do
                self._arr_path[#self._arr_path + 1] = w
            end
            return self._arr_path
        end
     }
end

---@param string: filename
---@return string
local function status( filename )
    local attrib, is_file = filesystem.GetFileAttributes( filename ), io.open( filename, 'r' )
    local status = {}
    if attrib == INVALID_FILE_ATTRIBUTES then
        return 'file does not exist'
    end
    if is_file then
        status[#status + 1] = 'file'
        io.close( filename )
    end
    for enum, text in pairs( attribute_text ) do
        if (attrib & enum) ~= 0 then
            status[#status + 1] = text
        end
    end
    return table.concat( status, ', ' )
end

---@param string: filename
local function is_directory( filename )
    local attributes = filesystem.GetFileAttributes( filename )
    return attributes ~= INVALID_FILE_ATTRIBUTES and (attributes & FILE_ATTRIBUTE_DIRECTORY) ~= 0
end

---@param string: filename
local function is_file( filename )
    local f = io.open( filename, 'r' )
    if f then
        io.close( f )
        return true
    end
end

---@param string: filename
---@return boolean: file exist?
local function exist( filename )
    return is_file( filename ) or is_directory( filename )
end

---@param string: filename
---@return function: directory iterator
local function directory_recursive_iterator( filename )

end

---@param string: filename
---@return string: folder path | err on fail
local function new_folder( filename )
    if not is_file( filename ) and not is_directory( filename ) then
        local ok, succ = pcall( filesystem.CreateDirectory, filename )
        if not ok then
            return succ
        end
    end
    return filename
end

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
    
  The mode string can also have a 'b' at the end, which is needed in some systems to open the file in binary mode.
]]

local function read( filename, format )
    local f<close> = assert( io.open( filename, 'r' ) )
    return f:read( format or 'all' )
end

local function overwrite( filename, content )
    local f<close> = assert( io.open( filename, 'w' ) )
    return f:write( content )
end

---@param string: from "file name"
---@param string: to "new file name"
---@param boolean: transfer_attributes
local function copy( from, to, transfer_attributes )
    local ok, attributes = pcall( filesystem.GetFileAttributes( from ) )
    if not ok then
        return attributes
    end
    if attributes == INVALID_FILE_ATTRIBUTES then
        return 'file does not exist'
    end
    local ffrom = io.open( from, 'rb' )
    if ffrom then
        local content = ffrom:read( 'all' )
        ffrom:close()
        local fto = io.open( to, 'wb' )
        if fto then
            if #fto:seek( 'end' ) > 0 then
                fto:close()
                return 'file already exist'
            end
            fto:write( content ):flush()
            fto:close()
            if transfer_attributes == nil or transfer_attributes == true then
                filesystem.SetFileAttributes( to, attributes )
            end
            return true
        end
        return select( 2, pcall( filesystem.GetFileAttributes, to ) )
    end

    if (attributes & FILE_ATTRIBUTE_DIRECTORY) ~= 0 then
        local ok, succ = pcall( filesystem.CreateDirectory, to )
        if not ok then
            return succ
        end
        if transfer_attributes == nil or transfer_attributes == true then
            filesystem.SetFileAttributes( to, attributes )
        end
        return true
    end
end

---@param string: from "file name"
---@param string: to "new file name"
local function move( from, to )
    if copy( from, to ) then
        local ok, errmsg = os.remove( from )
        if not ok then
            return errmsg
        end
        return ok
    end
end

---@param string: from "file name"
---@param string: to "new file name"
local function rename( from, to )
    local ok, errmsg = os.rename( from, to )
    if not ok then
        return errmsg
    end
    return ok
end

---@param string: path "file name"
local function remove( path )
    local ok, errmsg = os.remove( path )
    if not ok then
        return errmsg
    end
    return ok
end

return {
    __status = 'abandon',
    __version = '0.0.2',
    __date = '2022-07-29 03:02:40',
    path = path,
    is_directory = is_directory,
    is_file = is_file,
    copy = copy,
    move = move,
    read = read,
    overwrite = overwrite,
    rename = rename,
    status = status,
    directory_recursive_iterator = directory_recursive_iterator
 }
