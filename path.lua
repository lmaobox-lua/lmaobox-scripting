--[[
        Copyright the Deno authors (https://github.com/denoland/deno_std/blob/main/path/win32.ts)
        Created in 2023 by Lewd Developer.
--]]

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

-- code point
local CHAR_BACKWARD_SLASH, CHAR_FORWARD_SLASH, CHAR_COLON, CHAR_DOT, CHAR_QUESTION_MARK, CHAR_LOWERCASE_A, CHAR_LOWERCASE_Z, CHAR_UPPERCASE_A, CHAR_UPPERCASE_Z
CHAR_BACKWARD_SLASH = 92 -- '\'
CHAR_FORWARD_SLASH  = 47 -- '/'
CHAR_COLON          = 58 -- ':'
CHAR_DOT            = 46 -- '.'
CHAR_QUESTION_MARK  = 63 -- '?'
CHAR_LOWERCASE_A    = 97 -- 'a'
CHAR_LOWERCASE_Z    = 122 -- 'z'
CHAR_UPPERCASE_A    = 65 -- 'A'
CHAR_UPPERCASE_Z    = 90 -- 'Z'

local windows_directory_seperator, posix_directory_seperator, windows_path_seperator, posix_path_seperator
windows_directory_seperator = "\\"
posix_directory_seperator   = "/"
windows_path_seperator      = ";"
posix_path_seperator        = ":"

local function is_directory_seperator(code)
    return code == CHAR_FORWARD_SLASH or code == CHAR_BACKWARD_SLASH
end

local function is_windows_device_root(code)
    return (code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z) or
        (code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z)
end

--- TODO: Rewrite
-- Resolves `.` and `..` elements in a `path` with directory names
---@param path string
---@param allow_above_root boolean
---@param directory_seperator string
---@return string
local function normalize_string(path, allow_above_root, directory_seperator)
    local res, last_segment_length, slash_position, dots, length, current, code
    res                 = "" -- the normalized string
    last_segment_length = 0 -- characters captured after path seperator
    slash_position      = 0 -- position of last path seperator
    dots                = 0
    length              = string.len(path)
    current             = 1
    while current <= (length + 1) do
        if current <= length then
            code = string.byte(path, current)
        else
            if is_directory_seperator(code) then
                break
            end
            code = CHAR_FORWARD_SLASH
        end

        if is_directory_seperator(code) then
            local res_length = string.len(res)

            if slash_position == current - 1 or dots == 1 then
                goto __final__
            end

            if dots == 2 then
                local res_contains_dot = (string.byte(res, res_length) == CHAR_DOT) or
                    (string.byte(res, res_length - 1) == CHAR_DOT)

                if res_length > 0 or last_segment_length ~= 2 or res_contains_dot ~= true then
                    if res_length > 2 then
                        local where_slash = string_last_index_of(res, directory_seperator)
                        if where_slash == 0 then
                            res = ""
                            last_segment_length = 0
                        else
                            res = string.sub(res, 1, where_slash - 1)
                            last_segment_length = string.len(res) - string_last_index_of(res, directory_seperator)
                        end
                        goto __final__
                    end
                end

                if allow_above_root then
                    if res_length > 0 then
                        res = res .. directory_seperator .. ".."
                    else
                        res = '..'
                    end
                    last_segment_length = 2
                end
                goto __final__
            end

            if res_length > 0 then
                res = res .. directory_seperator .. string.sub(path, slash_position + 1, current - 1)
            else
                res = string.sub(path, slash_position + 1, current - 1)
            end
            last_segment_length = current - slash_position - 1

            ::__final__::
            slash_position = current
        else
            if code == CHAR_DOT then
                dots = dots + 1
            else
                dots = 0
            end
        end
        current = current + 1
    end

    return res
end

-- Verifies whether `path` identifies the location of a file without reference to an additional starting location
---@param path string
---@return boolean
local function is_absolute(path)
    local first = string.byte(path, 1)
    if is_directory_seperator(first) then
        return true
    end
    local second = string.byte(path, 2)
    local third = string.byte(path, 3)
    return is_windows_device_root(first) and second == CHAR_COLON and is_directory_seperator(third)
end

-- TODO: Preferred root_name (upper/lower)
---@param current_working_directory string
---@param directory_seperator string
---@varargs string
---@return string
local function absolute(current_working_directory, directory_seperator, ...)
    local arg, is_absolute, rootname, relative_path, index
    arg           = table.pack(...)
    relative_path = { "." }
    index         = 1
    for i = arg.n, 0, -1 do
        local path, length, one, two, root_last_position, capture_root, caught_absolute_path

        if i ~= 0 then
            path = arg[i]
        else
            path = current_working_directory
            if rootname and string.upper(string.sub(path, 1, 3)) ~= string.sub(rootname, 1, 3) then
                path = rootname
            end
        end

        if not path then goto L1 end
        length = string.len(path)
        if length == 0 then goto L1 end

        one, two           = string.byte(path, 1, 2)
        root_last_position = 1

        ---@format disable
        if length > 1 then
            if is_directory_seperator(one) then
                caught_absolute_path = true
                if is_directory_seperator(two) then -- Matched double path separator at beginning
                    local position, first, second = 3, 3, 3
                    while position < length do -- Match 1 or more non-path separators
                        if is_directory_seperator(string.byte(path, position, position)) then break else position = position + 1
                        end
                    end
                    if position < length and position ~= second then
                        first = position
                        while position < length do
                            if is_directory_seperator(string.byte(path, position, position)) then break else position = position + 1
                            end
                        end
                    end
                    if position < length and position ~= second then
                        second = position
                        while position < length do
                            if is_directory_seperator(string.byte(path, position, position)) then break else position = position + 1
                            end
                        end
                        capture_root       = directory_seperator .. directory_seperator .. string.sub(path, 3, first) .. directory_seperator .. string.sub(path, second, position)
                        root_last_position = position
                    end
                end
            elseif is_windows_device_root(one) then
                if two == CHAR_COLON then
                    capture_root       = string.upper(string.sub(path, 1, 2))
                    root_last_position = 3
                    if length > 2 then
                        if is_directory_seperator(string.byte(path, 3, 3)) then
                            caught_absolute_path = true
                            root_last_position = 4
                        end
                    end
                end
            end
        end

        if capture_root then
            if not rootname then
                rootname = capture_root
            elseif rootname ~= capture_root then
                goto L1
            end
        end

        if not is_absolute then
            index                = index - 1
            relative_path[index] = string.sub(path, root_last_position, length)
            is_absolute          = caught_absolute_path
        elseif rootname ~= nil then
            index                = index - 1
            relative_path[index] = rootname
            break
        end

        ::L1::
    end

    return normalize_string(table.concat(relative_path, directory_seperator, index), is_absolute ~= true,
        directory_seperator)
end

-- Normalizes a `path`
local function weakly_canonicalize(path)

end

-- Join all given a sequence of `paths`, then normalizes the resulting path.
---@param ... string
local function lexically_normal(...)
    local arg = table.pack(...)
    if arg.n == 0 then
        return '.'
    end
    local segments, index, slash_count, need_replace, first_part, length = {}, 0, 0, true, nil, 0
    do

    end
    if index == 0 then
        return "."
    end
    assert(first_part, "error")
    if is_directory_seperator(string.byte(first_part, 1, 1)) then
        slash_count = slash_count + 1
        length      = string.len(slash_count)
        if length > 1 then
            if is_directory_seperator(string.byte(slash_count, 2, 2)) then
                slash_count = slash_count + 1
                if length > 2 then
                    if is_directory_seperator(string.byte(slash_count, 3, 3)) then
                        slash_count = slash_count + 1
                    else
                        -- We matched a UNC path in the first part
                        need_replace = false
                    end
                end
            end
        end
    end
    if need_replace then
        --- todo concat segment and get length
        while slash_count < 0 do
            if not is_directory_seperator() then
                break
            end
            slash_count = slash_count + 1
            if slash_count >= 2 then

            end
        end
    end
end

--- TODO: implement!
-- It will solve the relative path from `from` to `to`, for instance: \
--  from = `C:\\orandea\\test\\aaa`                                   \
--  to = `C:\\orandea\\impl\\bbb`                                     \
-- The output of the function should be: `..\\..\\impl\\bbb`
---@param from string
---@param to string
local function lexically_relative(from, to)

end

--- TODO: implement!
-- Resolves `path` to a `namespace path`
---@param path string
local function to_namespace_path(path)

end

--- TODO: implement!
-- iterator access to the path as a sequence of elements
local function iterator(path)

end

--- TODO: implement!
-- 	Appends elements to the path with a path separator
---@param ... string
local function connect(...)

end

---@class Path
---@field str string                 -- the path string
---@field root_name string?          -- drive letter or UNC server name
---@field root_directory string?     -- directory separator
---@field root_path string?          -- root_name() / root_directory()
---@field relative_path string?      -- path relative to root path
---@field parent_path string?        -- path without the final component
---@field filename string?           -- filename path component
---@field stem string?               -- filename without the final extension
---@field extension string?          -- file extension path component
local Path = {
    get = function(self)
        return self.str
    end,
    empty = function(self)
        return not (self.root_name or self.root_directory or self.relative_path or self.filename)
    end,
    -- Formats the path to a string
    format = function(self, ...)

    end,
    -- 	Appends elements to the path with a directory separator
    append = function(self, ...)

    end,
    -- Concatenates paths without introducing a directory separator
    concat = function(self, ...)

    end,
}

local Path_mt = {
    __index = Path,
    __add = nil,
    __div = Path.append,
    __concat = Path.concat,
    __tostring = Path.format,
}

--- constructs a path object
---@param path string
---@return Path
local function construct(path)
    local obj = setmetatable({}, Path_mt)

    return obj
end

local pathlib = {
    is_absolute         = is_absolute,
    to_namespace_path   = to_namespace_path,
    weakly_canonicalize = weakly_canonicalize,
    lexically_normal    = lexically_normal,
    lexically_relative  = lexically_relative,
    --- TODO: missing decomposite functions
    iterator            = iterator,
    connector           = connect,
    construct           = construct,
}

return pathlib

-- dirname             = function()

-- end,
-- extname             = function()

-- end,
-- basename            = function()

-- end,