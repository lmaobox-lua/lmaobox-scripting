--- Ported from https://github.com/denoland/deno_std/blob/main/path/win32.ts
--- Copyright 2022-2023 Lewd Developer. All rights reserved. MIT License

local string_split, string_last_index_of

function string_split(source, seperator, limit)
    local capture  = {}
    local index    = 1
    local position = 1
    local limit    = limit or 4294967295
    while index <= limit do
        local first, last = string.find(source, seperator, index, true)
        if not first then
            break
        end
        capture[index] = string.sub(source, position, first - 1)
        index          = index + 1
        position       = last + 1
    end
    if index <= limit then
        capture[index] = string.sub(source, position, -1)
    end
    return capture
end

function string_last_index_of(source, seperator)
    local first = 0
    local last, position
    repeat
        position    = first
        first, last = string.find(source, seperator, first + 1, true)
    until (first == nil)
    return position
end

---@alias PathStruct { root: string, directory: string, basename: string, extension: string, filename: string }

-- code point
local CHAR_BACKWARD_SLASH, CHAR_FORWARD_SLASH, CHAR_COLON, CHAR_DOT, CHAR_QUESTION_MARK, CHAR_QUESTION_MARK, CHAR_LOWERCASE_A, CHAR_LOWERCASE_Z, CHAR_UPPERCASE_A, CHAR_UPPERCASE_Z
CHAR_BACKWARD_SLASH = 92 -- '\'
CHAR_FORWARD_SLASH  = 47 -- '/'
CHAR_COLON          = 58 -- ':'
CHAR_DOT            = 46 -- '.'
CHAR_QUESTION_MARK  = 63 -- '?'
CHAR_LOWERCASE_A    = 97
CHAR_LOWERCASE_Z    = 122
CHAR_UPPERCASE_A    = 65
CHAR_UPPERCASE_Z    = 90

local seperator, posix_seperator, delimiter
seperator       = "\\"
posix_seperator = "/"
delimiter       = ";"

local current_working_directory = ""

local function is_path_seperator(code)
    return code == CHAR_FORWARD_SLASH or code == CHAR_BACKWARD_SLASH
end

local function is_windows_device_root(code)
    return (code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z) or
        (code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z)
end

--- TODO: Rewrite (https://en.cppreference.com/w/cpp/filesystem/path) \
-- Resolves `.` and `..` elements in a `path` with directory names
---@param path string
---@param allow_above_root boolean
---@param seperator string
---@return string
local function normalize_string(path, allow_above_root, seperator)
    local paths, captured, index, length, position
    length   = string.len(path)
    position = 1
    paths    = {}
    index    = 0
    captured = 0

    while length + 1 > position do
        local first, second, code

        code = string.byte(path, position)
        if length == position then
            code = CHAR_BACKWARD_SLASH
        end

        if code == CHAR_FORWARD_SLASH or code == CHAR_BACKWARD_SLASH then
            if captured == 0 then
                goto __continue__
            end
            first, second = string.byte(path, position - captured, position - captured + 1)
            if captured == 1 and first == CHAR_DOT then
            elseif captured == 2 and first == CHAR_DOT and second == CHAR_DOT then
                if index ~= 0 then
                    index = index - 1
                end
            else
                index        = index + 1
                paths[index] = string.sub(path, position - captured, position - 1)
            end
            captured = 0
        else
            captured = captured + 1
        end
        ::__continue__::
        position = position + 1
    end

    local start_index = 1
    if allow_above_root then
        start_index = 0
        paths[start_index] = ".."
    end

    return table.concat(paths, seperator, start_index, index)
end

--- TODO: Rewrite \
---@param seperator string
---@param path_struct PathStruct
---@return string
local function _format(seperator, path_struct)
    local dir = path_struct.directory or path_struct.root
    local base = path_struct.basename or (path_struct.basename or "") .. (path_struct.extension or "")
    if not dir then
        return base
    end
    if dir == path_struct.root then
        return dir .. base
    end
    return (dir .. seperator) .. base
end

local function resolve(...)
    local segments = { ... }
    local paths    = {}

end

---@param path string
local function normalize(path)

end

-- Verifies whether `path` is absolute
---@param path string
---@return boolean
local function isabsolute(path)
    local first = string.byte(path, 1)
    if is_path_seperator(first) then
        return true
    end
    local second = string.byte(path, 2)
    local third = string.byte(path, 3)
    return is_windows_device_root(first) and second == CHAR_COLON and is_path_seperator(third)
end

-- Join all given a sequence of `paths`, then normalizes the resulting path.
---@param ... string
local function join(...)
    local res, paths, length, first_part
    paths = { ... }
    for _, path in pairs(paths) do

    end

end

-- It will solve the relative path from `from` to `to`, for instance: \
--  from = `C:\\orandea\\test\\aaa`                                   \
--  to = `C:\\orandea\\impl\\bbb`                                     \
-- The output of the function should be: `..\\..\\impl\\bbb`
---@param from string
---@param to string
local function relative(from, to)

end

-- Resolves `path` to a `namespace path`
---@param path string
local function to_namespace_path(path)

end

-- Return the directory path of a `path`.
---@param path string
local function dirname(path)

end

-- Return the last portion of a `path`. Trailing directory separators are ignored.
---@param path string
---@param extension string
local function basename(path, extension)

end

-- Return the extension of the `path` with leading period.
---@param path string
local function extname(path, extension)

end

-- Generate a `path` from `Path` table
---@param path_struct PathStruct
---@return string
local function format(path_struct)

end

-- Generate a `PathStruct` table from `path`
---@param path string
---@return PathStruct
local function parse(path)
    local path_struct = {
        root      = "",
        directory = "",
        basename  = "",
        extension = "",
        filename  = ""
    }
    return path_struct
end

local pathlib = {
    isabsolute        = isabsolute,
    join              = join,
    relative          = relative,
    to_namespace_path = to_namespace_path,
    dirname           = dirname,
    basename          = basename,
    extname           = extname,
    format            = format,
    parse             = parse
}

print(normalize_string("..\\C:\\\\temp\\\\foo\\bar\\..\\", true, "\\"))

-- current_working_directory = resolve(...)
pathlib.current_working_directory = current_working_directory

return pathlib
