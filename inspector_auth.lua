callbacks.Register("ServerCmdKeyValues", function(kv) ---@param kv StringCmd
    print(kv:Get())
    kv:Set([[ "AchievementEarned" { "achievementID" "0xCA7" } ]])
end)

local CAT_IDENTIFY = 0xCA7
local CAT_REPLY    = 0xCA8

engine.SendKeyValues([[ "ClanTagChanged" { "tag" "hello" } ]])
engine.SendKeyValues([[ "FreezeCamTaunt" { "achiever" "162" "command" "freezecam_tauntsentry" "gibs" "1" } ]])
engine.SendKeyValues([[ "AchievementEarned" { "achievementID" "0xCA7" } ]])
engine.SendKeyValues(
[[ 
"cl_drawline" 
{ 
    "panel" "2" 
    "line"  "0"
    "x"     "0xCA7"
    "y"     "1234567.0"
} 
]])
