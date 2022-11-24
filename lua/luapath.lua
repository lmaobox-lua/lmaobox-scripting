--- copied from / heavily inspired by: 
--- https://github.com/starwing/lpath
-- https://learn.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
local win32_file_attributes = {
    [1] = 'readonly',
    [2] = 'hidden',
    [4] = 'system',
    [16] = 'directory',
    [32] = 'archive',
    [64] = 'device',
    [128] = 'normal',
    [256] = 'temporary',
    [512] = 'sparse',
    [1024] = 'reparse point',
    [2048] = 'compressed',
    [4096] = 'offline',
    [8192] = 'indexed',
    [16384] = 'encrypted',
    [32768] = 'integrity',
    [65536] = 'virtual',
    [131072] = 'scrub data',
    [262144] = 'recall on open',
    [524288] = 'pinned',
    [1048576] = 'unpinned',
    [4194304] = 'recall on data access'
 }

---@region signature
--- @field fs filesystem 
--- @field env environment
--- @field info os constants
--- @field file io contents
local fs, env, info, file = {}, {}, {}, {}
--- @class module
local luapath = {
    _VERSION = 'luapath 0.1',
    _NAME = "luapath",
    fs = fs,
    env = env,
    info = info,
    --- 
    file = file
 }
info.platform = 'windows'
info.sep = '\\'
info.altsep = '/'
info.curdir = '.'
info.pardir = '..'
info.extsep = '.'
info.pathsep = ';'
---@endregion 

--- fetch the current working directory path.
--- @return string
function luapath.cwd()
    return (engine.GetGameDir():gsub('[\\/][^\\/]+$', ''))
end

--- returns a idx, part iterator to get parts in the path.
--- @param path: string
--- @return function(): idx, string
function luapath.parts(path)
    local idx = 0
    local next_pc = path:gmatch('([^\\/]+)([\\/]*)')
    return function()
        local v = next_pc()
        if v ~= nil then
            idx = idx + 1
            return idx, v
        end
    end
end

---
function luapath.parse()
end

function luapath.applysepparts()

end

--- return joined normalized path string
--- @param arg: string
--- @return string
function luapath.resolve(...)
    --- TODO resolve
    local arg = { ... }
    for i, v in ipairs(arg) do

    end
end

--- return joined normalized path string using alternative sep.
--- @param arg: string
--- @return string
function luapath.alt(...)
    --- TODO alt
end

--- walk into sub directories recursively.
--- accepts a pattern for filter the items in directory.
--- returns a iterator to list all child items in path
--- @param dirpath: ?string
--- @param filter: ?string
--- @param depth: ?integer
--- @return function(): string, table
function fs.glob(dirpath, filter, depth)
    --- TODO glob
    -- sort alphabetically
    local idx, folder = 1, { dirpath }
    local node = {}
    repeat
        local dirpath, iter
        dirpath = folder[idx]
        iter = dirpath .. '\\*'
        filesystem.EnumerateDirectory(iter, function(filename, attributes)
            if filename == '.' or filename == '..' then
                return
            end
            local rel = dirpath .. '\\' .. filename
            if not filter or filename:match(filter) then
                node[rel] = fs.attributes(rel)
            end
            if attributes & 0x10 ~= 0 then
                table.insert(folder, rel)
            end
        end)
        idx = idx + 1
    until folder[idx] == nil
    return function()
        local k, v = next(node)
        if v ~= nil then
            return k, v
        end
    end
end

--- create directory recursively.
--- returns a table with success code and any error message
--- @param dirpath: string
--- @return table<integer, string> @indicies
function fs.makedirs(dirpath)
    --- TODO makedirs
end

---	returns whether the path is exists in file system 
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.exists(path)
    return filesystem.GetFileAttributes(path) ~= 0xFFFFFFFF
end

--- returns file attributes of said path
--- @return nil | table<key, value> @key-value
function fs.attributes(path)
    if fs.exists(path) then
        local attributes = {}
        local flags = filesystem.GetFileAttributes(path)
        for k, v in pairs(win32_file_attributes) do
            if (flags & k) ~= 0 then
                attributes[k] = v
            end
        end
        return attributes
    end
end

--- returns whether the path is a directory.
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.isdir(path)
    local a = filesystem.GetFileAttributes(path)
    return a ~= 0xFFFFFFFF and a & 0x10 ~= 0
end

--- returns whether the path is a regular file.
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.isfile(path)
    local a = filesystem.GetFileAttributes(path)
    return a ~= 0xFFFFFFFF and a & 0x10 == 0
end

--- update the access/modify time for the path file, if file is not exists, create it.
--- @param filepath: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.touch(filepath)
    local f, suc, err = io.open(filepath, 'a')
    if f then
        f:close()
        return true
    end
    return nil, suc, err
end

--- return a path that all environment variables replaced.
--- @param arg: string
--- @return string
function env.expand(...)
    --- TODO expand
    local arg = { ... }
    for i, v in ipairs(arg) do
        arg[i] = os.getenv(v:sub(2, #v - 1)) or v
    end
    return table.concat(arg, info.sep)
end

--- read contents from a file.
--- @param filepath: string
--- @param format: openmode
--- @return ?string | nil
function file.read(filepath, format)
    if not fs.touch(filepath) then
        return nil
    end
    local f, contents
    f = io.open(filepath, 'rb')
    contents = f:read(format or 'a')
    f:close()
    return contents
end

--- write contents to a file.
--- @param filepath: string
--- @param contents: string
--- @return true | nil
function file.write(filepath, contents)
    if not fs.touch(filepath) then
        return nil
    end
    local f, contents
    f = io.open(filepath, 'wb')
    f:write(contents):close()
    return true
end

--- deletes the file
--- @return suc: boolean
--- @return ?string : error
--- @return ?line : integer
function file.delete(filepath)
    return os.remove(filepath)
end

setmetatable(luapath, {
    __call = resolve,
    __name = 'luapath'
 })

-- for i, v in parts(cwd()) do
--     print(i, v)
-- end

-- for k, v in fs.glob(cwd()) do
--     print(k, v)
-- end

if not ... then
    package.preload['luapath'] = function()
        return luapath
    end
else
    return luapath
end

