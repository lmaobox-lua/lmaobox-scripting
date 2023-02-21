-- TODO: No VDF parser yet
--     : Remove clock bandaid fix, send 2 MVMUpgrade and recieve 2 UserMessage and Move on
--     : Keep m_nCanPurchaseUpgradesCount to 0 (or worst case make it go negative)

-- Note: Can only be used before the first wave ends
--     : Can only be used in the upgrade zone
--     : Can only be used if starting money is more than 600

-- 1. Open Upgrades Panel
-- 2. Upgrade twice, and walk away
-- 3. Open Upgrades Panel
-- 4. Remove one upgrade, then refund
-- 5. Open Upgrades Panel
-- 6. Upgrade twice, then remove two upgrades
-- 7. Repeat step 2 to 6

local observed_upgrades_count = 0

---@region keyvalues

-- m_nCanPurchaseUpgradesCount is reset when reconnecting to the server

-- Always make sure m_nCanPurchaseUpgradesCount is 0 otherwise you can't change class
local function begin_upgrade()
    assert(engine.SendKeyValues('"MvM_UpgradesBegin" {}'))
    observed_upgrades_count = observed_upgrades_count + 1
end

-- You should only use when m_nCanPurchaseUpgradesCount is bigger than 0, else server will recieve an assertion message
---@param num_upgrades number # If `num_upgrades` are bigger than 0 there's a chance the player can speak this voice line `MP_CONCEPT_MVM_UPGRADE_COMPLETE`
local function end_upgrade(num_upgrades)
    num_upgrades = num_upgrades or 0
    assert(engine.SendKeyValues(
        '"MvM_UpgradesDone" { \"num_upgrades\" \"' .. num_upgrades .. '\" }'))
    observed_upgrades_count = observed_upgrades_count - 1
end

local function respec_upgrades()
    assert(engine.SendKeyValues('"MVM_Respec" {}'))
end

local function mvm_upgrade_weapon(itemslot, upgrade, count)
    assert(engine.SendKeyValues(
        '"MVM_Upgrade" { \"Upgrade\" { \"itemslot\" \"' ..
        itemslot .. '\" \"Upgrade\" \"' .. upgrade .. '\" \"count\" \"' .. count .. '\" } }'))
end

---@endregion keyvalues

---@region core

local confirmed_upgrades_request, sent_upgrades_request, step, clock, grace

local function reset()
    confirmed_upgrades_request = 0
    sent_upgrades_request      = 0
    step                       = 1
    clock                      = 0
    grace                      = true
end

local function vaccinator_ghost_upgrade(count)
    mvm_upgrade_weapon(1, 19, count)
    sent_upgrades_request = sent_upgrades_request + 1
end

local phase = {
    function()
        begin_upgrade()
        vaccinator_ghost_upgrade(1)
        vaccinator_ghost_upgrade(1)
        end_upgrade(2)
    end,
    function()
        begin_upgrade()
        vaccinator_ghost_upgrade( -1)
        vaccinator_ghost_upgrade(1)
        respec_upgrades() --> infinite money glitch
        end_upgrade( -1)
    end,
    function()
        begin_upgrade()
        vaccinator_ghost_upgrade(1)
        vaccinator_ghost_upgrade(1)
        vaccinator_ghost_upgrade( -1)
        vaccinator_ghost_upgrade( -1)
        end_upgrade(0)
    end
}

local function check_prerequisites()
    local me = entities.GetLocalPlayer()
    if not me then
        return
    end
    local server_allowed_respec, my_credits, in_upgrade_zone
    server_allowed_respec = client.GetConVar('tf_mvm_respec_enabled') == 1
    my_credits            = me:GetPropInt('m_nCurrency')
    in_upgrade_zone       = me:GetPropInt('m_bInUpgradeZone') == 1
    if server_allowed_respec and in_upgrade_zone then
        return true
    end
end

--- Feel free imporoving this, buybot lua scripter
local function exec_exploit()
    if clock > globals.CurTime() then
        goto continue
    end

    if confirmed_upgrades_request < sent_upgrades_request then
        if grace then
            grace = false
            goto refresh_clock
        end
        confirmed_upgrades_request = 0
        sent_upgrades_request      = 0
        goto continue
    end

    if step == 4 then
        step = 1
        goto refresh_clock
    end

    phase[step]()
    step = step + 1
    grace = true

    ::refresh_clock::
    clock = globals.CurTime() + clientstate.GetLatencyOut()

    ::continue::
end

callbacks.Register("PostPropUpdate", function()
    if input.IsButtonDown(KEY_L) then
        if check_prerequisites() then
            exec_exploit()
        end
    end
end)

