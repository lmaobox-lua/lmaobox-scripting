-- https://learn.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
local attribute_text = { [1] = "readonly", [2] = "hidden", [4] = "system", [16] = "directory", [32] = "archive",
                         [64] = "device", [128] = "normal", [256] = "temporary", [512] = "sparse",
                         [1024] = "reparse point", [2048] = "compressed", [4096] = "offline", [8192] = "indexed",
                         [16384] = "encrypted", [32768] = "integrity", [65536] = "virtual", [131072] = "scrub data",
                         [262144] = "recall on open", [524288] = "pinned", [1048576] = "unpinned",
                         [4194304] = "recall on data access" }

local function get_script_name()
    return select( 3, pcall( debug.getlocal, 4, 1 ) ) or GetScriptName()
end

local filewrap, custom_dir, default_dir

---@class filewrap
filewrap = {}
default_dir = engine.GetGameDir():gsub( '[^\\/]+$', '' )
custom_dir = {}

function filewrap.chdir(path)
    if not custom_dir[get_script_name()] then
        custom_dir[get_script_name()] = {}
    end
    custom_dir[get_script_name()][1] = path
    return true
end

function filewrap.currentdir(...)
    if not custom_dir[get_script_name()] then
        custom_dir[get_script_name()] = {}
    end
    return custom_dir[get_script_name()][1] or default_dir
end

function filewrap.attributes(filename, need_enum)
    local attributes, flags
    attributes = {}
    flags = filesystem.GetFileAttributes( filewrap.currentdir() .. filename )
    if need_enum == nil then
        need_enum = true
    end
    if flags == 0xFFFFFFFF then
        attributes['invalid'] = true
        if need_enum then
            attributes[0xFFFFFFFF] = true
        end
        return
    end
    if flags & 0x10 == 0 then
        attributes['file'] = true
    end
    for enum, text in pairs( attribute_text ) do
        if (flags & enum) ~= 0 then
            attributes[attribute_text[enum]] = true
            if need_enum then
                attributes[enum] = true
            end
        end
    end
    return attributes
end

function filewrap.is_dir(filename)
    local flags = filesystem.GetFileAttributes( filewrap.currentdir() .. filename )
    if flags == 0xFFFFFFFF then
        return nil
    end
    if flags & 0x10 ~= 0 then
        return true
    end
    return false
end

function filewrap.is_file(filename)
    local flags = filesystem.GetFileAttributes( filewrap.currentdir() .. filename )
    if flags == 0xFFFFFFFF then
        return nil
    end
    if flags & 0x10 == 0 then
        return true
    end
    return false
end

function filewrap.mkdir(dirname)
    return filesystem.CreateDirectory( filewrap.currentdir() .. dirname )
end

function filewrap.mkfile(filename)
    if filewrap.is_file( filename ) == nil then
        local f = io.open( filename, 'w' )
        assert( f )
        f:close()
        return true
    end
    return nil, "file already exist"
end

function filewrap.rmdir(dirname, force)
    local path, has_content_inside
    path = filewrap.currentdir() .. dirname
    has_content_inside = false
    filesystem.EnumerateDirectory( path, function(name, attrib)
        has_content_inside = true
    end )

    if not has_content_inside or force then
        filesystem.SetFileAttributes( path, 0 )
        return os.remove( path )
    end
    return nil, "folder is not empty"
end

function filewrap.rm(filename)
    return os.remove( filewrap.currentdir() .. filename )
end

function filewrap.mv(oldname, newname)
    return os.rename( oldname, newname )
end

function filewrap.open(filename, mode)
    return assert( io.open( filewrap.currentdir() .. filename, mode ) )
end

function filewrap.read(filename)
    return assert( io.open( filewrap.currentdir() .. filename, 'rb' ) )
end

function filewrap.write(filename, contents)
    return assert( io.open( filewrap.currentdir() .. filename, 'w' ) )
end

function filewrap.delete(filename)
    local path = filewrap.currentdir() .. filename
    local ret = filewrap.is_file( path )
    if ret == nil then
        return nil, 'cannot find path'
    end
    if ret == true then
        return filewrap.rm( path )
    end
    if ret == false then
        return filewrap.rmdir( path )
    end
end

return filewrap
