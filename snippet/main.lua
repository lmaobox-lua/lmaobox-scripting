-- LoadScript([[C:\Users\mayakey\AppData\Local\lbox\lua\luapath.lua]])
-- local luapath, where = require('luapath')
-- assert(package.loaded['luapath'])
--- settings.json
LoadScript([[C:\Users\mayakey\AppData\Local\lbox\lua\dkjson.lua]])
local json = require 'dkjson'

local function create_folder(path)
    return filesystem.CreateDirectory(path) or
               (filesystem.GetFileAttributes(path) & 0x10 ~= 0 and filesystem.GetFileAttributes(path) ~= 0xFFFFFFFF)
end

--- @class module
local datafile = {
    _NAME = 'datafile',
    _VERSION = 'datafile 1.0',
    _DESCRIPTION = 'datafile is a basic config manager for lmaobox lua.',
    _AUTHOR = 'Moonverse#9320'
 }

datafile.storage = {
    memory = {},
    tmpfile = {},
    user = {}
 }

function datafile.find(where, key)

end

function datafile.update(where, key, value)

end

function datafile.merge(where, to, key, overwrite)

end

function datafile.use(key, obj)
end

---@region tests
datafile.tests = {
    [1] = function()
        local f = io.tmpfile()
        local t = { {
            dictionary = {
                a = 1,
                b = '2',
                c = '可靠小弟',
                d = 'a ă ắ ằ ẳ ẵ ẽ ế ề ể'
             },
            array = { 1, 3, 5, 7, 9 }
         } }
        local buffer, str = {}
        assert(json.encode(t, {
            indent = false,
            keyorder = { '_AUTHOR', '_VERSION', '_DESCRIPTION', 'array', 'dictionary' },
            level = 0,
            buffer = buffer,
            bufferlen = 0,
            tables = {},
            exception = json.encodeexception
         }) == true)
        str = table.concat(buffer)
        f:write(str)
        f:seek('set', 0)
        local contents = f:read('a')
        assert(contents == str)
    end,
    [2] = function()
        local folders = { 'User' }
        local main = create_folder('./LewdDeveloper')
        if main then
            for _, folder in ipairs(folders) do
                local path = './LewdDeveloper/' .. folder
                assert(create_folder(path), 'Failed to find/create folder: ' .. path)
            end
        end
        io.open('./LewdDeveloper/User/settings.json', 'a'):close()
        local f = io.open('./LewdDeveloper/User/settings.json', 'r+')
        local str = f:read('a') or ''
        local dat = json.decode(str, 0)
        if type(dat) ~= 'table' then
            f:seek('set')
            f:write('{}')
            if #str > 0 then
                f:write(',\n' .. str)
            end
        else
            datafile.storage.user = dat
        end
        f:close()
    end
 }

(function()
    local failed
    for id, test in ipairs(datafile.tests) do
        local succ, errcode = pcall(test)
        if not succ then
            failed = true
            print(string.format('Test %d failed: %s', id, errcode))
        end
    end
    if failed then
        error(' [test failed] one or more test has failed, stop execution', 2)
    end
end)()
---@endregion tests

if not ... then
    package.preload['datafile'] = function()
        return datafile
    end
else
    return datafile
end