callbacks.Register("FireGameEvent", function(event) ---@param event GameEvent
    if event:GetName() == "game_newmap" then
        reset()
    end
end)
reset()

---@endregion core

local mann_vs_machine_event = {
    kMVMEvent_Player_Points               = 0,
    kMVMEvent_Player_Death                = 1,
    kMVMEvent_Player_PickedUpCredits      = 2,
    kMVMEvent_Player_BoughtInstantRespawn = 3,
    kMVMEvent_Player_BoughtBottle         = 4,
    kMVMEvent_Player_BoughtUpgrade        = 5,
    kMVMEvent_Player_ActiveUpgrades       = 6,
    kMVMEvent_Max                         = 255
}

callbacks.Register("ServerCmdKeyValues", function(vdf) ---@param vdf StringCmd
    local txt = vdf:Get()
    local key = txt:match('([^"]+)')
    if key == "MvM_UpgradesBegin" then
        observed_upgrades_count = observed_upgrades_count + 1
    elseif key == "MvM_UpgradesDone" then
        observed_upgrades_count = observed_upgrades_count - 1
    end
end)

local function attempt_balance_upgrades_count()
    while observed_upgrades_count > 0 do
        end_upgrade(0)
        return
    end
    while observed_upgrades_count < 0 do
        begin_upgrade()
        return
    end
    return true
end

-- Ghetto fix
local function TextMsg(hud_type, text)
    if text == '#TF_MVM_NoClassUpgradeUI' then
        client.ChatPrintf("[Buy Bot] It seems like you can't change class, try again")
        if attempt_balance_upgrades_count() then
            observed_upgrades_count = observed_upgrades_count + 1
            attempt_balance_upgrades_count()
        end
    end
end


local function MVMPlayerUpgradedEvent(player_index, current_wave, itemdefinition, attributedefinition, quality,
                                      credit_cost)
end

local function MVMLocalPlayerUpgradesValue(mercenary, itemdefinition, upgrade, credit_cost)
    confirmed_upgrades_request = confirmed_upgrades_request + 1
end

local function MVMLocalPlayerWaveSpendingValue(steamID64, current_wave, mvm_event_type, credit_cost)

end

local user_message_triggers = {
    [5] = function(UserMessage)
        local hud_type, text
        hud_type = UserMessage:ReadByte()
        text = UserMessage:ReadString(256)
        TextMsg(hud_type, text)
    end,
    [60] = function(UserMessage)
        local player_index, current_wave, itemdefinition, attributedefinition, quality, credit_cost
        player_index = UserMessage:ReadByte()
        current_wave = UserMessage:ReadByte()
        itemdefinition = UserMessage:ReadInt(16)
        attributedefinition = UserMessage:ReadInt(16)
        quality = UserMessage:ReadByte()
        credit_cost = UserMessage:ReadInt(16)
        MVMPlayerUpgradedEvent(player_index, current_wave, itemdefinition, attributedefinition, quality, credit_cost)
    end,
    [MVMLocalPlayerUpgradesClear] = function(UserMessage)
    end,
    [64] = function(UserMessage)
        local mercenary, itemdefinition, upgrade, credit_cost
        mercenary = UserMessage:ReadByte()
        itemdefinition = UserMessage:ReadInt(16)
        upgrade = UserMessage:ReadByte()
        credit_cost = UserMessage:ReadInt(16)
        MVMLocalPlayerUpgradesValue(mercenary, itemdefinition, upgrade, credit_cost)
    end,
    [66] = function(UserMessage)
        local steamID64, current_wave, mvm_event_type, credit_cost
        steamID64 = UserMessage:ReadInt(64)
        current_wave = UserMessage:ReadByte()
        mvm_event_type = UserMessage:ReadByte()
        credit_cost = UserMessage:ReadInt(16)
        MVMLocalPlayerWaveSpendingValue(steamID64, current_wave, mvm_event_type, credit_cost)
    end,
    [PlayerLoadoutUpdated] = function(UserMessage)
    end,
}

callbacks.Register("DispatchUserMessage", function(UserMessage) ---@param UserMessage UserMessage
    local id = UserMessage:GetID()
    if user_message_triggers[id] then
        user_message_triggers[id](UserMessage)
    end
end)

--- Debug:
-- local rows, y = { 600, 800 }, 600

-- local function table_text(first, second)
--     if first then
--         draw.Color(255, 255, 255, 255)
--         draw.Text(rows[1], y, first)
--     end
--     if second then
--         draw.Color(255, 255, 0, 255)
--         draw.Text(rows[2], y, second)
--     end
--     y = y + 24
-- end

-- callbacks.Register("Draw", function()
--     draw.SetFont(21)
--     y = 600
-- end)
