--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__StringCharCodeAt(self, index)
    if index ~= index then
        index = 0
    end
    if index < 0 then
        return 0 / 0
    end
    local ____string_byte_result_0 = string.byte(self, index + 1)
    if ____string_byte_result_0 == nil then
        ____string_byte_result_0 = 0 / 0
    end
    return ____string_byte_result_0
end

local function __TS__StringSlice(self, start, ____end)
    if start == nil or start ~= start then
        start = 0
    end
    if ____end ~= ____end then
        ____end = 0
    end
    if start >= 0 then
        start = start + 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = ____end - 1
    end
    return string.sub(self, start, ____end)
end

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local function __TS__LastIndexOf(a, b)
    a = string.reverse(a)
    b = string.reverse(b)
    local i, j = string.find(a, b, 1, true)
    if (i == nil) then
        return -1
    end
    return (#a - i - #b + 2) -1
end

local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
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
        end
        return result
    end
end

local function __TS__TypeOf(value)
    local luaType = type(value)
    if luaType == "table" then
        return "object"
    elseif luaType == "nil" then
        return "undefined"
    else
        return luaType
    end
end

-- End of Lua Library inline imports
local ____exports = {}
local CHAR_BACKWARD_SLASH = 92
local CHAR_FORWARD_SLASH = 47
local CHAR_COLON = 58
local CHAR_DOT = 46
local CHAR_QUESTION_MARK = 63
local CHAR_LOWERCASE_A = 97
local CHAR_LOWERCASE_Z = 122
local CHAR_UPPERCASE_A = 65
local CHAR_UPPERCASE_Z = 90
function ____exports.isPosixPathSeparator(self, code)
    return code == CHAR_FORWARD_SLASH
end

function ____exports.isPathSeparator(self, code)
    return ____exports.isPosixPathSeparator(nil, code) or code == CHAR_BACKWARD_SLASH
end

function ____exports.isWindowsDeviceRoot(self, code)
    return code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z or code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z
end

function ____exports.normalizeString(self, path, allowAboveRoot, separator)
    local isPathSeparator = ____exports.isPathSeparator
    local res = ""
    local lastSegmentLength = 0
    local lastSlash = -1
    local dots = 0
    local code
    do
        local i = 0
        local len = #path
        while i <= len do
            do
                if i < len then
                    code = __TS__StringCharCodeAt(path, i)
                elseif isPathSeparator(nil, code) then
                    break
                else
                    code = CHAR_FORWARD_SLASH
                end
                if isPathSeparator(nil, code) then
                    if lastSlash == i - 1 or dots == 1 then
                    elseif lastSlash ~= i - 1 and dots == 2 then
                        if #res < 2 or lastSegmentLength ~= 2 or __TS__StringCharCodeAt(res, #res - 1) ~= CHAR_DOT or
                            __TS__StringCharCodeAt(res, #res - 2) ~= CHAR_DOT then
                            if #res > 2 then
                                local lastSlashIndex = __TS__LastIndexOf(res, separator)
                                if lastSlashIndex == -1 then
                                    res = ""
                                    lastSegmentLength = 0
                                else
                                    res = __TS__StringSlice(res, 0, lastSlashIndex)
                                    lastSegmentLength = #res - 1 - __TS__LastIndexOf(res, separator)
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
                            res = res .. separator .. __TS__StringSlice(path, lastSlash + 1, i)
                        else
                            res = __TS__StringSlice(path, lastSlash + 1, i)
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

function ____exports._format(self, sep, pathObject)
    local dir = pathObject.dir or pathObject.root
    local base = pathObject.base or (pathObject.name or "") .. (pathObject.ext or "")
    if not dir then
        return base
    end
    if dir == pathObject.root then
        return dir .. base
    end
    return (dir .. sep) .. base
end

____exports.sep = "\\"
____exports.delimiter = ";"
--- Resolves path segments into a `path`
--
-- @param pathSegments to process to path
function ____exports.resolve(self, ...)
    local pathSegments = { ... }
    local resolvedDevice = ""
    local resolvedTail = ""
    local resolvedAbsolute = false
    do
        local Deno = {
            cwd = function()
                return [[C:\Users\mayakey\Desktop\filesystem]]
            end,
            env = {
                get = function()
                    return [[C:\Users\mayakey\Desktop\filesystem]]
                end
            }
        }
        local i = #pathSegments - 1
        while i >= -1 do
            do
                local path = ""
                if i >= 0 then
                    path = pathSegments[i + 1]
                elseif resolvedDevice == "" then
                    local ____Deno_cwd_1 = Deno
                    if ____Deno_cwd_1 ~= nil then
                        ____Deno_cwd_1 = ____Deno_cwd_1.cwd
                    end
                    if type(____Deno_cwd_1) ~= "function" then
                        error(
                            "Resolved a drive-letter-less path without a CWD.",
                            0
                        )
                    end
                    path = Deno:cwd()
                else
                    local ____Deno_env_5 = Deno
                    if ____Deno_env_5 ~= nil then
                        ____Deno_env_5 = ____Deno_env_5.env
                    end
                    local ____Deno_env_get_3 = ____Deno_env_5
                    if ____Deno_env_get_3 ~= nil then
                        ____Deno_env_get_3 = ____Deno_env_get_3.get
                    end
                    local ____temp_9 = type(____Deno_env_get_3) ~= "function"
                    if not ____temp_9 then
                        local ____Deno_cwd_7 = Deno
                        if ____Deno_cwd_7 ~= nil then
                            ____Deno_cwd_7 = ____Deno_cwd_7.cwd
                        end
                        ____temp_9 = type(____Deno_cwd_7) ~= "function"
                    end
                    if ____temp_9 then
                        error(
                            "Resolved a relative path without a CWD.",
                            0
                        )
                    end
                    path = Deno:cwd()
                    if path == nil or string.lower(string.sub(path, 1, 3)) ~= string.lower(resolvedDevice) .. "\\" then
                        path = resolvedDevice .. "\\"
                    end
                end
                print(path, type(path))
                local len = #path
                if len == 0 then
                    goto __continue30
                end
                local rootEnd = 0
                local device = ""
                local isAbsolute = false
                local code = string.byte(path, 1) or 0 / 0
                if len > 1 then
                    if ____exports.isPathSeparator(nil, code) then
                        isAbsolute = true

                        if ____exports.isPathSeparator(
                            nil,
                            string.byte(path, 2) or 0 / 0
                        ) then
                            local j = 2
                            local last = j
                            do
                                while j < len do
                                    if ____exports.isPathSeparator(
                                        nil,
                                        __TS__StringCharCodeAt(path, j)
                                    ) then
                                        break
                                    end
                                    j = j + 1
                                end
                            end
                            if j < len and j ~= last then
                                local firstPart = __TS__StringSlice(path, last, j)
                                last = j
                                do
                                    while j < len do
                                        if not ____exports.isPathSeparator(
                                            nil,
                                            __TS__StringCharCodeAt(path, j)
                                        ) then
                                            break
                                        end
                                        j = j + 1
                                    end
                                end
                                if j < len and j ~= last then
                                    last = j
                                    do
                                        while j < len do
                                            if ____exports.isPathSeparator(
                                                nil,
                                                __TS__StringCharCodeAt(path, j)
                                            ) then
                                                break
                                            end
                                            j = j + 1
                                        end
                                    end
                                    if j == len then
                                        device = (("\\\\" .. firstPart) .. "\\") .. __TS__StringSlice(path, last)
                                        rootEnd = j
                                    elseif j ~= last then
                                        device = (("\\\\" .. firstPart) .. "\\") .. __TS__StringSlice(path, last, j)
                                        rootEnd = j
                                    end
                                end
                            end
                        else
                            rootEnd = 1
                        end
                    elseif ____exports.isWindowsDeviceRoot(nil, code) then
                        if (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
                            device = string.sub(path, 1, 2)
                            rootEnd = 2
                            if len > 2 then
                                if ____exports.isPathSeparator(
                                    nil,
                                    string.byte(path, 3) or 0 / 0
                                ) then
                                    isAbsolute = true
                                    rootEnd = 3
                                end
                            end
                        end
                    end
                elseif ____exports.isPathSeparator(nil, code) then
                    rootEnd = 1
                    isAbsolute = true
                end
                if #device > 0 and #resolvedDevice > 0 and string.lower(device) ~= string.lower(resolvedDevice) then
                    goto __continue30
                end
                if #resolvedDevice == 0 and #device > 0 then
                    resolvedDevice = device
                end
                if not resolvedAbsolute then
                    resolvedTail = (__TS__StringSlice(path, rootEnd) .. "\\") .. resolvedTail
                    resolvedAbsolute = isAbsolute
                end
                if resolvedAbsolute and #resolvedDevice > 0 then
                    break
                end
            end
            ::__continue30::
            i = i - 1
        end
    end
    resolvedTail = ____exports.normalizeString(
        nil,
        resolvedTail,
        not resolvedAbsolute,
        "\\",
        ____exports.isPathSeparator
    )
    return (resolvedDevice .. (resolvedAbsolute and "\\" or "")) .. resolvedTail or "."
end

--- Normalizes a `path`
--
-- @param path to normalize
function ____exports.normalize(self, path)
    local len = #path
    if len == 0 then
        return "."
    end
    local rootEnd = 0
    local device
    local isAbsolute = false
    local code = string.byte(path, 1) or 0 / 0
    if len > 1 then
        if ____exports.isPathSeparator(nil, code) then
            isAbsolute = true
            if ____exports.isPathSeparator(
                nil,
                string.byte(path, 2) or 0 / 0
            ) then
                local j = 2
                local last = j
                do
                    while j < len do
                        if ____exports.isPathSeparator(
                            nil,
                            __TS__StringCharCodeAt(path, j)
                        ) then
                            break
                        end
                        j = j + 1
                    end
                end
                if j < len and j ~= last then
                    local firstPart = __TS__StringSlice(path, last, j)
                    last = j
                    do
                        while j < len do
                            if not ____exports.isPathSeparator(
                                nil,
                                __TS__StringCharCodeAt(path, j)
                            ) then
                                break
                            end
                            j = j + 1
                        end
                    end
                    if j < len and j ~= last then
                        last = j
                        do
                            while j < len do
                                if ____exports.isPathSeparator(
                                    nil,
                                    __TS__StringCharCodeAt(path, j)
                                ) then
                                    break
                                end
                                j = j + 1
                            end
                        end
                        if j == len then
                            return ((("\\\\" .. firstPart) .. "\\") .. __TS__StringSlice(path, last)) .. "\\"
                        elseif j ~= last then
                            device = (("\\\\" .. firstPart) .. "\\") .. __TS__StringSlice(path, last, j)
                            rootEnd = j
                        end
                    end
                end
            else
                rootEnd = 1
            end
        elseif ____exports.isWindowsDeviceRoot(nil, code) then
            if (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
                device = string.sub(path, 1, 2)
                rootEnd = 2
                if len > 2 then
                    if ____exports.isPathSeparator(
                        nil,
                        string.byte(path, 3) or 0 / 0
                    ) then
                        isAbsolute = true
                        rootEnd = 3
                    end
                end
            end
        end
    elseif ____exports.isPathSeparator(nil, code) then
        return "\\"
    end
    local tail
    if rootEnd < len then
        tail = ____exports.normalizeString(
            nil,
            __TS__StringSlice(path, rootEnd),
            not isAbsolute,
            "\\",
            ____exports.isPathSeparator
        )
    else
        tail = ""
    end
    if #tail == 0 and not isAbsolute then
        tail = "."
    end
    if #tail > 0 and ____exports.isPathSeparator(
        nil,
        __TS__StringCharCodeAt(path, len - 1)
    ) then
        tail = tail .. "\\"
    end
    if device == nil then
        if isAbsolute then
            if #tail > 0 then
                return "\\" .. tail
            else
                return "\\"
            end
        elseif #tail > 0 then
            return tail
        else
            return ""
        end
    elseif isAbsolute then
        if #tail > 0 then
            return (device .. "\\") .. tail
        else
            return device .. "\\"
        end
    elseif #tail > 0 then
        return device .. tail
    else
        return device
    end
end

--- Verifies whether path is absolute
--
-- @param path to verify
function ____exports.isAbsolute(self, path)
    local len = #path
    if len == 0 then
        return false
    end
    local code = string.byte(path, 1) or 0 / 0
    if ____exports.isPathSeparator(nil, code) then
        return true
    elseif ____exports.isWindowsDeviceRoot(nil, code) then
        if len > 2 and (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
            if ____exports.isPathSeparator(
                nil,
                string.byte(path, 3) or 0 / 0
            ) then
                return true
            end
        end
    end
    return false
end

--- Join all given a sequence of `paths`,then normalizes the resulting path.
--
-- @param paths to be joined and normalized
function ____exports.join(self, ...)
    local paths = { ... }
    local pathsCount = #paths
    if pathsCount == 0 then
        return "."
    end
    local joined
    local firstPart = nil
    do
        local i = 0
        while i < pathsCount do
            local path = paths[i + 1]
            if #path > 0 then
                if joined == nil then
                    firstPart = path
                    joined = firstPart
                else
                    joined = joined .. "\\" .. path
                end
            end
            i = i + 1
        end
    end
    if joined == nil then
        return "."
    end
    local needsReplace = true
    local slashCount = 0
    if firstPart == nil then
        return "error"
    end
    if ____exports.isPathSeparator(
        nil,
        string.byte(firstPart, 1) or 0 / 0
    ) then
        slashCount = slashCount + 1
        local firstLen = #firstPart
        if firstLen > 1 then
            if ____exports.isPathSeparator(
                nil,
                string.byte(firstPart, 2) or 0 / 0
            ) then
                slashCount = slashCount + 1
                if firstLen > 2 then
                    if ____exports.isPathSeparator(
                        nil,
                        string.byte(firstPart, 3) or 0 / 0
                    ) then
                        slashCount = slashCount + 1
                    else
                        needsReplace = false
                    end
                end
            end
        end
    end
    if needsReplace then
        do
            while slashCount < #joined do
                if not ____exports.isPathSeparator(
                    nil,
                    __TS__StringCharCodeAt(joined, slashCount)
                ) then
                    break
                end
                slashCount = slashCount + 1
            end
        end
        if slashCount >= 2 then
            joined = "\\" .. __TS__StringSlice(joined, slashCount)
        end
    end
    return ____exports.normalize(nil, joined)
end

--- It will solve the relative path from `from` to `to`, for instance:
--  from = 'C:\\orandea\\test\\aaa'
--  to = 'C:\\orandea\\impl\\bbb'
-- The output of the function should be: '..\\..\\impl\\bbb'
--
-- @param from relative path
-- @param to relative path
function ____exports.relative(self, from, to)
    if from == to then
        return ""
    end
    local fromOrig = ____exports.resolve(nil, from)
    local toOrig = ____exports.resolve(nil, to)
    if fromOrig == toOrig then
        return ""
    end
    from = string.lower(fromOrig)
    to = string.lower(toOrig)
    if from == to then
        return ""
    end
    local fromStart = 0
    local fromEnd = #from
    do
        while fromStart < fromEnd do
            if __TS__StringCharCodeAt(from, fromStart) ~= CHAR_BACKWARD_SLASH then
                break
            end
            fromStart = fromStart + 1
        end
    end
    do
        while fromEnd - 1 > fromStart do
            if __TS__StringCharCodeAt(from, fromEnd - 1) ~= CHAR_BACKWARD_SLASH then
                break
            end
            fromEnd = fromEnd - 1
        end
    end
    local fromLen = fromEnd - fromStart
    local toStart = 0
    local toEnd = #to
    do
        while toStart < toEnd do
            if __TS__StringCharCodeAt(to, toStart) ~= CHAR_BACKWARD_SLASH then
                break
            end
            toStart = toStart + 1
        end
    end
    do
        while toEnd - 1 > toStart do
            if __TS__StringCharCodeAt(to, toEnd - 1) ~= CHAR_BACKWARD_SLASH then
                break
            end
            toEnd = toEnd - 1
        end
    end
    local toLen = toEnd - toStart
    local length = fromLen < toLen and fromLen or toLen
    local lastCommonSep = -1
    local i = 0
    do
        while i <= length do
            if i == length then
                if toLen > length then
                    if __TS__StringCharCodeAt(to, toStart + i) == CHAR_BACKWARD_SLASH then
                        return __TS__StringSlice(toOrig, toStart + i + 1)
                    elseif i == 2 then
                        return __TS__StringSlice(toOrig, toStart + i)
                    end
                end
                if fromLen > length then
                    if __TS__StringCharCodeAt(from, fromStart + i) == CHAR_BACKWARD_SLASH then
                        lastCommonSep = i
                    elseif i == 2 then
                        lastCommonSep = 3
                    end
                end
                break
            end
            local fromCode = __TS__StringCharCodeAt(from, fromStart + i)
            local toCode = __TS__StringCharCodeAt(to, toStart + i)
            if fromCode ~= toCode then
                break
            elseif fromCode == CHAR_BACKWARD_SLASH then
                lastCommonSep = i
            end
            i = i + 1
        end
    end
    if i ~= length and lastCommonSep == -1 then
        return toOrig
    end
    local out = ""
    if lastCommonSep == -1 then
        lastCommonSep = 0
    end
    do
        i = fromStart + lastCommonSep + 1
        while i <= fromEnd do
            if i == fromEnd or __TS__StringCharCodeAt(from, i) == CHAR_BACKWARD_SLASH then
                if #out == 0 then
                    out = out .. ".."
                else
                    out = out .. "\\.."
                end
            end
            i = i + 1
        end
    end
    if #out > 0 then
        return out .. __TS__StringSlice(toOrig, toStart + lastCommonSep, toEnd)
    else
        toStart = toStart + lastCommonSep
        if __TS__StringCharCodeAt(toOrig, toStart) == CHAR_BACKWARD_SLASH then
            toStart = toStart + 1
        end
        return __TS__StringSlice(toOrig, toStart, toEnd)
    end
end

--- Resolves path to a namespace path
--
-- @param path to resolve to namespace
function ____exports.toNamespacedPath(self, path)
    if type(path) ~= "string" then
        return path
    end
    if #path == 0 then
        return ""
    end
    local resolvedPath = ____exports.resolve(nil, path)
    if #resolvedPath >= 3 then
        if (string.byte(resolvedPath, 1) or 0 / 0) == CHAR_BACKWARD_SLASH then
            if (string.byte(resolvedPath, 2) or 0 / 0) == CHAR_BACKWARD_SLASH then
                local code = string.byte(resolvedPath, 3) or 0 / 0
                if code ~= CHAR_QUESTION_MARK and code ~= CHAR_DOT then
                    return "\\\\?\\UNC\\" .. string.sub(resolvedPath, 3)
                end
            end
        elseif ____exports.isWindowsDeviceRoot(
            nil,
            string.byte(resolvedPath, 1) or 0 / 0
        ) then
            if (string.byte(resolvedPath, 2) or 0 / 0) == CHAR_COLON and
                (string.byte(resolvedPath, 3) or 0 / 0) == CHAR_BACKWARD_SLASH then
                return "\\\\?\\" .. resolvedPath
            end
        end
    end
    return path
end

--- Return the directory path of a `path`.
--
-- @param path to determine the directory path for
function ____exports.dirname(self, path)
    local len = #path
    if len == 0 then
        return "."
    end
    local rootEnd = -1
    local ____end = -1
    local matchedSlash = true
    local offset = 0
    local code = string.byte(path, 1) or 0 / 0
    if len > 1 then
        if ____exports.isPathSeparator(nil, code) then
            offset = 1
            rootEnd = offset
            if ____exports.isPathSeparator(
                nil,
                string.byte(path, 2) or 0 / 0
            ) then
                local j = 2
                local last = j
                do
                    while j < len do
                        if ____exports.isPathSeparator(
                            nil,
                            __TS__StringCharCodeAt(path, j)
                        ) then
                            break
                        end
                        j = j + 1
                    end
                end
                if j < len and j ~= last then
                    last = j
                    do
                        while j < len do
                            if not ____exports.isPathSeparator(
                                nil,
                                __TS__StringCharCodeAt(path, j)
                            ) then
                                break
                            end
                            j = j + 1
                        end
                    end
                    if j < len and j ~= last then
                        last = j
                        do
                            while j < len do
                                if ____exports.isPathSeparator(
                                    nil,
                                    __TS__StringCharCodeAt(path, j)
                                ) then
                                    break
                                end
                                j = j + 1
                            end
                        end
                        if j == len then
                            return path
                        end
                        if j ~= last then
                            offset = j + 1
                            rootEnd = offset
                        end
                    end
                end
            end
        elseif ____exports.isWindowsDeviceRoot(nil, code) then
            if (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
                offset = 2
                rootEnd = offset
                if len > 2 then
                    if ____exports.isPathSeparator(
                        nil,
                        string.byte(path, 3) or 0 / 0
                    ) then
                        offset = 3
                        rootEnd = offset
                    end
                end
            end
        end
    elseif ____exports.isPathSeparator(nil, code) then
        return path
    end
    do
        local i = len - 1
        while i >= offset do
            if ____exports.isPathSeparator(
                nil,
                __TS__StringCharCodeAt(path, i)
            ) then
                if not matchedSlash then
                    ____end = i
                    break
                end
            else
                matchedSlash = false
            end
            i = i - 1
        end
    end
    if ____end == -1 then
        if rootEnd == -1 then
            return "."
        else
            ____end = rootEnd
        end
    end
    return __TS__StringSlice(path, 0, ____end)
end

--- Return the last portion of a `path`. Trailing directory separators are ignored.
--
-- @param path to process
-- @param ext of path directory
function ____exports.basename(self, path, ext)
    if ext == nil then
        ext = ""
    end
    if ext ~= nil and type(ext) ~= "string" then
        error(
            "\"ext\" argument must be a string",
            0
        )
    end
    local start = 0
    local ____end = -1
    local matchedSlash = true
    local i
    if #path >= 2 then
        local drive = string.byte(path, 1) or 0 / 0
        if ____exports.isWindowsDeviceRoot(nil, drive) then
            if (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
                start = 2
            end
        end
    end
    if ext ~= nil and #ext > 0 and #ext <= #path then
        if #ext == #path and ext == path then
            return ""
        end
        local extIdx = #ext - 1
        local firstNonSlashEnd = -1
        do
            i = #path - 1
            while i >= start do
                local code = __TS__StringCharCodeAt(path, i)
                if ____exports.isPathSeparator(nil, code) then
                    if not matchedSlash then
                        start = i + 1
                        break
                    end
                else
                    if firstNonSlashEnd == -1 then
                        matchedSlash = false
                        firstNonSlashEnd = i + 1
                    end
                    if extIdx >= 0 then
                        if code == __TS__StringCharCodeAt(ext, extIdx) then
                            extIdx = extIdx - 1
                            if extIdx == -1 then
                                ____end = i
                            end
                        else
                            extIdx = -1
                            ____end = firstNonSlashEnd
                        end
                    end
                end
                i = i - 1
            end
        end
        if start == ____end then
            ____end = firstNonSlashEnd
        elseif ____end == -1 then
            ____end = #path
        end
        return __TS__StringSlice(path, start, ____end)
    else
        do
            i = #path - 1
            while i >= start do
                if ____exports.isPathSeparator(
                    nil,
                    __TS__StringCharCodeAt(path, i)
                ) then
                    if not matchedSlash then
                        start = i + 1
                        break
                    end
                elseif ____end == -1 then
                    matchedSlash = false
                    ____end = i + 1
                end
                i = i - 1
            end
        end
        if ____end == -1 then
            return ""
        end
        return __TS__StringSlice(path, start, ____end)
    end
end

--- Return the extension of the `path` with leading period.
--
-- @param path with extension
-- @returns extension (ex. for `file.ts` returns `.ts`)
function ____exports.extname(self, path)
    local start = 0
    local startDot = -1
    local startPart = 0
    local ____end = -1
    local matchedSlash = true
    local preDotState = 0
    if #path >= 2 and (string.byte(path, 2) or 0 / 0) == CHAR_COLON and ____exports.isWindowsDeviceRoot(
        nil,
        string.byte(path, 1) or 0 / 0
    ) then
        startPart = 2
        start = startPart
    end
    do
        local i = #path - 1
        while i >= start do
            do
                local code = __TS__StringCharCodeAt(path, i)
                if ____exports.isPathSeparator(nil, code) then
                    if not matchedSlash then
                        startPart = i + 1
                        break
                    end
                    goto __continue214
                end
                if ____end == -1 then
                    matchedSlash = false
                    ____end = i + 1
                end
                if code == CHAR_DOT then
                    if startDot == -1 then
                        startDot = i
                    elseif preDotState ~= 1 then
                        preDotState = 1
                    end
                elseif startDot ~= -1 then
                    preDotState = -1
                end
            end
            ::__continue214::
            i = i - 1
        end
    end
    if startDot == -1 or ____end == -1 or preDotState == 0 or
        preDotState == 1 and startDot == ____end - 1 and startDot == startPart + 1 then
        return ""
    end
    return __TS__StringSlice(path, startDot, ____end)
end

--- Generate a path from `FormatInputPathObject` object.
--
-- @param pathObject with path
function ____exports.format(self, pathObject)
    if pathObject == nil or type(pathObject) ~= "table" then
        error(

            "The \"pathObject\" argument must be of type Object. Received type " .. __TS__TypeOf(pathObject)
            ,
            0
        )
    end
    return ____exports._format(nil, "\\", pathObject)
end

--- Return a `ParsedPath` object of the `path`.
--
-- @param path to process
function ____exports.parse(self, path)
    local ret = {
        root = "",
        dir = "",
        base = "",
        ext = "",
        name = ""
    }
    local len = #path
    if len == 0 then
        return ret
    end
    local rootEnd = 0
    local code = string.byte(path, 1) or 0 / 0
    if len > 1 then
        if ____exports.isPathSeparator(nil, code) then
            rootEnd = 1
            if ____exports.isPathSeparator(
                nil,
                string.byte(path, 2) or 0 / 0
            ) then
                local j = 2
                local last = j
                do
                    while j < len do
                        if ____exports.isPathSeparator(
                            nil,
                            __TS__StringCharCodeAt(path, j)
                        ) then
                            break
                        end
                        j = j + 1
                    end
                end
                if j < len and j ~= last then
                    last = j
                    do
                        while j < len do
                            if not ____exports.isPathSeparator(
                                nil,
                                __TS__StringCharCodeAt(path, j)
                            ) then
                                break
                            end
                            j = j + 1
                        end
                    end
                    if j < len and j ~= last then
                        last = j
                        do
                            while j < len do
                                if ____exports.isPathSeparator(
                                    nil,
                                    __TS__StringCharCodeAt(path, j)
                                ) then
                                    break
                                end
                                j = j + 1
                            end
                        end
                        if j == len then
                            rootEnd = j
                        elseif j ~= last then
                            rootEnd = j + 1
                        end
                    end
                end
            end
        elseif ____exports.isWindowsDeviceRoot(nil, code) then
            if (string.byte(path, 2) or 0 / 0) == CHAR_COLON then
                rootEnd = 2
                if len > 2 then
                    if ____exports.isPathSeparator(
                        nil,
                        string.byte(path, 3) or 0 / 0
                    ) then
                        if len == 3 then
                            local ____path_10 = path
                            ret.dir = ____path_10
                            ret.root = ____path_10
                            return ret
                        end
                        rootEnd = 3
                    end
                else
                    local ____path_11 = path
                    ret.dir = ____path_11
                    ret.root = ____path_11
                    return ret
                end
            end
        end
    elseif ____exports.isPathSeparator(nil, code) then
        local ____path_12 = path
        ret.dir = ____path_12
        ret.root = ____path_12
        return ret
    end
    if rootEnd > 0 then
        ret.root = __TS__StringSlice(path, 0, rootEnd)
    end
    local startDot = -1
    local startPart = rootEnd
    local ____end = -1
    local matchedSlash = true
    local i = #path - 1
    local preDotState = 0
    do
        while i >= rootEnd do
            do
                code = __TS__StringCharCodeAt(path, i)
                if ____exports.isPathSeparator(nil, code) then
                    if not matchedSlash then
                        startPart = i + 1
                        break
                    end
                    goto __continue248
                end
                if ____end == -1 then
                    matchedSlash = false
                    ____end = i + 1
                end
                if code == CHAR_DOT then
                    if startDot == -1 then
                        startDot = i
                    elseif preDotState ~= 1 then
                        preDotState = 1
                    end
                elseif startDot ~= -1 then
                    preDotState = -1
                end
            end
            ::__continue248::
            i = i - 1
        end
    end
    if startDot == -1 or ____end == -1 or preDotState == 0 or
        preDotState == 1 and startDot == ____end - 1 and startDot == startPart + 1 then
        if ____end ~= -1 then
            local ____TS__StringSlice_result_13 = __TS__StringSlice(path, startPart, ____end)
            ret.name = ____TS__StringSlice_result_13
            ret.base = ____TS__StringSlice_result_13
        end
    else
        ret.name = __TS__StringSlice(path, startPart, startDot)
        ret.base = __TS__StringSlice(path, startPart, ____end)
        ret.ext = __TS__StringSlice(path, startDot, ____end)
    end
    if startPart > 0 and startPart ~= rootEnd then
        ret.dir = __TS__StringSlice(path, 0, startPart - 1)
    else
        ret.dir = ret.root
    end
    return ret
end

local inspect = require "lua_modules.inspect"

local print = function(...)
    local t = { ... }
    for index, value in pairs(t) do
        _G.print(value)
    end
end

-- print(____exports.resolve(nil, "Hello", "d:World.js"))
print(____exports.normalizeString(nil, "..\\C:\\temp\\\\foo\\bar\\..\\", false, "\\"))
-- print(____exports.normalizeString(nil, "C:\\temp\\hello\\..\\world", false, "\\"))

print(____exports.dirname(nil, '/foo/bar/baz/asdf/quux'))

-- print(
--     --
--     ____exports.relative(nil, 'C:\\orandea\\test\\aaa', 'C:\\orandea\\impl\\bbb'),
--     -- // Returns: '/foo/bar/baz/asdf'
--     ____exports.normalize(nil, '/foo/bar//baz/asdf/quux/..'),
--     -- // Returns: 'C:\\temp\\foo\\'
--     ____exports.normalize(nil, 'C:\\temp\\\\foo\\bar\\..\\'),
--     -- // Returns:
--     -- // { root: 'C:\\',
--     -- //   dir: 'C:\\path\\dir',
--     -- //   base: 'file.txt',
--     -- //   ext: '.txt',
--     -- //   name: 'file' }
--     inspect(____exports.parse(nil, 'C:\\path\\dir\\file.txt')),
--     inspect(__TS__StringSplit('foo\\bar\\baz', "\\")),
--     ____exports.toNamespacedPath(nil, "C:\\Windows\\users\\..\\admin"),
--     ____exports.basename(nil, 'C:\\foo.html', '.html'),
--     ____exports.dirname(nil, '/foo/bar/baz/asdf/quux'),
--     ____exports.extname(nil, 'index.html.md'),
--     -- // Returns: 'C:\\path\\dir\\file.txt'
--     ____exports.format(nil, {
--         dir = 'C:\\path\\dir',
--         base = 'file.txt',
--     }),
--     ____exports.isAbsolute(nil, '//server'), -- true
--     ____exports.isAbsolute(nil, '\\\\server'), -- true
--     ____exports.isAbsolute(nil, 'C:/foo/..'), -- true
--     ____exports.isAbsolute(nil, 'C:\\foo\\..'), -- true
--     ____exports.isAbsolute(nil, 'bar\\baz'), -- false
--     ____exports.isAbsolute(nil, 'bar/baz'), -- false
--     ____exports.isAbsolute(nil, '.'), -- false
--     -- // Returns: '/foo/bar/baz/asdf'
--     ____exports.join(nil, '/foo', 'bar', 'baz/asdf', 'quux', '..'),
--     -- // Returns: 'C:\\temp\\foo\\bar'
--     ____exports.normalize(nil, 'C:////temp\\\\/\\/\\/foo/bar')
-- )

return ____exports
