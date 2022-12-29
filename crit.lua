--- List of weapons that cannot crit in official TF2 Server
--
--- ``CalcIsAttackCriticalHelpers()`` overridden to disable crit, or only grant crit on certain condition
--
--- https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes
--- https://api.steampowered.com/IEconItems_440/GetSchemaItems/v0001/?key=YOUR_API_KEY Client Item Schema (item_games.txt)
local sets = {
    [441] = true,
    [416] = true,
    [40] = true,
    [594] = true,
    [595] = true,
    [813] = true,
    [834] = true,
    [141] = true,
    [1004] = true,
    [142] = true,
    [232] = true,
    [61] = true,
    [1006] = true,
    [525] = true,
    [132] = true,
    [1082] = true,
    [266] = true,
    [482] = true,
    [327] = true,
    [307] = true,
    [357] = true,
    [404] = true,
    [812] = true,
    [833] = true,
    [237] = true,
    [265] = true,
    [155] = true,
    [460] = true,
    [1178] = true,
    [14] = true,
    [201] = true,
    [56] = true,
    [230] = true,
    [402] = true,
    [526] = true,
    [664] = true,
    [752] = true,
    [792] = true,
    [801] = true,
    [851] = true,
    [881] = true,
    [890] = true,
    [899] = true,
    [908] = true,
    [957] = true,
    [966] = true,
    [1005] = true,
    [1092] = true,
    [1098] = true,
    [15000] = true,
    [15007] = true,
    [15019] = true,
    [15023] = true,
    [15033] = true,
    [15059] = true,
    [15070] = true,
    [15071] = true,
    [15072] = true,
    [15111] = true,
    [15112] = true,
    [15135] = true,
    [15136] = true,
    [15154] = true,
    [30665] = true,
    [194] = true,
    [225] = true,
    [356] = true,
    [461] = true,
    [574] = true,
    [638] = true,
    [649] = true,
    [665] = true,
    [727] = true,
    [794] = true,
    [803] = true,
    [883] = true,
    [892] = true,
    [901] = true,
    [910] = true,
    [959] = true,
    [968] = true,
    [15062] = true,
    [15094] = true,
    [15095] = true,
    [15096] = true,
    [15118] = true,
    [15119] = true,
    [15143] = true,
    [15144] = true,
    [131] = true,
    [406] = true,
    [1099] = true,
    [1144] = true,
    [46] = true,
    [42] = true,
    [311] = true,
    [863] = true,
    [1002] = true,
    [159] = true,
    [433] = true,
    [1190] = true,
    [129] = true,
    [226] = true,
    [354] = true,
    [1001] = true,
    [1101] = true,
    [1179] = true,
    [642] = true,
    [133] = true,
    [444] = true,
    [405] = true,
    [608] = true,
    [57] = true,
    [231] = true,
    [29] = true,
    [211] = true,
    [35] = true,
    [411] = true,
    [663] = true,
    [796] = true,
    [805] = true,
    [885] = true,
    [894] = true,
    [903] = true,
    [912] = true,
    [961] = true,
    [970] = true,
    [998] = true,
    [15008] = true,
    [15010] = true,
    [15025] = true,
    [15039] = true,
    [15050] = true,
    [15078] = true,
    [15097] = true,
    [15121] = true,
    [15122] = true,
    [15123] = true,
    [15145] = true,
    [15146] = true,
    [30] = true,
    [212] = true,
    [59] = true,
    [60] = true,
    [297] = true,
    [947] = true,
    [735] = true,
    [736] = true,
    [810] = true,
    [831] = true,
    [933] = true,
    [1080] = true,
    [1102] = true,
    [140] = true,
    [1086] = true,
    [30668] = true,
    [25] = true,
    [737] = true,
    [26] = true,
    [28] = true,
    [222] = false,
    [1121] = false,
    [1180] = false,
    [58] = false,
    [1083] = false,
    [1105] = false
}

