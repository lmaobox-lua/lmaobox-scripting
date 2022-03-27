-- You're free to do whatever you want with this script, by any means
local package = {
    name = "customHud",
    version = "1.0.0",
    author = "Moonverse#9320",
    url = "https://github.com/LewdDeveloper/lmaobox-scripting",
    dependencies = "lua >= 5.4"
}

-- Wrapper for creating a font instance
-- invoke this function outside callback
-- use SetFont to render text (note : invoke in Draw callback if your script uses 2 fonts or more)
-- @param path : in Team Fortress 2 folder or specify absolute path
-- @param name : font name
-- @param height : font height
-- @param weight : font weight (see : )
local addfont = function(path, name, height, weight)
    local exist = draw.AddFontResource(path) -- AddFontResource prints error message when font does not exist
    if (exist) then
        return draw.CreateFont(name, height, weight)
    end -- CreateFont returns fontid (integer)
end

local Font0 = addfont("C:\\Windows\\Fonts\\Verdana.ttf", "Verdana", 14, 800)
local Font1 = addfont("C:\\Windows\\Fonts\\Tahoma.ttf", "Tahoma", 14, 500)
print(Font0, Font1)

-- The callback register implementation is different from what i've seen in csgo cheats
callbacks.Unregister('Draw', 'on_paint', on_paint)

local GetCommonPlayerProp = function(entityindex)
    if not (entityindex:IsPlayer()) then
        error("entity is not a player")
    end
    local player = {}
    player.iTeam = entityindex:GetTeamNumber()
    player.iClass = entityindex:GetClass()
    player.iHealth = entityindex:GetHealth()
    player.iMaxHealth = entityindex:GetMaxHealth()
    player.iMaxBuffedHealth = entityindex:iMaxBuffedHealth()
    player.iAmmo = 0
    player.bCritBoosted = entityindex:IsCritBoosted()
    player.m_vecOrigin = entityindex:GetAbsOrigin()

    return player
end

local error_hander = function(...)
    local bSucess, output = pcall(...)
    print("[Status] " .. tostring(bSucess) .. ", [Output] " .. tostring(output))
end

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

local surface3d_vec_coordinate = function()
    local localplayer = entities.GetLocalPlayer()
    if not (localplayer) then
        return -- not ingame
    end

    local temp = {}
    local playerTbl, player = GetPlayers()
    local m_vecOrigin
    local w2s_vecOrigin
    for i = 1, #playerTbl do
        repeat
            player = playerTbl[i]
            m_vecOrigin = player:GetAbsOrigin()
            w2s_vecOrigin = client.WorldToScreen(m_vecOrigin)
            if not (w2s_vecOrigin) then
                break
            end
            if not (player:GetHealth() > 1) then
                break
            end
            draw.Color(0, 255, 0, 255)
            draw.TextShadow(w2s_vecOrigin[1], w2s_vecOrigin[2],
                tostring(math.abs(math.floor(player:GetPropFloat('m_vecVelocity[0]'))))) -- use string.format if you like
            draw.TextShadow(w2s_vecOrigin[1], w2s_vecOrigin[2] + 20, tostring(m_vecOrigin))
        until true
    end

end

local surface2d_hud = function()
    local localplayer = entities.GetLocalPlayer()
    if not (localplayer:GetHealth() > 0 + 1) then
        return -- user hasn't spawned yet
    end

    local w, h = draw.GetScreenSize()
    local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
    local wpnId = weapon:GetPropInt("m_iItemDefinitionIndex")
    if wpnId ~= nil then
        local wpnName = itemschema.GetItemDefinitionByID(wpnId):GetName()
        draw.Color(0, 255, 0, 255)
        draw.TextShadow(h / 2, w / 2, wpnName) -- only take integer
    end
    local healthpoint = localplayer:GetHealth()
    local maxhealth = localplayer:GetMaxHealth()
    if localplayer:IsAlive() or healthpoint ~= nil then
        draw.Color(255, 0, 0, 255)
        draw.TextShadow(h / 2 - 100, w / 2, tostring(healthpoint) .. " / " .. tostring(maxhealth))
    end
end

local on_paint = function()
    draw.SetFont(Font0)
    -- surface3d_vec_coordinate()
    draw.SetFont(Font1)
    surface2d_hud()
    -- draw bottom right panel 
    -- draw essential player info panel
    -- draw score, timer, objective,..

    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        return
    end
    
end

callbacks.Register('Draw', 'on_paint', on_paint)


-- printLuaTable ( party.GetMembers() )
