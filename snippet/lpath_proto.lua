--- copied from / heavily inspired by: 
--- https://github.com/starwing/lpath
---@region signature
--- @class module
local luapath
--- @field fs filesystem 
--- @field env environment
--- @field info os constants
--- @field file io contents
local fs, env, info, file = {}, {}, {}, {}
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
local function cwd()

end

--- returns a idx, part iterator to get parts in the path.
--- @param path: string
--- @return function(): idx, string
local function parts(path)
end

--- return joined normalized path string
--- @param arg: string
--- @return string
local function resolve(...)

end

--- return joined normalized path string using alternative sep.
--- @param arg: string
--- @return string
local function alt(...)

end

--- walk into sub directories recursively.
--- accepts a pattern for filter the items in directory.
--- returns a iterator to list all child items in path
--- @param dirpath: ?string
--- @param filter: ?string
--- @param depth: ?integer
--- @return function(): string, table
function fs.glob(dirpath, filter, depth)
end

--- create directory recursively.
--- returns a table with success code and any error message
--- @param dirpath: string
--- @return table: integer, string @indicies
function fs.makedirs(dirpath)

end

---	returns whether the path is exists in file system 
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.exists(path)

end

--- returns file attributes of said path
--- @return attributes table<key, true> @key-value
function fs.attributes(path)

end

--- returns whether the path is a directory.
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.isdir(path)

end

--- returns whether the path is a regular file.
--- @param path: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.isfile(path)

end

--- update the access/modify time for the path file, if file is not exists, create it.
--- @param filepath: string
--- @return succ: boolean
--- @return ?err: string
--- @return ?line: integer
function fs.touch(filepath)

end

--- return a path that all environment variables replaced.
--- @param arg: string
--- @return string
function env.expand(...)

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

luapath = {
    _VERSION = 'luapath 0.1',
    ----
    cwd = cwd,
    parts = parts,
    resolve = resolve,
    alt = alt,
    ----
    fs = fs,
    env = env,
    info = info,
    --- 
    file = file
 }
setmetatable(luapath, {
    __call = resolve,
    __name = 'luapath'
 })

return luapath
