-- #region WIP timeout fn
callbacks.Unregister( 'Draw', 'settimeout_timer' )
local queueFN = {}
local settimeout = function( milisecond, fn, loop_forever )
    local expire = (milisecond / 1000) + globals.RealTime()
    -- print( 'index: ' .. #_queue+1 .. ' registered, run at: ' .. expire )
    if (loop_forever) then
        table.insert( queueFN, { expire, fn, milisecond, true } )
    else
        table.insert( queueFN, { expire, fn, 0, false } )
    end
end

local settimeout_timer = function()
    local now = globals.RealTime()
    for k, v in ipairs( queueFN ) do
        local expire, fn, milisecond, loop_forever = v[1], v[2], v[3], v[4]
        if not (expire > now) then
            -- print( 'index: ' .. k .. ' expired' .. ' at: ' .. now )
            fn()
            table.remove( queueFN, k )
            if (loop_forever == true) then
                settimeout( milisecond, fn, true )
            end
        end
    end
end
callbacks.Register( 'Draw', 'settimeout_timer', settimeout_timer )
-- #endregion WIP timeout fn

local hex_to_dec = function( hex )
    return tonumber( '0x' .. hex:gsub( "^#", "" ):gsub( "^0x", "" ) )
end

local hex2rgb = function( hex )
    local r, g, b
    r, g, b = hex_to_dec( hex:sub( 1, 2 ) ), hex_to_dec( hex:sub( 3, 4 ) ), hex_to_dec( hex:sub( 5, 6 ) )
    return { r, g, b }
end

local dec2rgb = function( dec )
    local hex = ("%06x"):format( dec )
    return hex2rgb( hex )
end

local gen_chams = function( rgb, name )
    local r, g, b = table.unpack( rgb )
    local kv = string.format( [["VertexLitGeneric"
    {
      $basetexture "vgui/white_additive"
      $bumpmap "vgui/white_additive"
      $selfillum "1"
      $color "[%02d %02d %02d]"
      $selfIllumFresnel "1"
      $selfIllumFresnelMinMaxExp "[0 0.18 0.1]"
      $selfillumtint "[0.3 0.001 0.1]"
    }
    ]], r, g, b )
    local mat = materials.Create( name, kv )
    mat:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )
    return mat
end

local blu_color, red_color = { 255, 255, 255 }, { 255, 255, 255 }
local material_team_b, material_team_r = gen_chams( blu_color, "bluchams" ), gen_chams( red_color, "redchams" )

local kv = [["VertexLitGeneric"
{
  $basetexture "vgui/white_additive"
  $bumpmap "vgui/white_additive"
  $color2 "[1 100 1]"
  $selfillum "1"
  $selfIllumFresnel "1"
  $selfIllumFresnelMinMaxExp "[0 0.18 0.1]"
  $selfillumtint "[0.3 0.001 0.1]"
}
]]

local BasedMaterial = materials.Create( "BasedMaterial", kv )
BasedMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )

callbacks.Unregister( "DrawModel", "draw_model_override" )

local function draw_model_override( drawModelContext )
    local entity = drawModelContext:GetEntity()
    if not (entity and entity:IsValid()) then
        return
    end

    if not (entity:IsPlayer() or entity:IsWeapon()) then
        return
    end

    local resolve_team = entity:GetTeamNumber() -- or entity:GetPropEntity( "m_hOwner" ):GetTeamNumber()
    local s = (resolve_team == 3 and material_team_b) or (resolve_team == 2 and material_team_r)
    drawModelContext:ForcedMaterialOverride( s )
end

gen_chams( blu_color, "bluchams" )
gen_chams( red_color, "redchams" )

local ref 
settimeout( 0, function()
    ref = ui.GetValue("lmaobox_ui_path")
end, true ) -- true : loop forever , false : run once

callbacks.Register( "DrawModel", "draw_model_override", draw_model_override )



local BasedMaterial = materials.Create( "BasedMaterial", em )
local TeamMaterial = materials.Create( "TeamMaterial", tm )
BasedMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )
TeamMaterial:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )

local function onDrawModel( drawModelContext )
    local entity = drawModelContext:GetEntity()
    if not (entity and entity:IsValid() and entity:GetClass() == "CTFPlayer") then
        return
    end   
    local resolve_team = entity:GetTeamNumber() or 
    entity:GetPropEntity( "m_hOwner" ):GetTeamNumber() -- 
        drawModelContext:ForcedMaterialOverride( TeamMaterial ) --thanks for these two lines jesse
end
