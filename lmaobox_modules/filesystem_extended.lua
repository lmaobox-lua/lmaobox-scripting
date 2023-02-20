--[[
        Extending functionality to current filesystem library.
        Created in 2023 by Lewd Developer.
--]]

local pathlib = require("path")
local fs = {}

local current_working_directory = pathlib.current_working_directory


---@return boolean|nil
local function is_file_attribute(attributes)
    if attributes == INVALID_FILE_ATTRIBUTES then return nil end
    return (attributes & ~FILE_ATTRIBUTE_DIRECTORY == 0) and true or false
end

---Returns true if the given path is a file, false if it is a directory, and `nil` if cannot find the file
---@return boolean|nil
local function is_file(path) return is_file_attribute(filesystem.GetFileAttributes(path)) end

local function expand(path)
    return pathlib.resolve(string.gsub(path, "%%(%w+)%%", os.getenv))
end

--- Returns the directory contents
local function dir()

end

--- Returns the directory tree
local function glob(dirpath, depth)
end

--- Creates a new file, even if the path doesn't exist
local function make(filepath)
end

--- Creates a new folder, even if the path doesn't exist
local function makedir(dirpath)
end

pathlib.filesystem = {
    make    = make,
    makedir = makedir,
    is_file = is_file_attribute,
    glob    = glob,
    dir     = dir
}

return pathlib
