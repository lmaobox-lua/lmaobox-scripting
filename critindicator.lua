-- If you see this error 
-- 50: attempt to concatenate a nil value (field 'shots_left_till_bucket_full')
-- It's safe to ignore! 
-- I was simply caching GetWeaponData() because CreateMove updates more often than Draw
local colors = {
    white = { 255, 255, 255, 255 },
    gray = { 190, 190, 190, 255 },
    red = { 255, 0, 0, 255 },
    green = { 36, 255, 122, 255 },
    blue = { 30, 139, 195, 255 }
 }

local other_weapon_info = {
    crit_chance = 0,
    observedCritChance = 0,
    damageStats = {}
 }
local cache_weapon_info = {
    [0] = {}
 }
function cache_weapon_info.get(critCheckCount)
    if cache_weapon_info[0].critCheckCount == critCheckCount then
        return cache_weapon_info[0], false
    end
end
function cache_weapon_info.update(t)
    for k, v in pairs(t) do
        cache_weapon_info[0][k] = v
    end
end

local hardcoded_weapon_ids = {}
local arr = { 441, 416, 40, 594, 595, 813, 834, 141, 1004, 142, 232, 61, 1006, 525, 132, 1082, 266, 482, 327, 307, 357,
              404, 812, 833, 237, 265, 155, 230, 460, 1178, 14, 201, 56, 230, 402, 526, 664, 752, 792, 801, 851, 881,
              890, 899, 908, 957, 966, 1005, 1092, 1098, 15000, 15007, 15019, 15023, 15033, 15059, 15070, 15071, 15072,
              15111, 15112, 15135, 15136, 15154, 30665, 194, 225, 356, 461, 574, 638, 649, 665, 727, 794, 803, 883, 892,
              901, 910, 959, 968, 15062, 15094, 15095, 15096, 15118, 15119, 15143, 15144, 131, 406, 1099, 1144, 46, 42,
              311, 863, 1002, 159, 433, 1190, 129, 226, 354, 1001, 1101, 1179, 642, 133, 444, 405, 608, 57, 231, 29,
              211, 35, 411, 663, 796, 805, 885, 894, 903, 912, 961, 970, 998, 15008, 15010, 15025, 15039, 15050, 15078,
              15097, 15121, 15122, 15123, 15145, 15146, 30, 212, 59, 60, 297, 947, 735, 736, 810, 831, 933, 1080, 1102,
              140, 1086, 30668, 25, 737, 26, 28, 222, 1121, 1180, 58, 1083, 1105 }
for i = 1, #arr do
    hardcoded_weapon_ids[arr[i]] = true
end

local function CanFireCriticalShot(me, wpn)
    if me:GetPropInt('m_iClass') == TF2_Spy and wpn:IsMeleeWeapon() then
        return false
    end
    local className = wpn:GetClass()
    if className == 'CTFSniperRifle' or className == 'CTFBuffItem' or className == 'CTFWeaponLunchBox' then
        return false
    end
    if hardcoded_weapon_ids[wpn:GetPropInt('m_iItemDefinitionIndex')] then
        return false
    end
    if wpn:GetCritChance() <= 0 then
        return false
    end
    if wpn:GetWeaponBaseDamage() <= 0 then
        return false
    end
    return true
end

local fontid = draw.CreateFont('Verdana', 16, 700, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)
callbacks.Unregister('Draw', 'Draw-F3drQ')
callbacks.Register('Draw', 'Draw-F3drQ', function()
    local me, wpn
    me = entities.GetLocalPlayer()
    if me and me:IsAlive() then
        wpn = me:GetPropEntity('m_hActiveWeapon')
        if not (wpn and wpn:IsWeapon() and CanFireCriticalShot(me, wpn)) then
            return
        end
    else
        return
    end

    local x, y = 600, 800
    draw.SetFont(fontid)

    local weaponinfo = cache_weapon_info[0]

    local sv_allow_crit = wpn:CanRandomCrit()
    if wpn:IsMeleeWeapon() then
        local tf_weapon_criticals_melee = client.GetConVar('tf_weapon_criticals_melee')
        sv_allow_crit = (sv_allow_crit and tf_weapon_criticals_melee == 1) or (tf_weapon_criticals_melee == 2)
    end

    local mult = 0
    local elements = {}
    elements[1] = { 'Crit',
                    (me:IsCritBoosted() or me:InCond(TFCond_CritCola)) and colors.blue or sv_allow_crit and colors.green or
        colors.gray }
    elements[2] = { weaponinfo.shots_left_till_bucket_full .. ' attacks left until full bar', nil,
                    weaponinfo.shots_left_till_bucket_full ~= 0 }
    elements[3] = { weaponinfo.stored_crits .. ' crits available' }
    elements[4] = { 'deal ' .. math.floor(other_weapon_info.requiredDamage) .. ' damage', nil,
                    (other_weapon_info.critChance + 0.1 < other_weapon_info.observedCritChance) }
    elements[5] = { 'streaming crit', colors.red, wpn:GetRapidFireCritTime() > wpn:GetLastRapidFireCritCheckTime() }
    for i = 1, #elements, 1 do
        local text, color, visible = elements[i][1], elements[i][2] or colors.white, elements[i][3]
        draw.Color(color[1], color[2], color[3], color[4])
        if visible ~= false then
            draw.Text(x, y + mult, text)
            mult = mult + 20
        end
    end
end)

