local myfont = draw.CreateFont( "Verdana", 16, 800 )

callbacks.Register( "Draw", function ()
    draw.Color(255, 255, 255, 255)
    draw.SetFont( myfont )

    local player = entities.GetLocalPlayer()
    local wpn = player:GetPropEntity("m_hActiveWeapon")

    if wpn ~= nil then
        local critChance = wpn:GetCritChance()
        local dmgStats = wpn:GetWeaponDamageStats()
        local totalDmg = dmgStats["total"]
        local criticalDmg = dmgStats["critical"]

        -- (the + 0.1 is always added to the comparsion)
        local cmpCritChance = critChance + 0.1

        print(cmpCritChance, wpn:CalcObservedCritChance())

        -- If we are allowed to crit
        if cmpCritChance > wpn:CalcObservedCritChance() then
            draw.Text( 200, 510, "We can crit just fine!")
        else --Figure out how much damage we need
            local requiredTotalDamage = (criticalDmg * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
            local requiredDamage = requiredTotalDamage - totalDmg

            draw.Text( 200, 510, "Damage needed to crit: " .. math.floor(requiredDamage))
        end
    end
end )

