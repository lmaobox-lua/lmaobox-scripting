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

local weapon_name_cache = {}
local function get_weapon_name( any )
    if type( any ) == 'number' then
        return weapon_name_cache[any] or get_weapon_name( itemschema.GetItemDefinitionByID( any ) )
    end

    local meta = getmetatable( any )

    if meta['__name'] == 'Entity' then
        return get_weapon_name( any:GetPropInt( 'm_iItemDefinitionIndex' ) )
    end

    if meta['__name'] == 'ItemDefinition' then
        if weapon_name_cache[any] then
            return weapon_name_cache[any]
        end
        local special = tostring( any ):match( 'TF_WEAPON_[%a%A]*' )
        if special then
            local i1 = client.Localize( special )
            if i1:len() ~= 0 then
                weapon_name_cache[any:GetID()] = i1
                return i1
            end
            weapon_name_cache[any:GetID()] = client.Localize( any:GetTypeName():gsub( '_Type', '' ) )
            return weapon_name_cache[any:GetID()]
        end
        for attrDef, value in pairs( any:GetAttributes() ) do
            local name = attrDef:GetName()
            if name == 'paintkit_proto_def_index' or name == 'limited quantity item' then
                weapon_name_cache[any:GetID()] = client.Localize( any:GetTypeName():gsub( '_Type', '' ) )
                return weapon_name_cache[any:GetID()]
            end
        end
        weapon_name_cache[any:GetID()] = tostring( any:GetNameTranslated() )
        return weapon_name_cache[any:GetID()]
    end
end

callbacks.Register( "Draw", function()

    local w, h = draw.GetScreenSize()
    local cw, ch = w // 2, h // 2 + 15
    draw.Color( 255, 255, 255, 255 )
    draw.SetFont( myfont )

    local player = entities.GetLocalPlayer()

    if not player then
        return
    end

    local wpn = player:GetPropEntity( "m_hActiveWeapon" )
    local wpnid = wpn:GetPropInt( 'm_iItemDefinitionIndex' )

    if player:IsAlive() and wpn ~= nil then
        local weapon_item_definition = itemschema.GetItemDefinitionByID( wpnid )
        -- printLuaTable(getmetatable(weapon_item_definition))
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
        local t1, t2, t3, t4 = { 'superior name', 'CanRandomCrit', 'base dmg', 'CritTokenBucket', 'CritCheckCount',
                                 'CritSeedRequestCount', 'CurrentCritSeed', 'CritMult', 'RapidFireCritTime',
                                 'LastRapidFireCritCheckTime', 'CritChance', 'CalcObservedCritChance', 'CritCost',
                                 'totalDmg', 'criticalDmg', 'meleeDmg', 'storedCrits (inaccurate)', 'mult_crit_chance',
                                 'm_flObservedCritChance' },
            { get_weapon_name( weapon_item_definition ), wpn:CanRandomCrit(), baseDmg, tokenBucket, critCheckCount,
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
        if baseDmg <= 0 then
            text = "can it even crit?"
            tw, th = draw.GetTextSize( text )
            return draw.Text( cw - (tw // 2), ch, text )
        end

        if not wpn:CanRandomCrit() or critChance == 0 then
            text = "cannot random crit"
            tw, th = draw.GetTextSize( text )
            return draw.Text( cw - (tw // 2), ch, text )
        end

        if wpn:IsMeleeWeapon() then
            local mult_crit_chance = wpn:AttributeHookFloat( 'mult_crit_chance', critMult * critChance )
        end

        -- printc(255, 0, 255, 255, '----')
        -- printLuaTable(weapon_item_definition:GetAttributes()) -- damage penalty: 0.85000002384186
        -- printc(0, 255, 255, 255, '----')

        if tokenBucket < critCost then
            text = "[Low Bucket] "
            tw, th = draw.GetTextSize( text )
            return draw.Text( cw - (tw // 2), ch, text )
        end

        -- If we are allowed to crit
        if cmpCritChance > wpn:CalcObservedCritChance() and (critSeed > -1 or wpn:GetSwingRange()) then
            text = "Crit ready "
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
