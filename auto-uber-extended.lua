-- TODO: Add extra 500ms to last m_hLastHealingTarget if beam just disconnected
-- https://github.dev/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/game/shared/tf/tf_weapon_medigun.cpp#L1358
-- IN_SCORE     = (1 << 16); // Used by client.dll for when scoreboard is held down

local json         = require "dkjson"
local menulib      = require "Menu"
local items_name   = require "items_name"
local buttons_name = require "buttoncode_translation"
local now          = globals.CurTime
local font         = draw.CreateFont('Verdana', 16, 800, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)

-- set_weapon_mode
local MedigunType  = {
    "Medi Gun",
    "",
    "Quickfix",
    "Vaccinator"
}

-- set_charge_type
local ChargeType   = {
    "Uber",
    "Crit",
    "Mega Heal",
    "Resist"
}

-- m_nChargeResistType
local ResistType   = {
    "Bullet",
    "Fire",
    "Blast"
}

local function render_text(x, y, text, ...)
    draw.Color(...)
    draw.Text(x, y, text)
    local wide, tall = draw.GetTextSize(text)
    return y + tall
end

local function sort_by_alphabet(object)
    local keys = {}
    for key in pairs(object) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function create_menu(title, flags)
    local menu = menulib.Create(title, flags)
    callbacks.Register("Unload", function() menulib.RemoveMenu(menu) end)
    return menu
end

---@region menu and config
local builder = create_menu("Medic Enjoyer", MenuFlags.AutoSize)
builder:AddComponent(menulib.Label("Version: Stable 1.0.0"))
builder:AddComponent(menulib.Label("Active Uber Delay (Millseconds)"))
builder:AddComponent(menulib.Label("Min > Max : No random"))

local store             = {
    config_file_load_time  = 0,
    config_file_contents   = nil,
    trigger_uber_at        = nil,
    medigun_healing        = false,
    charge_level           = 0,
    target                 = 0,
    vaccinator_resist_mode = 0,
    menu                   = {
        millisecond_before_activate_ubercharge_m     = builder:AddComponent(menulib.Slider("Min", 0, 2000)),
        millisecond_before_activate_ubercharge_n     = builder:AddComponent(menulib.Slider("Max", 0, 2000)),
        allow_only_whitelisted_can_active_ubercharge = builder:AddComponent(menulib.Checkbox("Whitelist only", false)),
        notification_trigger_uber_activated          = builder:AddComponent(menulib.Checkbox("Notification when trigger uber activated", false)),
        background_opacity                           = builder:AddComponent(menulib.Slider("Background Opacity", 0, 255, 100)),
        draw_disable_key                             = builder:AddComponent(menulib.Keybind("Hide Key")),
    },
}

local config            = {
    version                                      = 0.1,
    position_x                                   = 100,
    position_y                                   = 100,
    background_opacity                           = 100,
    draw_disable_key                             = KEY_TAB,
    millisecond_before_activate_ubercharge_m     = 90,
    millisecond_before_activate_ubercharge_n     = 210,
    allow_only_whitelisted_can_active_ubercharge = true,
    notification_trigger_uber_activated          = false,
    whitelisted_steamid64                        = {
        BillionthSteamAccount = 76561198960265728,
    },
}
store.config_file_order = sort_by_alphabet(config)

local filename          = "auto-uber-extended.json"

---@param config table
---@param fullpath string
local function load_config(config, fullpath)
    local file = io.open(fullpath, "r")
    if file == nil then return false end
    local contents = file:read("a")
    file:close()
    local object = json.decode(contents)
    if type(object) ~= "table" then return false end

    local lhs, rhs, bad
    for key, value in pairs(object) do
        lhs, rhs = type(config[key]), type(value)
        if lhs ~= rhs then
            goto mismatch
        end
        config[key] = value
        goto continue
        ::mismatch::
        print("Type mismatch: " .. key .. " " .. lhs .. " ~= " .. rhs)
        bad = true
        ::continue::
    end

    if bad then
        return false
    end
    return true
end

