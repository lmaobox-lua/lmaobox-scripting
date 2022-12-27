local function isdir(a)
    return a ~= 0xFFFFFFFF and a & 0x10 ~= 0
end

local function join(...)
    return table.concat({ ... }, '/')
end

local scripts = {}
-- Replace all backslashes with forward slashes and truncate starting from last slashes
local root = engine.GetGameDir():gsub('\\', '/'):gsub('/[^/]+$', '') .. '/lmaobox-scripting'

local function iter(filename, fields)
    if filename ~= '.' and filename ~= '..' then
        if filename:match('[^.]+$') == 'lua' and not isdir(fields) then
            if not scripts[filename] then
                scripts[filename] = join(root, filename)
                scripts[filename:gsub('.[^.]+$', '')] = join(root, filename)
            end
            return
        end
    end
end

local lastUpd = 0
local interval = 1

callbacks.Unregister('SendStringCmd', '----')
callbacks.Register('SendStringCmd', '----', function(o)
    local cmd = o:Get()
    if cmd:sub(1, 8) == 'lua_file' then
        if os.time() > lastUpd then
            --- gay ass solution til i figure out recursion
            filesystem.EnumerateDirectory('./lmaobox-scripting/*', iter)
            -- filesystem.EnumerateDirectory('./lmaobox-scripting/lua/*', iter)
            lastUpd = os.time() + interval
        end
        o:Set('')
        local rel = cmd:sub(10)
        if #rel == 0 then
            for k, v in pairs(scripts) do
                print(k)
            end
            return
        end
        local ret = scripts[rel] and LoadScript(scripts[rel]) or false
        printc(125, 0, 88, 255, string.format('attempt to load script %s (result : %s)', rel, ret))
    end
    if cmd:sub(1, 11) == 'lua_unload ' then
        local p = cmd:sub(12)
        if #p == 0 then
            return
        end
        o:Set('')
        local ret = scripts[p] and UnloadScript(scripts[p]) or UnloadScript(p)
        printc(125, 0, 88, 255,
               string.format('attempt to unload script %s (result : %s) (where: %s)', p, ret, scripts[p] or p))
    end
end)

package.path=package.path .. ';E:/SteamLibrary/steamapps/common/Team Fortress 2/lmaobox-scripting/?.lua' .. ';E:/SteamLibrary/steamapps/common/Team Fortress 2/lmaobox-scripting/../?.lua'
package.cpath=package.path .. ';E:/SteamLibrary/steamapps/common/Team Fortress 2/lmaobox-scripting/?.dll' .. ';E:/SteamLibrary/steamapps/common/Team Fortress 2/lmaobox-scripting/../?.dll'
