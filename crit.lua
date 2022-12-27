---
--- For LMAOBOX Lua 5.4 (x86|windows)
---

---@type Entity|any
local wpn
local ref = {}
local font = draw.CreateFont('Verdana', 16, 700, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)

local fmt = string.format

--- Note: The calculations aren't a hundred percent accurate, but it's close approximation for me and readers to figure out the rest.
--- Here are some edge case that I didn't handle (on full bucket):
--- 1. Soilder's Direct hit can withdrawn 3 crits
--- 2. Sniper's SMG can withdrawn 2 crits
--- 3. Max withdrawn crit is offset by one on melee weapon
--- 4. Do %d more attacks to get %d crits

local function ServerAllowRandomCrit()
    local tf_weapon_criticals = client.GetConVar('tf_weapon_criticals')
    if wpn:IsMeleeWeapon() then
        local tf_weapon_criticals_melee = client.GetConVar('tf_weapon_criticals_melee')
        return (tf_weapon_criticals and tf_weapon_criticals_melee == 1) or tf_weapon_criticals_melee == 2
    end
    return tf_weapon_criticals == 1
end

callbacks.Register("Draw", function()
    if not wpn then
        return
    end
    local time = wpn:GetRapidFireCritTime() - globals.CurTime()
    local space = 25
    local width, height = 200, 10
    local x, y = 200, 550
    --- your drawing code here, et cetra
    --- you want draw code, i give you :)
    draw.Color(255, 255, 255, 255)
    draw.SetFont(font)
    draw.Text(x, y, fmt("(Crit Stored)\t\t%d out of %d", ref.crits, ref.total))
    y = y + space
    draw.Color(28, 28, 28, 255)
    draw.FilledRect(x, y, x + width, y + height + 10)
    draw.Color(255, 255, 255, 255)
    draw.OutlinedRect(x - 2, y - 2, x + width + 2, y + height + 10)
    --- crit
    draw.Color(30, 255, 0, 255)
    if input.IsButtonDown(gui.GetValue('crit key')) then
        draw.Color(115, 0, 255, 255) -- rgb(115, 0, 255)
    end
    if (time > 0) then
        draw.FilledRect(x, y, x + math.floor(width * (time / 2)), y + height)
    else
        draw.FilledRect(x, y, x + math.floor(width * (ref.crits / ref.total)), y + height)
    end
    --- spent
    draw.Color(30, 255, 0, 255) -- rgb(30, 255, 0)
    draw.FilledRect(x, y, x + math.floor(width * (ref.exp_crits / ref.total)), y + height)
    --- fill bucket
    draw.Color(149, 0, 255, 255) -- rgb(149, 0, 255)
    draw.FilledRect(x, y + height,
        x + math.floor(width * math.min(ref.bucketStored + wpn:GetWeaponBaseDamage(), 1000) / ref.bucketMax)
        , y + height + 8)
    --- bucket
    draw.Color(0, 166, 255, 255) -- rgb(0, 166, 255)
    draw.FilledRect(x, y + height, x + math.floor(width * (ref.bucketStored / ref.bucketMax)), y + height + 8)

    -- x, y = 600, 550
    -- draw.Color(0, 0, 0, 95)
    -- draw.FilledRect(x - 20, y, x + 190, y + 130)
    -- draw.Color(204, 153, 201, 255)
    -- draw.FilledRect(x, y, x + 170, y + 3)
    -- draw.Color(255, 255, 255, 255)
    -- draw.Text(x, y + 20, fmt("Crit fired  \t\t\t\t\t%d", wpn:GetCritSeedRequestCount()))
    -- draw.Text(x, y + 40, fmt("Seed request\t\t\t%d", wpn:GetCritCheckCount()))
    -- draw.Text(x, y + 60, fmt("Bucket        \t\t\t\t%.0f", wpn:GetCritTokenBucket()))
    -- draw.Text(x, y + 80, fmt("Gain      \t\t\t\t\t\t%.0f", wpn:GetWeaponBaseDamage()))
    -- draw.Text(x, y + 100,
    --     fmt("Cost         \t\t\t\t\t%f",
    --         wpn:GetCritCost(wpn:GetCritTokenBucket(), wpn:GetCritCheckCount(), wpn:GetCritSeedRequestCount())))
    -- draw.Color(204, 153, 201, 255)
end)

callbacks.Register("CreateMove", function()
    local me = entities.GetLocalPlayer()
    wpn = me:GetPropEntity("m_hActiveWeapon")

    --- Weapon don't spawn yet
    if not wpn:IsValid() then
        wpn = nil
        return
    end

    local serverAllowCrit = ServerAllowRandomCrit()
    local addedPerShot = wpn:GetWeaponBaseDamage()
    --- This only check if server disabled crit or weapon does not deal damage (defined by WeaponData)
    --- Refer to TF2 Wiki to get a list of weapon that cannot random crit
    if serverAllowCrit == false or addedPerShot <= 0 then
        wpn = nil
        return
    end

    local bucketStored    = wpn:GetCritTokenBucket()
    local bucketMax       = client.GetConVar('tf_weapon_criticals_bucket_cap')
    local weaponCritCount = wpn:GetCritSeedRequestCount()
    local weaponSeedCount = wpn:GetCritCheckCount()

    local need = math.floor(bucketMax / addedPerShot)
    local crits, attacks, total = 0, 0, 0
    local exp_crits = 0

    --- Calculate number of attacks needed to fill entire bucket
    do
        local i, stored = 0, bucketStored
        while stored < bucketMax do
            stored = stored + addedPerShot
            i = i + 1
        end
        attacks = i
    end

    --- Calculate number of crits allowed to withdrawn from bucket
    do
        local i, stored = 0, bucketStored
        local cost      = math.floor(wpn:GetCritCost(stored, weaponCritCount, weaponSeedCount))
        while stored >= cost do
            i = i + 1
            stored = stored - cost
            cost = wpn:GetCritCost(stored, weaponCritCount + i, weaponSeedCount)
        end
        crits = i
    end

    --- Calculate number of crits can be withdrawn when bucket is full
    --- I don't know why, when shooting a lot after you filled the bucket, crit cost reduced, thus you gain additional crits
    do
        local i, cap          = 0, bucketMax
        local weaponSeedCount = weaponSeedCount + attacks
        local weaponCritCount = weaponCritCount - need
        local cost            = math.floor(wpn:GetCritCost(cap, weaponCritCount, weaponSeedCount))
        while cap >= cost do
            cap = cap - cost
            cost = wpn:GetCritCost(cap, weaponCritCount + i, weaponSeedCount)
            i = i + 1
        end
        total = i
    end

    --- Calculate number of crits allowed to withdrawn from bucket after we shot a crit
    --- Is This really needed? 3AM brain is not working
    do
        local i, stored = 0, bucketStored
        local stored    = bucketStored - wpn:GetCritCost(bucketStored, weaponCritCount, weaponSeedCount)
        local cost      = wpn:GetCritCost(stored, weaponCritCount + 1, weaponSeedCount + 1)
        while stored >= cost do
            i = i + 1
            stored = stored - cost
            cost = wpn:GetCritCost(stored, weaponCritCount + i + 1, weaponSeedCount + 1)
        end
        exp_crits = i
    end

    ref = {
        crits = crits,
        exp_crits = exp_crits,
        attacks = attacks,
        total = total,
        cost = math.floor(wpn:GetCritCost(bucketStored, weaponCritCount, weaponSeedCount)),
        bucketStored = bucketStored,
        bucketMax = bucketMax,
    }
end)