---@param config table
---@param fullpath string
local function save_config(config, fullpath)
    local file = assert(io.open(fullpath, "w"))
    local result = assert(json.encode(config, {
            indent = true,
            keyorder = store.config_file_order
        }))
    file:write(result)
    file:close()
end

callbacks.Register("Draw", "ConfigWatch", function()
    local last_modified = filesystem.GetFileTime(filename)
    local update_menu   = false
    if last_modified ~= store.config_file_load_time then
        if not load_config(config, filename) then
            save_config(config, filename)
        end
        update_menu = true
        store.config_file_load_time = last_modified
    end

    if update_menu then
        for key, value in pairs(store.menu) do
            if key == "draw_disable_key" then
                store.menu[key].Key = config[key]
                store.menu[key].KeyName = buttons_name[config[key]]
            else
                store.menu[key].Value = config[key]
            end
        end
        builder.X = config.position_x
        builder.Y = config.position_y
    else
        local need_replace = false

        for key, value in pairs(store.menu) do
            if key == "draw_disable_key" then
                if value.Key ~= config[key] then
                    config[key] = value.Key
                    need_replace = true
                end
            else
                if value.Value ~= config[key] then
                    config[key] = value.Value
                    need_replace = true
                end
            end
        end

        if config.position_x ~= builder.X then
            config.position_x = builder.X
            need_replace = true
        end

        if config.position_y ~= builder.Y then
            config.position_y = builder.Y
            need_replace = true
        end

        if need_replace then
            save_config(config, filename)
        end
    end
end)
---@endregion menu and config

---@region 'active uber trigger'

callbacks.Register("CreateMove", function(usercmd) ---@param usercmd UserCmd
    local me     = entities.GetLocalPlayer()
    local weapon = me:GetPropEntity('m_hActiveWeapon') ---@type Entity

    if not weapon:IsMedigun() then
        return
    end

    local player_being_healed, medigun_healing, charge_level, vaccinator_resist_mode
    player_being_healed = weapon:GetPropEntity('m_hHealingTarget')

    if not player_being_healed:IsValid() then
        return
    end

    if store.trigger_uber_at and store.trigger_uber_at <= now() then
        usercmd.buttons = usercmd.buttons | IN_ATTACK2
        store.trigger_uber_at = nil
    end

    medigun_healing              = weapon:GetPropBool('m_bHealing')
    vaccinator_resist_mode       = weapon:GetPropInt('m_nChargeResistType')
    charge_level                 = weapon:GetPropFloat('NonLocalTFWeaponMedigunData', 'm_flChargeLevel')

    store.target                 = player_being_healed:GetIndex()
    store.medigun_healing        = medigun_healing
    store.vaccinator_resist_mode = vaccinator_resist_mode
    store.charge_level           = charge_level
end)

callbacks.Register("DispatchUserMessage", function(um) ---@param um UserMessage
    local id = um:GetID()
    if id == VoiceSubtitle then
        local player_index, menu_slot, command_item
        player_index = um:ReadByte()
        menu_slot = um:ReadByte()
        command_item = um:ReadByte()

        if menu_slot ~= 1 or command_item ~= 6 then
            return
        end

        if player_index ~= store.target and player_index ~= client.GetLocalPlayerIndex() then
            return
        end

        if not entities:GetLocalPlayer():GetPropEntity('m_hActiveWeapon'):IsMedigun() then
            return
        end

        local condition = not config.allow_only_whitelisted_can_active_ubercharge

        local player_info = client.GetPlayerInfo(player_index)
        local steamid64 = steam.ToSteamID64(player_info.SteamID)

        if not condition then
            for index, value in pairs(config.whitelisted_steamid64) do
                if value == steamid64 then
                    condition = true
                    break
                end
            end
        end

        if condition then
            local time = (
                engine.RandomInt(
                    config.millisecond_before_activate_ubercharge_m,
                    config.millisecond_before_activate_ubercharge_n
                ) * 0.001)
            if config.notification_trigger_uber_activated then
                client.ChatPrintf("ACTIVATE UBER IN " .. time .. " SECONDS")
            end
            store.trigger_uber_at = now() + time
        end
    end
end)

