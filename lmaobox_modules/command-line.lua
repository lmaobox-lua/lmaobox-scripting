local convar = {}

local function add(name, callbacks)
    if convar[name] ~= nil then
        error(string.format("Convar %q already exists", name), 2)
    end
    local index            = #convar.identifier + 1
    convar[name]           = index
    convar.callback[index] = callbacks
    return true
end

local function remove(name)
    local index            = convar[name]
    convar.callback[index] = nil
    convar[name]           = nil
    return true
end

local CHAR_SPACE = 32 -- ' '
local CHAR_QUOTE = 34 -- '"'
local CHAR_SINGLE_QUOTE = 39 -- "'"

callbacks.Register('SendStringCmd', 'command-line-interface', function(string_cmd) ---@param string_cmd StringCmd
    local input, length, position, captured, convar
    input    = string_cmd:Get()
    length   = string.len(input)
    position = 1
    captured = 0
    local segments, index, in_quote
    segments = {}
    index    = 0

    while position <= length do
        local code = string.byte(input, position)

        if code == CHAR_QUOTE or code == CHAR_SINGLE_QUOTE then
            in_quote = not in_quote
        end

        if code ~= CHAR_SPACE or in_quote then
            captured = captured + 1
            goto __continue__
        end

        index           = index + 1
        segments[index] = string.sub(input, position - captured, position - 1)
        captured        = 0

        ::__continue__::
        position = position + 1
    end

    printLuaTable(segments)

    if captured ~= 0 then
        index           = index + 1
        segments[index] = string.sub(input, position - captured, position - 1)
    end

    if index == 0 then
        return
    end

    if segments[1] ~= 'do' then
        return
    end

    string_cmd:Set('')
    convar = segments[2]

    printc(102, 204, 153, 255, "Unknown command: " .. convar)
    printc(204, 255, 255, 255, "Type 'do' for a list of commands")
end)
