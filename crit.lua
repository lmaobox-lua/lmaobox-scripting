local myfont = draw.CreateFont( "verdana", 2 ^ 4, 800, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW )
local myfont2 = draw.CreateFont( 'verdana', 2 ^ 4, 600, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE )

callbacks.Register( 'CreateMove', function( cmd )
    local player = entities.GetLocalPlayer()
    local wpn = player:GetPropEntity( "m_hActiveWeapon" )

    if player:IsAlive() and wpn ~= nil then
        if wpn:IsAttackCritical( cmd.command_number ) == true then
            -- printc(255, 0, 255, 255, cmd.command_number)
        end
    end
end )

local critState = { CRIT_BUCKET_EMPTY, CRIT_OBSERVED_CAP, CRIT_DISABLED, CRIT_BOOSTED_EXTERNAL_SOURCE, CRIT_STREAMING }

callbacks.Register( "Draw", function()
    local w, h = draw.GetScreenSize()
    local cw, ch = w // 2, h // 2 + 15
    draw.Color( 255, 255, 255, 255 )
    draw.SetFont( myfont )

    local player = entities.GetLocalPlayer()
    local wpn = player:GetPropEntity( "m_hActiveWeapon" )
    local wpnid = wpn:GetPropInt( 'm_iItemDefinitionIndex' )

    if player:IsAlive() and wpn ~= nil then
        local weapon_item_definition = itemschema.GetItemDefinitionByID( wpnid )
        local tokenBucket, critCheckCount, critSeedRequestCount, critSeed, rapidFireCritTime,
            lastRapidFireCritCheckTime, critChance, critCost, dmgStats, totalDmg, criticalDmg, meleeDmg, baseDmg,
            calcObservedCritChance, critMult

        tokenBucket = wpn:GetCritTokenBucket()
        baseDmg = wpn:GetWeaponBaseDamage()
        critCheckCount = wpn:GetCritCheckCount()
        critSeedRequestCount = wpn:GetCritSeedRequestCount()
        critSeed = wpn:GetCurrentCritSeed()
        critMult = wpn:GetCritMult()
        rapidFireCritTime = wpn:GetRapidFireCritTime()
        lastRapidFireCritCheckTime = wpn:GetLastRapidFireCritCheckTime()
        critChance = wpn:GetCritChance()
        calcObservedCritChance = wpn:CalcObservedCritChance()
        critCost = wpn:GetCritCost( tokenBucket, critSeedRequestCount, critCheckCount )
        dmgStats = wpn:GetWeaponDamageStats()
        totalDmg = dmgStats.total
        criticalDmg = dmgStats.critical
        meleeDmg = dmgStats.melee

        -- draw.Text limits to 511 char
        draw.SetFont( myfont2 )
        local t1, t2, t3, t4 = { 'superior name', 'base dmg', 'CritTokenBucket', 'CritCheckCount',
                                 'CritSeedRequestCount', 'CurrentCritSeed', 'CritMult', 'RapidFireCritTime',
                                 'LastRapidFireCritCheckTime', 'CritChance', 'CalcObservedCritChance', 'CritCost',
                                 'totalDmg', 'criticalDmg', 'meleeDmg', 'storedCrits (inaccurate)', 'mult_crit_chance',
                                 'm_flObservedCritChance' },
            { tostring( weapon_item_definition:GetNameTranslated() ),  baseDmg, tokenBucket, critCheckCount,
              critSeedRequestCount, critSeed, critMult, rapidFireCritTime, lastRapidFireCritCheckTime, critChance,
              calcObservedCritChance, critCost, totalDmg, criticalDmg, meleeDmg, tokenBucket // critCost,
              wpn:AttributeHookFloat( 'mult_crit_chance' ), wpn:GetPropFloat( 'm_flObservedCritChance' ) }, 150, 0
        for i, name in ipairs( t1 ) do
            local tw, th = draw.GetTextSize( name )
            t4 = t4 < tw and tw or t4
            draw.Text( 100, t3, name )
            t3 = t3 + th
        end
        t3 = 150
        for i, name in ipairs( t2 ) do
            draw.Color( 36, 255, 122, 255 )
            if type( name ) == 'number' then
                name = tonumber( string.format( "%.3f", name ) )
            end
            name = tostring( name )
            local tw, th = draw.GetTextSize( name )
            draw.Text( 100 + t4 + 20, t3, name )
            t3 = t3 + th
        end
        draw.SetFont( myfont )

        -- (the + 0.1 is always added to the comparsion)
        local cmpCritChance = critChance + 0.1
        draw.Color( 255, 255, 255, 255 )
        local text, tw, th

        --[[
            if critcheckcount == 0, crit seed won't be updated
        ]]


        -- invalid + hardcode value
        if not wpn:CanRandomCrit() then
            text = "Random crit disabled :("
            tw, th = draw.GetTextSize( text )
            return draw.Text( cw - (tw // 2), ch, text )
        end

        if wpn:IsMeleeWeapon() then
            local mult_crit_chance = wpn:AttributeHookFloat( 'mult_crit_chance' )
            -- print(mult_crit_chance)
        end

        -- printc(255, 0, 255, 255, '----')
        -- printLuaTable(weapon_item_definition:GetAttributes()) -- damage penalty: 0.85000002384186
        -- printc(0, 255, 255, 255, '----')

        if tokenBucket < critCost then
            text = "Bucket is low"
            tw, th = draw.GetTextSize( text )
            return draw.Text( cw - (tw // 2), ch, text )
        end

        -- If we are allowed to crit
        if cmpCritChance > wpn:CalcObservedCritChance() and (critSeed > -1 or wpn:GetSwingRange()) then
            text = "Crit ready"
            tw, th = draw.GetTextSize( text )
            draw.Text( cw - (tw // 2), ch, text )
        else -- Figure out how much damage we need
            local requiredTotalDamage = (criticalDmg * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
            local requiredDamage = requiredTotalDamage - totalDmg
            text = "Damage needed to crit: " .. math.floor( requiredDamage )
            tw, th = draw.GetTextSize( text )
            draw.Text( cw - (tw // 2), ch, text )
        end
    end
end )

--[[
            tokenBucket = wpn:GetCritTokenBucket()
        critCheckCount = wpn:GetCritCheckCount()
        critSeedRequestCount = wpn:GetCritSeedRequestCount()
        critSeed = wpn:GetCurrentCritSeed()
        rapidFireCritTime = wpn:GetRapidFireCritTime()
        critChance = wpn:GetCritChance()
        critCost = wpn:GetCritCost( tokenBucket, critSeedRequestCount, critCheckCount )
        dmgStats = wpn:GetWeaponDamageStats()
        totalDmg = dmgStats.total
        criticalDmg = dmgStats.critical
        meleeDmg = dmgStats.melee
]]