local function ServerAllowRandomCrit(tf_weapon_criticals, tf_weapon_criticals_melee, is_melee)
    return is_melee and tf_weapon_criticals == 1 or tf_weapon_criticals_melee == 2 or
        (tf_weapon_criticals == 1 and tf_weapon_criticals_melee == 1)
end

local function WeaponAllowRandomCrit(base_damage, item_definition_id, player_class, is_melee)
    if player_class == 8 and is_melee == true then --- TF2_SPY = 8
        return false
    end
    return base_damage > 0 and sets[item_definition_id] ~= true
end

--- Purpose: share data from different callbacks
local store = {
    crit_calculator_command_number = -1,
    required_damage = 0
}

callbacks.Register("CreateMove", function(cmd) ---@param cmd UserCmd
    local me     = entities.GetLocalPlayer()
    local weapon = me:GetPropEntity("m_hActiveWeapon") ---@type Entity

    if not weapon:IsValid() then
        return
    end

    local command_number = cmd.command_number
    store.command_number = command_number

    local player_class
    local item_definition_id, is_melee, added_per_shot, bucket_current, crit_fired, seed_count, weapon_seed
    local tf_weapon_criticals, tf_weapon_criticals_melee, bucket_max

    player_class              = me:GetPropInt("m_iClass")
    is_melee                  = weapon:IsMeleeWeapon()
    added_per_shot            = weapon:GetWeaponBaseDamage()
    item_definition_id        = weapon:GetPropInt("m_iItemDefinitionIndex")
    tf_weapon_criticals       = client.GetConVar("tf_weapon_criticals")
    tf_weapon_criticals_melee = client.GetConVar("tf_weapon_criticals_melee")
    bucket_max                = client.GetConVar('tf_weapon_criticals_bucket_cap')

    if ServerAllowRandomCrit(tf_weapon_criticals, tf_weapon_criticals_melee, is_melee) == false or
        WeaponAllowRandomCrit(added_per_shot, item_definition_id, player_class, is_melee) == false then
        return
    end

    store.crit_calculator_command_number = command_number
    weapon_seed                          = weapon:GetCurrentCritSeed()

    --- do damage penalty calculation
    do
        if is_melee then
            goto _continue_1
        end

        local crit_chance, round_damage, damage_total, damage_crit
        local cmpCritChance, requiredTotalDamage
        local required_damage = 0

        crit_chance  = weapon:GetCritChance()
        round_damage = weapon:GetWeaponDamageStats()
        damage_total = round_damage["total"]
        damage_crit  = round_damage["critical"]

        -- (the + 0.1 is always added to the comparsion)
        cmpCritChance = crit_chance + 0.1

        if weapon:CalcObservedCritChance() > cmpCritChance then
            requiredTotalDamage = (damage_crit * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
            required_damage     = requiredTotalDamage - damage_total
        end
        store.required_damage = required_damage
        ::_continue_1::
    end

    store.rapidfire_duration = weapon:GetRapidFireCritTime() - globals.CurTime()
    bucket_current       = weapon:GetCritTokenBucket()

    --- do crit bucket calculation
    if weapon_seed == store.weapon_seed and bucket_current == store.bucket_current  then
        return
    end
    store.weapon_seed = weapon_seed

    crit_fired           = weapon:GetCritSeedRequestCount()
    seed_count           = weapon:GetCritCheckCount()
    store.bucket_current = bucket_current
    store.crit_fired     = crit_fired
    store.seed_count     = seed_count

    do
        local bucket, seed, crit, cost
        local current_shot_cost    = weapon:GetCritCost(bucket_current, crit_fired, seed_count)
        store.current_shot_cost    = current_shot_cost
        local shots_to_fill_bucket = math.ceil(bucket_max / added_per_shot)

        local shots_left_till_bucket_max, critical_attacks, critical_attacks_max = 0, 0, 0

        --- Attacks needed till bucket token max
        bucket = bucket_current

        while bucket < bucket_max do
            bucket                     = bucket + added_per_shot
            shots_left_till_bucket_max = shots_left_till_bucket_max + 1
        end
        store.shots_to_fill_bucket = shots_left_till_bucket_max

        --- Amount of critical attacks stored
        bucket = bucket_current

        while bucket >= math.floor(current_shot_cost) do
            critical_attacks = critical_attacks + 1
            bucket           = bucket - weapon:GetCritCost(bucket, crit_fired + critical_attacks, seed_count)
        end
        store.critical_attacks = critical_attacks

        --- Total of critical attacks can be filled
        --- TODO: This calculation may be flawed
        bucket = bucket_max
        seed   = seed_count + shots_left_till_bucket_max
        crit   = crit_fired - shots_to_fill_bucket

        repeat
            critical_attacks_max = critical_attacks_max + 1
            cost                 = weapon:GetCritCost(bucket, crit, seed)
            bucket               = bucket - cost
        until bucket < cost
        store.critical_attacks_max = critical_attacks_max
    end
end)

--- draw
local font = draw.CreateFont("Tahoma", -11, 400, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)

local function render_text(x, y, text, ...)
    draw.Color(...)
    draw.Text(x, y, text)
    local wide, tall = draw.GetTextSize(text)
    return y + tall
end

local function render_filled_rect(x, y, x1, y1, ...)
    draw.Color(...)
    draw.FilledRect(x, y, x1, y1)
end

local function render_outlined_rect(x, y, x1, y1, ...)
    draw.Color(...)
    draw.OutlinedRect(x, y, x1, y1)
end

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

callbacks.Register("Draw", function()
    draw.SetFont(font)
    draw.Color(255, 255, 255, 255)
    local x       = 200
    local y       = 550
    local margin  = 10
    local padding = 4

    local user_want_force_crit = input.IsButtonDown(gui.GetValue('crit key'))

    if clientstate.GetClientSignonState() ~= 6 then
        return
    end

    -- if engine.Con_IsVisible() or engine.IsGameUIVisible() then
    --     return
    -- end

    if store.command_number ~= store.crit_calculator_command_number then
        return
    end

    local text

    if store.required_damage > 0 then
        text = ("Penalty\t\t\t  " .. round(store.required_damage, 1) .. ' damage')
        y    = render_text(x, y, text, 255, 255, 255, 255) + padding
    end

    text = ("Bucket\t\t\t   " .. round(store.bucket_current, 1))
    y = render_text(x, y, text, 255, 255, 255, 255)

    text = ("Crit Stored\t\t" .. store.critical_attacks .. ' out of ' .. store.critical_attacks_max)
    y    = render_text(x, y, text, 255, 255, 255, 255) + padding + margin

    local width    = 200
    local height   = 8
    local duration = store.rapidfire_duration

    render_filled_rect(x, y, x + width, y + height + 2, 28, 28, 28, 255)
    render_outlined_rect(x - 2, y - 2, x + width + 2, y + height + 2, 255, 255, 255, 255)

    draw.Color(30, 255, 0, 255)
    if user_want_force_crit then
        draw.Color(115, 0, 255, 255)
    end

    if (duration > 0) then
        draw.FilledRect(x, y, x + math.floor(width * (duration / 2)), y + height)
    else
        draw.FilledRect(x, y, x + math.floor(width * (store.critical_attacks / store.critical_attacks_max)), y + height)
    end

    render_filled_rect(x, y, x + math.floor(width * ((store.critical_attacks - 1) / store.critical_attacks_max)),
        y + height, 30, 255, 0, 255)

    if store.bucket_current < math.floor(store.current_shot_cost) then
        text = ("– " .. round(store.current_shot_cost, 1))
        y = render_text(x, y + 20, text, 255, 0, 0, 255)
    end
end)
