local inspect = require "inspect"
local json = require "dkjson"
local dir, file
dir = setmetatable({}, {
    _index = function()
        return true
    end
})
file = dir

local e_parse = {}
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

function e_parse.clamp(low, n, high)
    return math.min(math.max(n, low), high)
end

local e_datafile, e_varstorage, e_uiconfig

---@alias datafile
e_datafile = {}

e_datafile.session_storage = {}

function e_datafile.load(filename)
    local f, errlog = file.read(filename)
    if not f then
        print(errlog)
        return false
    end
    return json.decode(f)
end

function e_datafile.save(filename, value)
    local towrite, errlog = json.encode(value)
    if towrite then
        file.write(filename, json.encode(value))
    else
        print(errlog)
        return false
    end
end

function e_datafile.entry(key, limit)
    if limit then
        limit = e_parse.clamp(2, limit, 10) 
    end
    if not e_datafile.session_storage[key] then
        e_datafile.session_storage[key] = {
            limit = limit or 2
        }
    end
end

function e_datafile.backup(key, value)
    local size, count
    size = #e_datafile.session_storage[key]
    count = size + 1
    e_datafile.session_storage[key][count] = {}
    e_parse.shallow_copy(value, e_datafile.session_storage[key][count])
    if count > e_datafile.session_storage[key].limit then
        table.remove(e_datafile.session_storage[key], 1)
    end
    print("data saved at " .. os.clock())
end

function e_datafile.restore(key, index)
    if index then
        return e_datafile.session_storage[key][index]
    end
    return e_datafile.session_storage[key]
end

e_datafile.entry("senseless", 5)
e_datafile.backup("senseless", {1, 2, 3})
e_datafile.backup("senseless", {1, 2, 3, "tap"})
e_datafile.backup("senseless", {1, 2, 3, "gone"})
e_datafile.backup("senseless", {1, 2, 3, "rough"})
e_datafile.backup("senseless", {1, 2, 3, "rough less"})
e_datafile.backup("senseless", {1, 2, 3, "tap"})
print(inspect(e_datafile.restore("senseless")))
