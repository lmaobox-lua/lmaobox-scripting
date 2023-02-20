-- Current path is: "C:\\"
-- Current root name is: "C:"
-- Current root directory is: "\\"
-- Current root path is: "C:\\"
-- Current relative path is: "Users\\mayakey\\Desktop\\filesystem\\filesystem\\out\\build\\x64-debug\\filesystem.exe"
-- Current parent path is: "C:\\Users\\mayakey\\Desktop\\filesystem\\filesystem\\out\\build\\x64-debug"
-- Current filename is: "filesystem.exe"
-- Current stem is: "filesystem"
-- Current extension is: ".exe"

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

local directory_seperator, posix_directory_seperator, win32_delimiter
directory_seperator       = "\\"
posix_directory_seperator = "/"
win32_delimiter           = ";"

local function is_directory_seperator(code)
    return code == CHAR_FORWARD_SLASH or code == CHAR_BACKWARD_SLASH
end

local function is_windows_device_root(code)
    return (code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z) or
        (code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z)
end

local function normalize_string(path, allow_above_root, seperator)
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
                        local where_slash = string_last_index_of(res, seperator)
                        if where_slash == 0 then
                            res = ""
                            last_segment_length = 0
                        else
                            res = string.sub(res, 1, where_slash - 1)
                            last_segment_length = string.len(res) - string_last_index_of(res, seperator)
                        end
                        goto __final__
                    end
                end

                if allow_above_root then
                    if res_length > 0 then
                        res = res .. seperator .. ".."
                    else
                        res = '..'
                    end
                    last_segment_length = 2
                end
                goto __final__
            end

            if res_length > 0 then
                res = res .. seperator .. string.sub(path, slash_position + 1, current - 1)
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

print(normalize_string([[D::\Users\\foo\bar\..\baz_asdf\quux\..\]], true, directory_seperator))


local function normalize_path(path, allow_above_root, seperator)
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
                -- if allow_above_root then
                --     index        = index - 1
                -- end
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

    return table.concat(paths, seperator, 1, index)
end
