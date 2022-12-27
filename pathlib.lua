---
--- For LMAOBOX Lua 5.4 (x86|windows)
---
local string_split, string_interp
do
    local sub = string.sub
    local find = string.find
    function string_split(source, separator, limit)
        if limit == nil then
            limit = string.len(source)
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        local currentPos = 1
        while resultIndex <= limit do
            local startPos, endPos = find(source, separator, currentPos, true)
            if not startPos then
                break
            end
            result[resultIndex] = sub(source, currentPos, startPos - 1)
            resultIndex = resultIndex + 1
            currentPos = endPos + 1
        end
        if resultIndex <= limit then
            result[resultIndex] = sub(source, currentPos)
        end
        return result
    end

    function string_interp(s, tab)
        return (string.gsub(s, '${(%w+)}', tab))
    end
end

local CHAR_BACKWARD_SLASH, CHAR_FORWARD_SLASH, CHAR_COLON, CHAR_DOT, CHAR_QUESTION_MARK, CHAR_LOWERCASE_A, CHAR_LOWERCASE_Z, CHAR_UPPERCASE_A, CHAR_UPPERCASE_Z
do
    CHAR_DOT = 46
    CHAR_FORWARD_SLASH = 47
    CHAR_COLON = 58
    CHAR_QUESTION_MARK = 63
    CHAR_UPPERCASE_A = 65
    CHAR_UPPERCASE_Z = 90
    CHAR_BACKWARD_SLASH = 92
    CHAR_LOWERCASE_A = 97
    CHAR_LOWERCASE_Z = 122
end

local isPosixPathSeparator, isPathSeparator, isWindowsDeviceRoot, normalizeString, _format
do
    function isPosixPathSeparator(code)
        return code == CHAR_FORWARD_SLASH
    end

    function isPathSeparator(code)
        return isPosixPathSeparator(code) or code == CHAR_BACKWARD_SLASH
    end

    function isWindowsDeviceRoot(code)
        return code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z or
            code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z
    end
    -- Resolves . and .. elements in a path with directory names
    function normalizeString(path, allowAboveRoot, separator)
        local res = ""
        local lastSegmentLength = 0
        local lastSlash = -1
        local dots = 0
        local code
        do
            local i = 0
            local len = string.len(path)
            while i <= len do
                do
                    if i < len then
                        code = string.byte(path, i)
                    elseif isPathSeparator(code) then
                        break
                    else
                        code = CHAR_FORWARD_SLASH
                    end
                    if isPathSeparator(code) then
                        if lastSlash == i - 1 or dots == 1 then
                        elseif lastSlash ~= i - 1 and dots == 2 then
                            if #res < 2 or lastSegmentLength ~= 2 or string.byte(res, #res) ~= CHAR_DOT or
                                string.byte(res, #res - 1) ~= CHAR_DOT then
                                if #res > 2 then
                                    local lastSlashIndex = string_lastIndexOf(res, separator)
                                    if lastSlashIndex == -1 then
                                        res = ""
                                        lastSegmentLength = 0
                                    else
                                        res = string.sub(res, 1, lastSlashIndex)
                                        lastSegmentLength = #res - 1 - string_lastIndexOf(res, separator)
                                    end
                                    lastSlash = i
                                    dots = 0
                                    goto __continue6
                                elseif #res == 2 or #res == 1 then
                                    res = ""
                                    lastSegmentLength = 0
                                    lastSlash = i
                                    dots = 0
                                    goto __continue6
                                end
                            end
                            if allowAboveRoot then
                                if #res > 0 then
                                    res = res .. separator .. ".."
                                else
                                    res = ".."
                                end
                                lastSegmentLength = 2
                            end
                        else
                            if #res > 0 then
                                res = res .. separator .. string.sub(path, lastSlash + 1, i)
                            else
                                res = string.sub(path, lastSlash + 1, i)
                            end
                            lastSegmentLength = i - lastSlash - 1
                        end
                        lastSlash = i
                        dots = 0
                    elseif code == CHAR_DOT and dots ~= -1 then
                        dots = dots + 1
                    else
                        dots = -1
                    end
                end
                ::__continue6::
                i = i + 1
            end
        end
        return res
    end
end

print(normalizeString('Hello/a/aWorld', false, '/'))

local pathlib, fs, info, file, cwd
cwd = engine.GetGameDir():gsub("\\", "/"):gsub('/[^/]+$', '')

---Returns true if the given path is a directory, false if it is a file, and nil if it doesn't exist.
---@return boolean|nil
local function is_directory(filePath, attributes)
    if not attributes then
        attributes = filesystem.GetFileAttributes(filePath)
    end
    if attributes == INVALID_FILE_ATTRIBUTES then return nil end
    return (attributes & FILE_ATTRIBUTE_DIRECTORY == 0) and true or false
end

---@param filePath string
---@return string|nil
---@return string|nil
local function basename(filePath)
    local basename = filePath:match('[^/\\]+$')
    local ext      = basename:match('%.[^.]+$')
    return basename, ext
end

--- Resolves path segments into a `path`
--
---@param pathSegments string to process to path
---@param ... string
local function resolve(pathSegments, ...)
    local arg    = { pathSegments, ... }
    local path   = {}
    local isabs  = false
    local device = nil
    local trail  = nil

    for i = #arg, 0, -1 do
        if device then
            break
        end
        local segment = arg[i]
        if segment == nil or segment == '' then
            goto continue
        end

        if string.find(segment, ":", 1, true) == 2 then
            local guessdevice = segment:sub(1, 1)
            if guessdevice >= 'A' or guessdevice <= 'z' then
                device = guessdevice
                goto continue
            end
        end

        print(i)

        path[#path + 1] = segment
        ::continue::
    end

end

resolve('C:\\', 'Users', 'Admin', 'Desktop', 'test.txt')

--- Normalizes a `path`
--
---@param path string to normalize
local function normalize(path)
    return path
end

--- Join all given a sequence of `paths`,then normalizes the resulting path.
--
---@param path string to be joined and normalized
local function join(path, ...)
    local arg = { path, ... }
end

---@return boolean
local function is_absolute(Path)

end

local function split(Path)
    return string_split(Path, info.altsep, info.LONG_PATH)
end

---@param path string
local function expand(path)
    return string.gsub(path, info.expansion, os.getenv)
end

local function parts(path)
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

fs = {
    is_directory = is_directory,
    basename     = basename,
    glob         = glob,
}

info = {
    platform   = 'windows',
    sep        = '\\',
    altsep     = '/',
    currentdir = '.',
    parentdir  = '..',
    delimiter  = ';',
    expansion  = "%%(%w+)%%",
    LONG_PATH  = 32767,
}

file = {
    make    = make,
    makedir = makedir,
}

pathlib = {
    _NAME      = 'pathlib',
    _VERSION   = '0.1',
    fs         = fs,
    info       = info,
    file       = file,
    cwd        = cwd,
    resolve    = resolve,
    normalize  = normalize,
    join       = join,
    isabsolute = isabsolute,
    split      = split,
    expand     = expand,
}

if ... then
    return pathlib
else
    package.preload['luapath'] = function() return pathlib end
end
