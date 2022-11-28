---@author:  2022-11-28 16:02:52
-- If you see this error: attempt to concatenate a nil value (field 'attacksTillBucketFull')
-- It's safe to ignore! 
-- I was simply caching GetWeaponData() because CreateMove updates more often than Draw
local colors = {
    white = { 255, 255, 255, 255 },
    gray = { 190, 190, 190, 255 },
    red = { 255, 0, 0, 255 },
    green = { 36, 255, 122, 255 },
    blue = { 30, 139, 195, 255 }
 }

local storage = {
    [0] = {}
 }

-- LuaFormatter off
local weapon_cannot_randomly_crit = { [441]=true,[416]=true,[40]=true,[594]=true,[595]=true,[813]=true,[834]=true,[141]=true,[1004]=true,[142]=true,[232]=true,[61]=true,[1006]=true,[525]=true,[132]=true,[1082]=true,[266]=true,[482]=true,[327]=true,[307]=true,[357]=true,[404]=true,[812]=true,[833]=true,[237]=true,[265]=true,[155]=true,[460]=true,[1178]=true,[14]=true,[201]=true,[56]=true,[230]=true,[402]=true,[526]=true,[664]=true,[752]=true,[792]=true,[801]=true,[851]=true,[881]=true,[890]=true,[899]=true,[908]=true,[957]=true,[966]=true,[1005]=true,[1092]=true,[1098]=true,[15000]=true,[15007]=true,[15019]=true,[15023]=true,[15033]=true,[15059]=true,[15070]=true,[15071]=true,[15072]=true,[15111]=true,[15112]=true,[15135]=true,[15136]=true,[15154]=true,[30665]=true,[194]=true,[225]=true,[356]=true,[461]=true,[574]=true,[638]=true,[649]=true,[665]=true,[727]=true,[794]=true,[803]=true,[883]=true,[892]=true,[901]=true,[910]=true,[959]=true,[968]=true,[15062]=true,[15094]=true,[15095]=true,[15096]=true,[15118]=true,[15119]=true,[15143]=true,[15144]=true,[131]=true,[406]=true,[1099]=true,[1144]=true,[46]=true,[42]=true,[311]=true,[863]=true,[1002]=true,[159]=true,[433]=true,[1190]=true,[129]=true,[226]=true,[354]=true,[1001]=true,[1101]=true,[1179]=true,[642]=true,[133]=true,[444]=true,[405]=true,[608]=true,[57]=true,[231]=true,[29]=true,[211]=true,[35]=true,[411]=true,[663]=true,[796]=true,[805]=true,[885]=true,[894]=true,[903]=true,[912]=true,[961]=true,[970]=true,[998]=true,[15008]=true,[15010]=true,[15025]=true,[15039]=true,[15050]=true,[15078]=true,[15097]=true,[15121]=true,[15122]=true,[15123]=true,[15145]=true,[15146]=true,[30]=true,[212]=true,[59]=true,[60]=true,[297]=true,[947]=true,[735]=true,[736]=true,[810]=true,[831]=true,[933]=true,[1080]=true,[1102]=true,[140]=true,[1086]=true,[30668]=true,[25]=true,[737]=true,[26]=true,[28]=true,[222]=false,[1121]=false,[1180]=false,[58]=false,[1083]=false,[1105]=false}
-- LuaFormatter on

local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

local function remap_val_clamped(val, A, B, C, D)
    if A == B then
        return val >= B and D or C
    end
    local cVal = (val - A) / (B - A)
    cVal = clamp(cVal, 0.0, 1.0)
    return C + (D - C) * cVal;
end

local function can_fire_critical_shot(character, itemDefinitionIndex, weaponBaseDamge)
    if character == TF2_Spy then
        return not wpn:IsMeleeWeapon()
    end
    if weapon_cannot_randomly_crit[itemDefinitionIndex] then
        return false
    end
    if weaponBaseDamge <= 0 then
        return false
    end
    return true
end

