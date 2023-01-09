--[[
    Infinite Food automation
    Credit: LNX00
    Author: forum/team-fortress-2-a/564934-infinite-eating-automation
    Dependencies: None
]]

local key = KEY_J
local timer, delay = 0, 0.5

callbacks.Unregister("CreateMove", "infinite-food")
callbacks.Register("CreateMove", "infinite-food", function(usercmd) ---@param usercmd UserCmd
    local me = entities.GetLocalPlayer()
    if not me:IsAlive() then return end
    if not input.IsButtonDown(key) then return end

    local weapon = me:GetPropEntity('m_hActiveWeapon') ---@type Entity
    if weapon:GetClass() ~= "CTFLunchBox" then return end

    usercmd:SetButtons(usercmd:GetButtons() | IN_ATTACK)

    if globals.CurTime() > timer then
        timer = globals.CurTime() + delay
        client.Command("taunt", true)
    end
end)
