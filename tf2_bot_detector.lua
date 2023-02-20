--[[ 
     https://github.com/PazerOP/tf2_bot_detector
--]]


local json, nanoids, file
local json    = require("dkjson")
local nanoids = require("nanoids").generate

local function game_newmap()
    local unique = nanoids()
    callbacks.Register("CreateMove", unique, function()
        callbacks.Unregister("CreateMove", unique)

    end)
end

xpcall(function()
    filesystem.CreateDirectory('tf2_bot_detector')
    filesystem.EnumerateDirectory("tf2_bot_detector/*", function(path)
        print(path)
    end)
end, function(error)
    print(error)
end)

-- json.decode()
