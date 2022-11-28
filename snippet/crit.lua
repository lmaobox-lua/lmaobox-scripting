local weapon_name_cache = {}
local function get_weapon_name(any)
    if type(any) == 'number' then
        return weapon_name_cache[any] or get_weapon_name(itemschema.GetItemDefinitionByID(any))
    end

    local meta = getmetatable(any)

    if meta['__name'] == 'Entity' then
        if any:IsWeapon() then
            return get_weapon_name(any:GetPropInt('m_iItemDefinitionIndex'))
        end
        return 'entity is not a weapon'
    end

    if meta['__name'] == 'ItemDefinition' then
        if weapon_name_cache[any] then
            return weapon_name_cache[any]
        end
        local special = tostring(any):match('TF_WEAPON_[%a%A]*')
        if special then
            local i1 = client.Localize(special)
            if i1:len() ~= 0 then
                weapon_name_cache[any:GetID()] = i1
                return i1
            end
            weapon_name_cache[any:GetID()] = client.Localize(any:GetTypeName():gsub('_Type', ''))
            return weapon_name_cache[any:GetID()]
        end
        for attrDef, value in pairs(any:GetAttributes()) do
            local name = attrDef:GetName()
            if name == 'paintkit_proto_def_index' or name == 'limited quantity item' then
                weapon_name_cache[any:GetID()] = client.Localize(any:GetTypeName():gsub('_Type', ''))
                return weapon_name_cache[any:GetID()]
            end
        end
        weapon_name_cache[any:GetID()] = tostring(any:GetNameTranslated())
        return weapon_name_cache[any:GetID()]
    end
end

local function is_rapid_fire_weapon(wpn)
    return wpn:GetWeaponData().useRapidFireCrits
end

local function get_crit_cap(wpn)
    local me_crit_multiplier = entities.GetLocalPlayer():GetCritMult()
    local chance = 0.02

    if wpn:IsMeleeWeapon() then
        chance = 0.15
    end
    local multiplier_crit_chance = wpn:AttributeHookFloat('mult_crit_chance', me_crit_multiplier * chance)

    if is_rapid_fire_weapon(wpn) then
        local total_crit_chance = math.max(math.min(0.02 * me_crit_multiplier, 0.01), 0.99)
        local crit_duration = 2.0
        local non_crit_duration = (crit_duration / total_crit_chance) - crit_duration
        local start_crit_chance = 1 / non_crit_duration
        multiplier_crit_chance = wpn:AttributeHookFloat('mult_crit_chance', start_crit_chance)
    end

    return multiplier_crit_chance
end

--- 

local indicator = draw.CreateFont('Verdana', 16, 700, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)
-- draw.CreateFont( 'Verdana', 24, 700, FONTFLAG_CUSTOM | FONTFLAG_ANTIALIAS )

local history = {}

local command_num_that_can_crit = false
local command_number