---@endregion 'active uber trigger'

---@region 'medic playerlist'

local medics = {
    n = 0, -- number of medic players on the enemy team
    ubercharge = {},
    weaponname = {},
    playername = {},
    chargeduration = {},
    dormant = {}
}

callbacks.Register("FireGameEvent", function(event) ---@param event GameEvent
    local eventname = event:GetName()
    if eventname == "player_chargedeployed" then
        local player = entities.GetByUserID(event:GetInt("userid"))
        if player then medics.chargeduration[player:GetIndex()] = now() + 3.000 end
        return
    end
end)

callbacks.Register("PostPropUpdate", function()
    local count              = 0
    local my_playerindex     = client.GetLocalPlayerIndex()
    local is_tournament_mode = client.GetConVar('mp_tournament') == 1 -- IsInTournamentMode()
    local mediguns           = entities.FindByClass('CWeaponMedigun')
    local player_resource    = entities.GetPlayerResources()
    local ubercharge         = player_resource:GetPropDataTableInt('m_iChargeLevel')
    local mercenary          = player_resource:GetPropDataTableInt('m_iPlayerClass')
    local team               = player_resource:GetPropDataTableInt('m_iTeam')
    local my_team            = team[my_playerindex + 1]
    local weaponname         = {}
    local dormantstate       = {}

    for entityindex, weapon in pairs(mediguns) do
        local player = weapon:GetPropEntity('m_hOwnerEntity')
        if player:IsPlayer() then
            local idx         = player:GetIndex() + 1
            local defindex    = weapon:GetPropInt("m_iItemDefinitionIndex")
            weaponname[idx]   = items_name[defindex]
            dormantstate[idx] = true or player:IsDormant()
            if not is_tournament_mode then
                ubercharge[idx] = math.floor(weapon:GetPropFloat('NonLocalTFWeaponMedigunData', 'm_flChargeLevel') *
                    100)
            end
        end
    end

    for idx = 2, #mercenary do
        local class, uber, name, playerindex
        playerindex = idx - 1
        class       = mercenary[idx]
        uber        = ubercharge[idx]
        name        = client.GetPlayerNameByIndex(playerindex)
        if string.len(name) == 0 then
            goto continue
        end
        if team[idx] == my_team then
            goto continue
        end
        if class ~= TF2_Medic then
            goto continue
        end
        count                  = count + 1
        medics[count]          = idx
        medics.playername[idx] = name
        medics.weaponname[idx] = weaponname[idx] or '[?]'
        medics.ubercharge[idx] = uber
        medics.dormant[idx]    = dormantstate[idx]
        ::continue::
    end
    medics.n = count
end)

callbacks.Register("Draw", function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() or input.IsButtonDown(config.draw_disable_key) then
        return
    end

    draw.SetFont(font)
    draw.Color(255, 0, 0, 255)

    local padding = 4
    local x       = config.position_x
    local y       = config.position_y
    local text

    for i = 1, medics.n do
        local j = medics[i]
        local t = {
            medics.playername[j],
            medics.weaponname[j],
            medics.ubercharge[j] .. "%",
        }
        local wide
        text = table.concat(t, '\t\t')
        wide = draw.GetTextSize(text)
        draw.Color(0, 0, 0, config.background_opacity)
        draw.FilledRect(x - 4, y - 4, x + wide + 4, y + 20)
        if not (medics.dormant[j] and client.GetConVar('mp_tournament') == 0) then
            y = render_text(x, y, text, 204, 255, 153, 255) + padding
        else
            y = render_text(x, y, text, 200, 200, 200, 255) + padding
        end
        draw.Color(204, 255, 153, config.background_opacity)
        draw.FilledRect(x - 3, y + 1, x + wide + 3, y + 2)
        if medics.chargeduration[j] and medics.chargeduration[j] > now() then
            y = render_text(x + 5, y + 10, ':: ÜberCharged ::', 255, 255, 255, 255) + padding
        end
        y = y + 10
    end
end)

---@endregion 'medic playerlist'
