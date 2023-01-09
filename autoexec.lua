local tf2_directory, script_name
do
    tf2_directory = assert(engine.GetGameDir():gsub('\\', '/'):gsub('/[^/]+$', ''))
    script_name = assert(GetScriptName():match('[^\\]*.lua$'))

    package.path =
    package.path
        .. ';' .. tf2_directory .. '/?.lua'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/?.lua'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/lua_modules/?.lua'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/lmaobox_modules/?.lua'
    package.cpath =
    package.cpath
        .. ';' .. tf2_directory .. '/?.dll'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/?.dll'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/lua_modules/?.dll'
        .. ';' .. tf2_directory .. '/lmaobox-scripting/lmaobox_modules/?.dll'
end

local console = {}
local where = package.path

local function list_console_variable()
    for key, value in pairs(console) do
        if key ~= 'lua_cvar' then
            printc(204, 255, 255, 255, key .. " " .. "(" .. tostring(value) .. ")")
        end
    end
end

function console.load(modname)
    local path = package.searchpath(modname, where, ".", "/") or modname
    printc(102, 204, 153, 255, "LoadScript([[" .. path .. "]])")
    LoadScript(path)
end

function console.unload(modname)
    local path = package.searchpath(modname, where, ".", "/") or modname
    printc(102, 204, 153, 255, "UnloadScript([[" .. path .. "]])")
    print(UnloadScript(path))
end

function console.reload_me()
    printc(153, 204, 153, 255, "('>`.__.`<)")
    LoadScript(GetScriptName())
end

function console.target(steamid, priority)
    local priority = priority or 5
    print(playerlist.SetPriority(steamid, priority))
    printc(102, 204, 153, 255, "Player Priority" .. " '" .. steam.GetPlayerName(steamid) .. "' " .. "is now " .. priority)
end

-- local cvar = {}
-- function console.setcvar(variable_name, value)
--     if value == nil then
--         cvar[variable_name] = nil
--     end
-- end
-- local cvar_timer, cvar_update_interval = -1, 0.1
-- callbacks.Register("Draw", "autoexec.setcvar.Timer", function ()
--     if globals.CurTime() > cvar_timer then
--         cvar_timer = globals.CurTime() + cvar_update_interval
--         for variable_name, value in pairs(cvar) do
--             client.SetConVar(variable_name, value)
--         end
--     end
-- end)

-- code point constants
local CHAR_SPACE = 32 -- ' '
local CHAR_QUOTE = 34 -- '"'
local CHAR_SINGLE_QUOTE = 39 -- "'"

callbacks.Unregister('SendStringCmd', 'autoexec.SendStringCmd')
callbacks.Register('SendStringCmd', 'autoexec.SendStringCmd', function(string_cmd) ---@param string_cmd StringCmd
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
            goto __capture__
        end

        if code ~= CHAR_SPACE or in_quote then
            captured = captured + 1
            goto __continue__
        end

        ::__capture__::
        if captured == 0 then
            goto __continue__
        end

        index           = index + 1
        segments[index] = string.sub(input, position - captured, position - 1)
        captured        = 0

        ::__continue__::
        position = position + 1
    end

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

    if convar == nil then
        return list_console_variable()
    end

    local command = console[convar]
    printc(255, 255, 153, 255, ".." .. script_name .. ":")

    if type(command) == "function" then
        command(table.unpack(segments, 3))
        return
    end

    printc(102, 204, 153, 255, "Unknown command: " .. convar)
    printc(204, 255, 255, 255, "Type 'do' for a list of commands")
end)