callbacks.Register('Draw', function()
    local width, height = draw.GetScreenSize()
    local width_center, height_center = width // 2, height // 2
    draw.SetFont(indicator)
    draw.Color(0, 0, 0, 255)
    local me = entities.GetLocalPlayer()

    if not me then
        return
    end

    local wpn = me:GetPropEntity('m_hActiveWeapon')

    if not wpn or not me:IsAlive() then
        return
    end

    local name = wpn:GetClass()

    local rapidfire_history, rapidfire_check_time = wpn:GetRapidFireCritTime(), wpn:GetLastRapidFireCritCheckTime()

    local bucket_current, bucket_cap, bucket_bottom, bucket_start = wpn:GetCritTokenBucket(),
                                                                    client.GetConVar('tf_weapon_criticals_bucket_cap'),
                                                                    client.GetConVar('tf_weapon_criticals_bucket_bottom'),
                                                                    client.GetConVar(
                                                                        'tf_weapon_criticals_bucket_default')

    local crit_check, crit_request = wpn:GetCritCheckCount(), wpn:GetCritSeedRequestCount()
    local observed_crit_chance = wpn:CalcObservedCritChance()
    local wpn_critchance = wpn:GetCritChance()
    local wpn_seed = wpn:GetCurrentCritSeed()
    local wpn_can_crit = wpn:CanRandomCrit()
    local damage_base = wpn:GetWeaponBaseDamage()
    local stats = wpn:GetWeaponDamageStats()
    local cost = wpn:GetCritCost(bucket_current, crit_request, crit_check)

    local server_allow_crit = false
    local can_criticals_melee = client.GetConVar('tf_weapon_criticals_melee')
    local can_weapon_criticals = client.GetConVar('tf_weapon_criticals')

    if wpn:IsMeleeWeapon() then
        if can_criticals_melee == 2 or (can_weapon_criticals == 1 and can_criticals_melee == 1) then
            server_allow_crit = true
        end
    elseif wpn:IsShootingWeapon() then
        if can_weapon_criticals == 1 then
            server_allow_crit = true
        end
    else
        server_allow_crit = wpn:CanRandomCrit()
    end

    local nProjectilesPerShot = wpn:GetWeaponData().bulletsPerShot
    if nProjectilesPerShot >= 1 then
        nProjectilesPerShot = wpn:AttributeHookFloat('mult_bullets_per_shot', nProjectilesPerShot)
    else
        nProjectilesPerShot = 1
    end

    local taken_per_crit = 0

    local added_per_shot = wpn:GetWeaponData().damage
    added_per_shot = wpn:AttributeHookFloat('mult_dmg', added_per_shot)
    added_per_shot = added_per_shot * nProjectilesPerShot
    local bucket_current_sim = bucket_current

    local shots_to_fill_bucket = bucket_cap / added_per_shot
    local shots_left_till_bucket_full = 0


    if wpn:GetWeaponBaseDamage() <= 0 then
        return
    end
    for i = 0, shots_to_fill_bucket + 1, 1 do
        if bucket_current_sim < bucket_cap then
            bucket_current_sim = bucket_current_sim + damage_base
            bucket_current_sim = math.min(bucket_current_sim, bucket_cap)
            -- crit_attempts == wpn_crit_check
            shots_left_till_bucket_full = shots_left_till_bucket_full + 1
        end
    end

    local costs = {}
    bucket_current_sim = bucket_bottom
    for i = 0, shots_to_fill_bucket + 1, 1 do
        if bucket_current_sim < bucket_cap then
            bucket_current_sim = bucket_current_sim + damage_base
            costs[i] = wpn:GetCritCost(bucket_current_sim, crit_request + i + 1, crit_check)
        end
    end

    local storedCrits = 0
    bucket_current_sim = bucket_current
    for i = 0, shots_to_fill_bucket + 1, 1 do
        if bucket_current_sim >= costs[i] then
            bucket_current_sim = bucket_current_sim - costs[i]
            storedCrits = storedCrits + 1
        end
    end


    if wpn:GetWeaponData().useRapidFireCrits then
        taken_per_crit = added_per_shot
        taken_per_crit = taken_per_crit * (2 / wpn:GetWeaponData().timeFireDelay)

        -- (Cathook) Yes this looks dumb but i want to ensure that it matches with valve code
        if taken_per_crit * 3 > bucket_cap then
            taken_per_crit = bucket_cap / 3
        end
    end

    ---- 
    local startpos, txt_x, txt_y = 130, draw.GetTextSize(name)
    draw.FilledRect(startpos, startpos, startpos + txt_x, startpos + txt_y)
    draw.Color(255, 255, 255, 255)
    draw.TextShadow(startpos, startpos, name)
    local wpndebug = {
        variable = {
            _ = nil,
            'server_allow_crit',
            'rapidfire_history',
            'rapidfire_check_time',
            'bucket_current',
            'bucket_cap',
            'bucket_bottom',
            'bucket_start',
            'cost', -- 'variation',
            'wpn_crit_check',
            'wpn_crit_request',
            'observed_crit_chance',
            'wpn_critchance',
            'wpn_seed',
            '(added_per_shot)',
            'total',
            'critical',
            'melee',
            'shots left to fill bucket',
            'how many crits can force',
            'current tick',
            'what tick can crit'
         },
        value = {
            _ = nil,
            server_allow_crit,
            rapidfire_history,
            rapidfire_check_time,
            bucket_current,
            bucket_cap,
            bucket_bottom,
            bucket_start,
            cost,
            crit_check,
            crit_request,
            observed_crit_chance,
            wpn_critchance,
            wpn_seed,
            damage_base,
            stats.total,
            stats.critical,
            stats.melee,
            shots_left_till_bucket_full,
            storedCrits,
            command_number,
            command_num_that_can_crit
         }
     }

    local i, j, space = 0, 0, 0
    for _, name in ipairs(wpndebug.variable) do
        local width, height = draw.GetTextSize(name)
        if width + startpos > space - 100 then
            space = width + startpos + 100
        end
        draw.Text(startpos, startpos + math.floor(height * i) + txt_y * 2, name)
        i = i + 1.3
    end
    draw.Color(36, 255, 122, 255)
    for _, value in ipairs(wpndebug.value) do
        if type(value) == 'number' and math.floor(value) ~= value then
            value = string.format('%.6s', value)
        end
        local width, height = draw.GetTextSize(tostring(value))
        draw.Text(space - (width // 2), startpos + math.floor(height * j) + txt_y * 2, tostring(value))
        j = j + 1.3
    end

    --- 
    draw.Color(255, 255, 255, 255)
    local data, text = {}
    local cmpCritChance = wpn_critchance + 0.1

    if not server_allow_crit then
        data[#data + 1] = 'server disabled crit'
    end

    if wpn:GetWeaponBaseDamage() <= 0 then
        data[#data + 1] = 'no random crit'
    end

    if cmpCritChance < wpn:CalcObservedCritChance() then
        local requiredTotalDamage = (stats.critical * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
        local requiredDamage = requiredTotalDamage - stats.total
        data[#data + 1] = 'deal ' .. math.floor(requiredDamage) .. ' damage'
    end

    if bucket_current < math.floor(cost) then
        data[#data + 1] = 'low bucket'
    end

    if bucket_current == bucket_cap then
        data[#data + 1] = 'bucket reached cap'
    end

    if is_rapid_fire_weapon(wpn) then
        data[#data + 1] = 'uses rapidfire crit'
    end

    if rapidfire_history - globals.CurTime() > 0 then
        data[#data + 1] = 'rapid firing: ' .. string.format('%.4s', rapidfire_history - globals.CurTime())
    end

    text = table.concat(data, ', ')
    txt_x, txt_y = draw.GetTextSize(text)
    draw.Text(width_center - math.floor(txt_x / 2), math.floor(height_center * 1.05), text)
end)

callbacks.Register('CreateMove', function(cmd)
    local me = entities.GetLocalPlayer()
    if (me ~= nil) then
        command_number = cmd.command_number
        local wpn = me:GetPropEntity('m_hActiveWeapon')
        if (wpn ~= nil) then
            if wpn:IsAttackCritical(cmd.command_number) then
                command_num_that_can_crit = cmd.command_number
            end
        end
    end
end)

-- mult_dmg : damage bonus / penalty (modifier)