local fontID = draw.CreateFont('Verdana', 16, 700, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)
callbacks.Unregister('Draw', 'Draw-F3drQ')
callbacks.Register('Draw', 'Draw-F3drQ', function()
    if clientstate.GetClientSignonState() ~= 6 or not storage.weaponCanRandomCrit then
        return
    end

    local me, wpn
    me = entities.GetLocalPlayer()
    wpn = me:GetPropEntity('m_hActiveWeapon')

    local x, y = 600, 800
    draw.SetFont(fontID)

    local cache = storage[0]

    local sv_allow_crit = wpn:CanRandomCrit()
    if wpn:IsMeleeWeapon() then
        local tf_weapon_criticals_melee = client.GetConVar('tf_weapon_criticals_melee')
        sv_allow_crit = (sv_allow_crit and tf_weapon_criticals_melee == 1) or tf_weapon_criticals_melee == 2
    end

    local space = 0
    local elements = {}
    function elements:insert(...)
        self[#self + 1] = table.pack(...)
    end
    local ratio = (cache.critCheckCount / cache.critRequestCount) < 10 and cache.critCheckCount > 0 and
                      cache.critRequestCount > 0
    local cmp = (storage.critChance + 0.1 < storage.observedCritChance)
    local critBoosted = (me:IsCritBoosted() or me:InCond(TFCond_CritCola))
    local subsequence = 0

    elements:insert('Crit', critBoosted and colors.blue or sv_allow_crit and colors.green or colors.gray)
    elements:insert(cache.attacksTillBucketFull .. ' attacks left until full bar', nil, cache.attacksTillBucketFull ~= 0)
    elements:insert(cache.storedCrits .. ' crits available')
    elements:insert('deal ' .. math.floor(storage.requiredDamage) .. ' damage', nil, cmp)
    elements:insert('streaming crit', colors.green, wpn:GetRapidFireCritTime() > globals.CurTime())

    for i = 1, #elements, 1 do
        local text, color, canRender = elements[i][1], elements[i][2] or colors.white, elements[i][3]
        draw.Color(color[1], color[2], color[3], color[4])
        if canRender ~= false then
            draw.Text(x, y + space, text)
            space = space + 20
        end
    end
end)

callbacks.Unregister('CreateMove', 'CreateMove-N8bat')
callbacks.Register('CreateMove', 'CreateMove-N8bat', function()
    local me, wpn, weapondata, cache
    me = entities.GetLocalPlayer()
    -- LuaFormatter off
    storage.weaponCanRandomCrit = false
    if me:IsAlive() then
        wpn = me:GetPropEntity('m_hActiveWeapon')
        if not wpn then return end
        if not can_fire_critical_shot(me:GetPropInt('m_iClass'), wpn:GetPropInt('m_iItemDefinitionIndex'), wpn:GetWeaponBaseDamage()) then return end
    else return end
    storage.weaponCanRandomCrit = true
    -- LuaFormatter on
    weapondata = wpn:GetWeaponData()

    --- Before you do anything stupid, do not remove those checks below
    cache = storage[0]
    if wpn:GetIndex() ~= cache.idx or cache.bucket ~= wpn:GetCritTokenBucket() or cache.critCheckCount ~=
        wpn:GetCritCheckCount() then
        -- printc(255, 0, 0, 255, '[crit] updating weaponinfo...')
        -- LuaFormatter off
        cache.idx                     = wpn:GetIndex()
        cache.weapondata              = weapondata
        cache.currentCritSeed         = wpn:GetCurrentCritSeed()
        cache.bulletsPerShot          = wpn:AttributeHookFloat('mult_bullets_per_shot', weapondata.bulletsPerShot)
        cache.addedPerShot            = wpn:GetWeaponBaseDamage()
        cache.bucket                  = wpn:GetCritTokenBucket()
        cache.bucketMax               = client.GetConVar('tf_weapon_criticals_bucket_cap')
        -- cache.bucketMin            = client.GetConVar('tf_weapon_criticals_bucket_bottom')
        -- cache.bucketStart          = client.GetConVar('tf_weapon_criticals_bucket_default')
        cache.critRequestCount        = wpn:GetCritSeedRequestCount()
        cache.critCheckCount          = wpn:GetCritCheckCount()
        cache.storedCrits             = 0
        cache.attacksTillBucketFull   = 0
        -- LuaFormatter on

        --- If you reload script while 
        local i, j = 0, 0
        local tmp, cost
        cost = wpn:GetCritCost(0, cache.critRequestCount, cache.critCheckCount)

        tmp = cache.bucket
        while tmp > cost do
            i = i + 1
            cost = wpn:GetCritCost(tmp, cache.critRequestCount + i, cache.critCheckCount)
            tmp = tmp - cost
            print((string.format('[crit] stored: %.2d | %6.6g - %4.6g = %6.6g', i, tmp + cost, cost, tmp)))
        end

        tmp = cache.bucket
        while tmp < cache.bucketMax do
            tmp = tmp + cache.addedPerShot
            j = j + 1
        end
        -- print('------------------------------------------------------------------')

        cache.storedCrits = i
        cache.attacksTillBucketFull = j
    end
    storage[0] = cache

    --- Re-implement custom GetCritChance() because minigun's spinning weapon state has different crit chance 
    local weaponCritChance, critMult, critChance

    weaponCritChance = wpn:IsMeleeWeapon() and 0.15 or 0.02
    critMult = remap_val_clamped(me:GetPropInt('m_iCritMult'), 0, 255, 1, 4)
    critChance = wpn:AttributeHookFloat('mult_crit_chance', critMult * weaponCritChance)

    if weapondata.useRapidFireCrits then
        -- get the total crit chance (ratio of total shots fired we want to be crits)
        local totalCritChance = clamp(0.02 * critMult, 0.01, 0.99)
        -- get the fixed amount of time that we start firing crit shots for	
        local rapidCritDuration = 2
        -- calculate the amount of time, on average, that we want to NOT fire crit shots for in order to achieve the total crit chance we want
        local nonCritDuration = (rapidCritDuration / totalCritChance) - rapidCritDuration
        -- calculate the chance per second of non-crit fire that we should transition into critting such that on average we achieve the total crit chance we want
        local startCritChance = 1 / nonCritDuration
        critChance = wpn:AttributeHookFloat('mult_crit_chance', startCritChance)
    end

    --- This, CalcObservedCritChance(), i have no clue
    local roundDamageStats = wpn:GetWeaponDamageStats()
    local cmpCritChance = critChance + 0.1
    local requiredTotalDamage = (roundDamageStats['critical'] * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
    storage.requiredDamage = math.ceil(requiredTotalDamage - roundDamageStats['total'])
    storage.observedCritChance = wpn:CalcObservedCritChance()
    storage.critChance = critChance
    storage.roundDamageStats = roundDamageStats

end)
