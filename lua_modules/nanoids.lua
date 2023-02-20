--[[
    Translated from https://github.com/radeno/nanoid.rb
     Created in 2023 by Lewd Developer.
--]]

local function string_to_table(s)
    local t = {}
    for i = 1, #s do
        t[i - 1] = s:sub(i, i)
    end
    return t
end

local DEFAULT_SIZE = 21
local SAFE_ALPHABET = '_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
local SAFE_ALPHABET_SIZE = #SAFE_ALPHABET
local SAFE_ALPHABET_ARRAY = string_to_table(SAFE_ALPHABET)
local ceil, log, type = math.ceil, math.log, math.type
local RANDOM

if _G.engine then
    local randint, randflt = engine.RandomInt, engine.RandomFloat
    function RANDOM(n, m)
        if type(n) == "integer" and type(m) == 'integer' then
            return randint(n, m)
        end
        return randflt(n, m)
    end
else
    RANDOM = math.random
end

---@param size integer
---@param alphabet string
local function non_secure_generate(size, alphabet)
    local alphabet_size  = #alphabet
    local alphabet_array = string_to_table(alphabet)
    local id             = {}
    for index = 1, size do
        id[index] = alphabet_array[(RANDOM() * alphabet_size // 1)]
    end
    return table.concat(id)
end

---@param size integer
local function simple_generate(size)
    local alphabet_array = SAFE_ALPHABET_ARRAY
    local id             = {}
    for index = 1, size do
        id[index] = alphabet_array[RANDOM(0, 0xFF) & 63]
    end
    return table.concat(id)
end

---@param size integer
---@param alphabet string
local function complex_generate(size, alphabet)
    local alphabet_size  = #alphabet
    local alphabet_array = string_to_table(alphabet)
    local mask           = (2 << (log(alphabet_size - 1) / log(2) // 1)) - 1
    local step           = ceil(1.6 * mask * size / alphabet_size)
    local id             = {}
    local index          = 0
    for i = 1, step do
        if index == size then
            break
        end
        local character = alphabet_array[RANDOM(0, 0xFF) & mask]
        if character then
            index = index + 1
            id[index] = character
        end
    end
    return table.concat(id)
end

local nanoids = {}

---@param size integer?
---@param alphabet string?
---@param non_secure boolean? @If true, perform less complex random generation
function nanoids.generate(size, alphabet, non_secure)
    size       = size or DEFAULT_SIZE
    alphabet   = alphabet or SAFE_ALPHABET
    non_secure = not not non_secure

    if non_secure then
        return non_secure_generate(size, alphabet)
    end

    if alphabet == SAFE_ALPHABET then
        return simple_generate(size)
    end

    return complex_generate(size, alphabet)
end

return nanoids
