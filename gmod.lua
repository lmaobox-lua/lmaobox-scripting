-- totem item
callbacks.Unregister( 'Draw', 'steal_random_cunt_loadout', steal_random_cunt_loadout )

local yoinked = false
local selected = 0

local steal_random_cunt_loadout = function()
    if not input.IsButtonDown( KEY_L ) then
        return
    end

    local me = entities.GetLocalPlayer()
    local players = entities.FindByClass( "CTFPlayer" )
    local data

    for i, p in ipairs( players ) do
        if p:IsAlive() and not p:IsDormant() and not (p == me) and not yoinked then
            selected = p:GetEntityForLoadoutSlot( LOADOUT_POSITION_MISC )
            --id = ItemDefinition.GetItemDefinitionByID( selected:GetPropInt( "m_iItemDefinitionIndex" ) )
            if not (selected:IsValid()) then
                goto gmod
            end
            print( "Item has been found: " .. selected:GetClass() .. " | " .. selected:GetIndex() .. "| " )
            data = selected:ToInventoryItem()
            if not data then goto gmod end
            print(data:GetName())
            yoinked = true
            ::gmod::
        end
    end

end
callbacks.Register( 'Draw', 'steal_random_cunt_loadout', steal_random_cunt_loadout )

-- 103.151.56.220:27015
