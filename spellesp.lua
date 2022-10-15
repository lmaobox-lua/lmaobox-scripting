local function get_entities( start, stop )
    local t = {}
    start = start or 1
    stop = stop or 2048
    for index = start, stop do
        local e = entities.GetByIndex( index )
        if e and not e:IsDormant() then
            t[index] = e
        end
    end
    return t
end

local function dump_materials( ... )
    local include = {}
    local args = { ... }
    if #args == 0 then
        include['*'] = true
    else
        for pos, value in ipairs( args ) do
            include[value] = true
        end
    end
    local t = {}
    materials.Enumerate( function( mat )
        local group = mat:GetTextureitem_name()
        if not t[group] then
            t[group] = {}
        end
        if include[group] or include['*'] then
            t[group][mat:GetName()] = mat
        end
    end )
    return t
end

local function round( num, numDecimalPlaces )
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor( num * mult + 0.5 ) / mult
end

local translations = {
    ["ITEM_SPELL"] = {
        ["localized_string_key"] = "TF_Spellbook_Type",
        ["localized_fallback"] = "Spell"
     },
    ["ITEM_SPELL_RARE"] = {
        ["localized_fallback"] = "Rare Spell"
     }
 }
for k, t in pairs( translations ) do
    local localized_str = client.Localize( t["localized_string_key"] or '' )
    ::checkpoint::
    if not localized_str or #localized_str:gsub( "%s", '' ) < 1 then
        localized_str = t["localized_fallback"]
    end
    translations[k] = localized_str
end

local spell_e = {
    [-2] = "", -- Rolling spell
    [-1] = nil,
    [0] = "Fireball",
    "Swarm of Bats",
    "Overheal",
    "Pumpkin MIRV",
    "Blast Jump",
    "Stealth",
    "Shadow Leap",
    "Ball O' Lightning",
    "Power Up",
    "Meteor Shower",
    "Summon MONOCULUS",
    "Skeletons Horde",
    "Boxing Rocket",
    "B.A.S.E. Jump",
    "Overheal",
    "Bomb Head",
 }
for index = 0, #spell_e do
    local name = spell_e[index]
    if translations[name] then
        spell_e[index] = translations[name]
    end
end

local esp = {}
local models_struct = {
    ["ITEM_SPELL"] = { "models/props_halloween/hwn_spellbook_incomplete.mdl",
                       "models/props_halloween/hwn_spellbook_magazine.mdl",
                       "models/props_halloween/hwn_spellbook_page.mdl",
                       "models/props_halloween/hwn_spellbook_upright.mdl", "models/items/crystal_ball_pickup.mdl",
                       "models/props_monster_mash/flask_vial_green.mdl" },
    ["ITEM_SPELL_RARE"] = { "models/props_halloween/hwn_spellbook_upright_major.mdl",
                            "models/items/crystal_ball_pickup_major.mdl",
                            "models/props_monster_mash/flask_vial_purple.mdl" }
 }
local models = {}
for item_name, group in pairs( models_struct ) do
    item_name = translations[item_name]
    esp[item_name] = {}
    for _, item in pairs( group ) do
        models[item] = item_name
    end
    -- models_struct[item_name] = nil 
end

callbacks.Register( "DrawModel", function( ctx )
    local name, entity
    name = ctx:GetModelName()
    entity = ctx:GetEntity()
    local item_name = models[name]
    if item_name then
        esp[item_name][entity:GetIndex()] = entity
    end
end )

callbacks.Register( "Draw", function()
    local screenwidth, screenheight = draw.GetScreenSize()
    local widthcenter, heightcenter = screenwidth // 2, screenheight // 2

    draw.SetFont( 21 )
    draw.Color( 255, 255, 255, 255 )

    for item_name, group in pairs( esp ) do
        for networkindex, entity in pairs( group ) do
            if entity:IsDormant() or not entity:IsValid() then
                group[networkindex] = nil
                goto done
            end
            local origin, w2s
            origin = entity:GetAbsOrigin()
            w2s = client.WorldToScreen( origin )
            if w2s then
                draw.Text( w2s[1], w2s[2], item_name )
            end
        end
        ::done::
    end

    local spellbooks = entities.FindByClass( 'CTFSpellBook' )
    for networkindex, entity in pairs( spellbooks ) do
        if entity:GetPropEntity( "m_hOwner" ) == entities.GetLocalPlayer() then
            local spellindex, spellcharges, time_before_use_spell
            spellindex = entity:GetPropInt( "m_iSelectedSpellIndex" )
            spellcharges = entity:GetPropInt( "m_iSpellCharges" )
            time_before_use_spell = entity:GetPropFloat( "m_flTimeNextSpell" ) - globals.CurTime()
            if spellindex ~= -1 and spellcharges >= 1 then
                local spellname = spell_e[spellindex]
                local w, h = widthcenter - (draw.GetTextSize( spellname ) // 2), heightcenter + 50
                draw.Text( w, h, spellname )
                draw.Text( w, h + 20, spellcharges .. " charges left" )
                if time_before_use_spell > 0 then
                    draw.Text( w, h + 50, "Wait " .. round( time_before_use_spell, 2 ) .. " before using spell" )
                end
            end
            goto done
        end
        ::done::
    end

end )
