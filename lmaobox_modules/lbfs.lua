local lfs, info, file, pathlib, cwd
pathlib = loadfile(package.searchpath("luapath", package.path, ".", "/"), 't')(engine.GetGameDir() .. '/..')
cwd     = pathlib.current_working_directory

---Returns true if the given path is a file, false if it is a directory, and nil if it doesn't exist.
---@return boolean|nil
local function is_file(filePath, attributes)
    if not attributes then
        attributes = filesystem.GetFileAttributes(filePath)
    end
    if attributes == INVALID_FILE_ATTRIBUTES then return nil end
    return (attributes & ~FILE_ATTRIBUTE_DIRECTORY == 0) and true or false
end

local function expand(path)
    return pathlib.resolve(string.gsub(path, "%%(%w+)%%", os.getenv))
end

local function dir()

end

--- Returns the directory tree
local function glob(dirpath, depth)
end

--- Creates a new file
local function make(filepath)
end

--- Creates a new folder
local function makedir(dirpath)
end

file = {
    make    = make,
    makedir = makedir,
}

lfs = {
    is_file = is_file,
    glob    = glob,
    dir     = dir
}

pathlib._NAME    = "pathlib"
pathlib._VERSION = "1.0.0.1"
pathlib.file     = file
pathlib.fs       = lfs

return pathlib
