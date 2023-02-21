--[[
    References:
    https://medium.com/swlh/lets-build-a-linux-shell-part-ii-340ecf471028
    https://medium.com/@mohammedisam2000/lets-build-a-linux-shell-part-iii-a472c0102849
    - convar.cpp
    CCommand::CCommand
    CCommand::Tokenize
    - commandbuffer.cpp
    CCommandBuffer::GetNextCommandLength
    -- https://github.com/mpeterv/argparse
-- https://docs.python.org/3/howto/argparse.html#id1
-- https://github.com/cofyc/argparse

]]
local function printLuaTable(a, indent)
    if a == nil then
        print("nil")
        return
    end
    if indent == nil then indent = 0 end
    for b, c in pairs(a) do
        if type(c) == "table" then
            print(string.rep("  ", indent) .. tostring(b) .. ":")
            printLuaTable(c, indent + 1)
        else
            print(string.rep("  ", indent) .. tostring(b) .. ": " .. tostring(c))
        end
    end
end

local CHAR_SPACE = 32
local CHAR_QUOTE = 34
local CHAR_APOSTROPHE = 39
local CHAR_SEMICOLON = 59
local ascii_map = {
    [32] = " ",
    [34] = "\"",
    [39] = "'",
    [59] = ";"
}

local function command_buffer_parse(buffer)
    local size, count, commands = string.len(buffer), 0, {}
    local start, length = 1, 0

    for i = 1, size + 1 do
        local code = string.byte(buffer, i, i)

        if code == nil or code == 59 then
            if length ~= 0 then
                count = count + 1
                commands[count] = string.sub(buffer, start, start + length - 1)
                length = 0
            end
            start = i + 1
            goto continue
        end

        length = length + 1
        ::continue::
    end

    commands.n = count
    return commands
end

local function command_tokenizer(command)

end

local function shell_buffer_parse(buffer)

end
local function shell_tokenizer(command)
    local size, count, values = string.len(command), 0, {}
    local i, start, length = 1, 1, 0

    repeat
        local code = string.byte(command, i, i)

        if code == CHAR_QUOTE or code == CHAR_APOSTROPHE then
            start = i + 1
            local stop = string.find(command, ascii_map[code], start, true)
            if stop ~= nil then
                i = stop
                length = stop - start
                goto extract
            end
            goto continue
        end

        if code == nil or code == CHAR_SPACE then
            goto extract
        end

        length = length + 1
        goto continue

        ::extract::
        if length ~= 0 then
            count         = count + 1
            values[count] = string.sub(command, start, start + length - 1)
        end
        length = 0
        start  = i + 1
        ::continue::
        i = i + 1
    until i == size + 2

    values.n = count
    return values
end

local function argument_parser(name)

end

local function add_argument()

end

local function add_argument_help()

end


-- local PATH = {}
-- callbacks.Register("SendStringCmd", function(msg) ---@param msg StringCmd
--     local command = msg:Get()
    
-- end)

-- local function main()
--     local app = argument_parser("argparse")
--     app.add_description("argparse for lmaobox lua")
--     app.add_argument("--beep").help("Play Sentry Gun Beeping Sound.")
--     app.add_argument("-?", "-h", "--help").help("Shows help about the selected command")
--     app.add_argument("-v", "--version").help("Display the version information")

--     local parse = app.add_command("parse")
--     parse.add_description("Parse a command buffer.")
-- end

local krits = draw.CreateTexture([[E:\SteamLibrary\steamapps\common\Team Fortress 2\tf\custom\flawhud\materials\vgui\replay\thumbnails\kritz.vtf]])

callbacks.Register("Draw", function ()
    draw.TexturedRect(krits, 0, 0, 100, 100)
end)