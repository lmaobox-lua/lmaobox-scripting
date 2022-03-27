-- You're free to do whatever you want with this script, by any means
local package = {
    name = "snippet",
    version = "1.0.0",
    author = "Moonverse#9320",
    url = "https://github.com/LewdDeveloper/lmaobox-scripting",
    dependencies = "lua >= 5.4"
}

-- Returns the entityindex of every player excludes local player
local GetPlayers = function()
    local entity_tbl = entities.FindByClass("CTFPlayer")
    local localplayer = entities.GetLocalPlayer()
    for i = 1, #entity_tbl do
        repeat
            if entity_tbl[i] == localplayer then
                table.remove(entity_tbl, i)
                break
            end
        until true
    end
    return entity_tbl
end