callbacks.Unregister('CreateMove', 'CreateMove-N8bat')
callbacks.Register('CreateMove', 'CreateMove-N8bat', function()
    local me, wpn
    me = entities.GetLocalPlayer()
    if me and me:IsAlive() then
        wpn = me:GetPropEntity('m_hActiveWeapon')
        if not (wpn and wpn:IsWeapon() and CanFireCriticalShot(me, wpn)) then
            return
        end
    else
        return
    end

    local weaponinfo, needupdate = cache_weapon_info.get(wpn:GetCritCheckCount())
    if needupdate == nil or wpn:GetIndex() ~= weaponinfo.currentWeapon then
        -- printc(255, 0, 0, 255, 'updating weaponinfo...')
        weaponinfo = setmetatable({}, {
            __index = wpn:GetWeaponData()
         })
        -- LuaFormatter off
        weaponinfo.currentWeapon                  = wpn:GetIndex()   
        weaponinfo.isRapidFire                    = weaponinfo.useRapidFireCrits or wpn:GetClass() == 'CTFMinigun' 
        weaponinfo.currentCritSeed                = wpn:GetCurrentCritSeed()
        weaponinfo.bulletsPerShot                 = wpn:AttributeHookFloat('mult_bullets_per_shot', weaponinfo.bulletsPerShot)
        weaponinfo.added_per_shot                 = wpn:GetWeaponBaseDamage()
        weaponinfo.bucket                         = wpn:GetCritTokenBucket()
        weaponinfo.bucket_max                     = client.GetConVar('tf_weapon_criticals_bucket_cap')
        weaponinfo.bucket_min                     = client.GetConVar('tf_weapon_criticals_bucket_bottom')
        weaponinfo.bucket_start                   = client.GetConVar('tf_weapon_criticals_bucket_default')
        weaponinfo.critRequestCount               = wpn:GetCritSeedRequestCount()
        weaponinfo.critCheckCount                 = wpn:GetCritCheckCount()
        weaponinfo.shots_to_fill_bucket           = weaponinfo.bucket_max / weaponinfo.added_per_shot
        weaponinfo.costs                          = {}
        weaponinfo.stored_crits                   = 0
        weaponinfo.shots_left_till_bucket_full    = 0
        -- LuaFormatter on

        local temp, temp1, temp2
        temp = weaponinfo.bucket_min
        temp1 = weaponinfo.bucket
        temp2 = weaponinfo.bucket

        --- FIXME : random bullshit go
        if wpn:IsMeleeWeapon() then
            local min = wpn:GetCritCost(temp, weaponinfo.critRequestCount, weaponinfo.critCheckCount)
            while temp1 > min do
                weaponinfo.stored_crits = weaponinfo.stored_crits + 1
                min = min +
                          wpn:GetCritCost(min, weaponinfo.critRequestCount + weaponinfo.stored_crits,
                                          weaponinfo.critCheckCount)
                if temp2 < weaponinfo.bucket_max then
                    temp2 = math.min(temp2 + weaponinfo.added_per_shot, weaponinfo.bucket_max)
                    weaponinfo.shots_left_till_bucket_full = weaponinfo.shots_left_till_bucket_full + 1
                end
                local temp3 = min +
                                  wpn:GetCritCost(min, weaponinfo.critRequestCount + weaponinfo.stored_crits + 1,
                                                  weaponinfo.critCheckCount) + weaponinfo.added_per_shot -
                                  weaponinfo.shots_to_fill_bucket
                if temp3 > weaponinfo.bucket_max then
                    break
                end
            end
        else
            for i = 0, weaponinfo.shots_to_fill_bucket + 1, 1 do
                if temp < weaponinfo.bucket_max then
                    temp = math.min(temp + weaponinfo.added_per_shot, weaponinfo.bucket_max)
                    weaponinfo.costs[i] = wpn:GetCritCost(temp, weaponinfo.critRequestCount + i,
                                                          weaponinfo.critCheckCount)
                end
                if temp1 >= weaponinfo.costs[i] then
                    temp1 = temp1 - weaponinfo.costs[i]
                    weaponinfo.stored_crits = weaponinfo.stored_crits + 1
                end
                if temp2 < weaponinfo.bucket_max then
                    temp2 = math.min(temp2 + weaponinfo.added_per_shot, weaponinfo.bucket_max)
                    weaponinfo.shots_left_till_bucket_full = weaponinfo.shots_left_till_bucket_full + 1
                end
            end
        end

        cache_weapon_info.update(weaponinfo)
    end

    -- from bf : weapon state affects the crit rate and for some reason the non revved state doesnt have bIsRapidFire afaik
    -- may cause inaccurate result on custom server / when reload script (due to hardcoded value)
    local critChance = wpn:GetCritChance()
    if weaponinfo.isRapidFire then
        critChance = 0.0102
    end

    -- TODO : figure out why holding mouse 1 with heavy still allow you to crit despite cmpChance + 0.1 < observedCritChance 
    local damageStats = wpn:GetWeaponDamageStats()
    local cmpCritChance = critChance + 0.1
    local requiredTotalDamage = (damageStats['critical'] * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
    other_weapon_info.requiredDamage = requiredTotalDamage - damageStats['total']
    other_weapon_info.observedCritChance = wpn:CalcObservedCritChance()
    other_weapon_info.critChance = critChance
    other_weapon_info.damageStats = damageStats
end)
