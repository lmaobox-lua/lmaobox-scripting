local dkjson = require "dkjson"

local raw        = assert(io.open('items_game.json', 'r')):read('a')
local serialized = dkjson.decode(raw)

local exports = {}

---@diagnostic disable-next-line: need-check-nil
for i, t in ipairs(serialized.result.items) do
    local item_name = t.item_name
    if t.proper_name == true then
        exports[t.defindex] = t.name
    else
        exports[t.defindex] = assert(client.Localize(item_name))
    end
end

local inspect = require "inspect"
local handle<close> = io.open('weaponname.lua', 'w')
handle:write(inspect(exports))
