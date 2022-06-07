UnloadScript( GetScriptName() )

local def = {
    SIGNONSTATE_NONE0 = 0, -- no state yet, about to connect
    SIGNONSTATE_CHALLENGE = 1, -- client challenging server, all OOB packets
    SIGNONSTATE_CONNECTED = 2, -- client is connected to server, netchans ready
    SIGNONSTATE_NEW = 3, -- just got serverinfo and string tables
    SIGNONSTATE_PRESPAWN = 4, -- received signon buffers
    SIGNONSTATE_SPAWN = 5, -- ready to receive entity packets
    SIGNONSTATE_FULL = 6, -- we are fully connected, first non-delta packet received
    SIGNONSTATE_CHANGELEVEL = 7, -- server is changing level, please wait
    ---
    LOADOUT_POSITION_PRIMARY = 0,
    LOADOUT_POSITION_SECONDARY = 1,
    LOADOUT_POSITION_MELEE = 2,
    LOADOUT_POSITION_UTILITY = 3,
    LOADOUT_POSITION_BUILDING = 4,
    LOADOUT_POSITION_PDA = 5,
    LOADOUT_POSITION_PDA2 = 6,
    LOADOUT_POSITION_HEAD = 7,
    LOADOUT_POSITION_MISC = 8,
    LOADOUT_POSITION_ACTION = 9,
    LOADOUT_POSITION_MISC2 = 10,
    LOADOUT_POSITION_TAUNT = 11,
    LOADOUT_POSITION_TAUNT2 = 12,
    LOADOUT_POSITION_TAUNT3 = 13,
    LOADOUT_POSITION_TAUNT4 = 14,
    LOADOUT_POSITION_TAUNT5 = 15,
    LOADOUT_POSITION_TAUNT6 = 16,
    LOADOUT_POSITION_TAUNT7 = 17,
    LOADOUT_POSITION_TAUNT8 = 18,
 }

local to_unicode = function( s )
    s = tostring( s )
    return utf8.char( string.byte( s, 1, #s ) )
end

local get_weapon_name = function( itemdef )
    return (itemdef:IsBaseItem() == true or string.find( tostring( itemdef ), 'Upgradeable' )) and
               to_unicode( client.Localize( tostring( itemdef:GetTypeName() ) ) ) or to_unicode( tostring( itemdef:GetNameTranslated() ) )
end

local font_veranda = draw.CreateFont( 'Tahoma', 14, 700, FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW )

local teamcol = {}
teamcol[3] = { 153, 204, 255 }
teamcol[2] = { 255, 64, 64 }

callbacks.Register( 'Draw', function()
    local connected = clientstate.GetClientSignonState() == def.SIGNONSTATE_FULL
    if not connected then return end

    local me = entities.GetLocalPlayer()
    local x, y = 500, 0
    local iter = 0
    for index, e in pairs( entities.FindByClass( 'CTFPlayer' ) ) do
        if not e:IsAlive() or iter > 12 then goto skip end

        local weapon, weapon_loadout_position, weaponid, weapon_item_definition
        weapon = e:GetPropEntity( 'm_hActiveWeapon' )
        weapon_loadout_position = weapon:GetLoadoutSlot()
        weaponid = weapon:GetPropInt( 'm_iItemDefinitionIndex' )

        if not weaponid then goto skip end
        iter = iter + 1
        weapon_item_definition = itemschema.GetItemDefinitionByID( weaponid )
        -- LuaFormatter off
        print( '-- start --' )
        print( string.format( '1, %s', weapon_item_definition:GetName() ),
               string.format( '2, %s', weapon_item_definition:GetNameTranslated() ),
               string.format( '3, %s', weapon_item_definition:GetTypeName() ), -- IsBaseItem()
        string.format( '4, %s', weapon_item_definition:GetBaseItemName() ), string.format( '5, %s', weapon_item_definition:GetClass() ),
               weapon_item_definition:GetDescription() or '' )
        print( '--- end --- ' )
        -- LuaFormatter on
        local name = get_weapon_name( weapon_item_definition ) -- =to_unicode( client.Localize( tostring( weapon_item_definition:GetTypeName() ) ) )
        local inv_item = weapon:ToInventoryItem()
        local icon = inv_item:GetImageTextureID()

        if icon == -1 then
            printc( 255, 255, 0, 255, string.format( 'Item: %s (%d), ID:%d does not contain texture', name, icon, inv_item:GetItemID() ) )
        else
            printc( 0, 255, 0, 255, icon )
            draw.Color( 255, 255, 255, 255 )
            draw.TexturedRect( icon, x, y, x + 64, y + 64 )
        end

        local team = e:GetTeamNumber()
        local r, g, b = table.unpack( teamcol[team] )

        draw.SetFont( font_veranda )
        draw.Color( r, g, b, 255 )
        draw.Text( x, y, string.format( '%s : %s', e:GetName(), name ) )

        local ysize = (select( 2, draw.GetTextureSize( icon ) ) * 0.25 // 1)
        ysize = ysize > 64 and 64 or select( 2, draw.GetTextSize( name ) )
        y = y + ysize
        ::skip::
    end
end )
