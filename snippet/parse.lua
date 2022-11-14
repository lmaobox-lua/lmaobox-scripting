
---@alias parse
e_parse = {}

function e_parse.C_to_boolean(value)
    return (value ~= 0 and value) and 1 or 0
end

--- shallow copy table keys to another table
---@param from table
---@param to   table
---@return boolean
function e_parse.shallow_copy(from, to)
    for k, v in pairs(from) do
        to[k] = v
    end
    return true
end

--- construct a keytable value with value
---@param size number
---@param ...  any
function e_parse.va_list(size, ...)
    local arg = {...}
    local t = {}
    for i = 1, size do
        t[arg[math.ceil(size / 2) + i + 1] or i] = arg[i]
    end
    return t
end

--- pack 4 unsigned bytes to unsigned int
---@param byte number
---@param byte number
---@param byte number
---@param byte number
function e_parse.uint32(...)
    local arg = {...}
    local u32 = 0
    local size = 4
    for i = 1, size, 1 do
        u32 = u32 | (arg[i] & 0xff) << (size - i) * 8
    end
    return u32
end

--- unpack unsigned int to 4 unsigned bytes
--- @param u32 number
function e_parse.to_byte(u32)
    local arg = {}
    local size = 4
    for i = size, 1, -1 do
        table.insert(arg, u32 >> ((size - i) * 8))
    end
    return arg
end

return e_parse