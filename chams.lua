-- for proc in io.popen(string.format([[code "%s"]], os.getenv('APPDATA'))):lines() do print(proc) end
UnloadScript( GetScriptName() )

-- @param : interval (seconds, whatever..)
local setTimeout = function( interval, has_time )
    local id = 'Draw'
    local unique, time = table.concat( { id, engine.RandomInt( 0, 0x7FFF ) }, '_callback_' ), globals.RealTime() + interval
    callbacks.Register( id, unique, function()
        if (globals.RealTime() >= time) then
            has_time()
            callbacks.Unregister( id, unique )
        end
    end )
end
local setInterval = function( interval, has_time )
    local id = 'Draw'
    local unique, time = table.concat( { id, engine.RandomInt( 0, 0x7FFF ) }, '_callback_' ), globals.RealTime() + interval
    callbacks.Register( id, unique, function()
        local now = globals.RealTime()
        if (now >= time) then
            has_time()
            time = now + interval
        end
    end )
end

local path = string.format( [[C:/Users/%s/Desktop/%s]], os.getenv( 'USERNAME' ), 'lbox_debug.log' )
--[[
print(path)
local buf, status = io.open( path, "a+" )
if status then
    io.close(io.output(path))
    print("Reload Script")
    UnloadScript(GetScriptName())
end

setInterval( 0.5, function()
    io.close(buf)
    UnloadScript(GetScriptName())
end )]]
local custom_materials = {
    [0] = { 'mat1', 'mat2', 'mat3', 'mat4' }, -- material name (has to be lowercase and unique)
    [1] = [["VertexLitGeneric" {
        $basetexture "vgui/white_additive"
        $bumpmap "vgui/white_additive"
        $color2 "[10 1 5]" 
        $selfillum "1"
        $selfIllumFresnel "1"
        $selfIllumFresnelMinMaxExp "[0 0.18 0.1]"
        $selfillumtint "[0.3 0.001 0.1]"
        }]],
    [2] = [["VertexLitGeneric" {
         $basetexture "models/player/shared/ice_player"
         $bumpmap "models/player/shared/shared_normal"
         $phong "1"
         $phongexponent "10"
         $phongboost "1"
         $phongfresnelranges "[0 0 0]"
         $basemapalphaphongmask "1"
         $phongwarptexture "models/player/shared/ice_player_warp"
        }]],
 }

-- purpose: if material existed then reuse it, otherwise create a new material
for i = 1, #custom_materials do
    local name, material, vmt = custom_materials[0][i], materials.Find( custom_materials[0][i] ), custom_materials[i]
    -- overwrite valve material type configuration with Material class
    custom_materials[i] = type( material ) == 'userdata' and material or materials.Create( name, vmt )
end

-- test for duplicate, lmao
local result = {}
materials.Enumerate( function( material )
    local name = material:GetName()
    if name:find( 'mat(%d+)' ) then result[name] = (result[name] or 0) + 1 end
end )
printLuaTable( result )

local guicolor_to_rgba = function( path )
    local ref = gui.GetValue( path )
    -- LuaFormatter off
    local rgba =
            (ref == 255 and string.find( path, "Blue Team" )) and { 153, 204, 255, 255 } 
        or  (ref == 255 and string.find( path, "Red Team" )) and { 255, 64, 64, 255 } 
        or   ref == -1 and { 255, 255, 255, 255 } 
        or { ref & 0xFF, ref >> 24 & 0xFF, ref >> 16 & 0xFF, ref >> 8 & 0xFF }
    return rgba
    -- LuaFormatter on
end

local red, blue
callbacks.Register( 'Draw', tostring( engine.RandomFloat( 0, 1000 ) ), function()
    red = guicolor_to_rgba( 'Red Team Color' )
    blue = guicolor_to_rgba( 'Blue Team Color' )
end )

callbacks.Register( 'DrawModel', tostring( engine.RandomFloat( 0, 1000 ) ), function( ctx )
    -- m_hViewModel
    local ent = ctx:GetEntity()
    local me = entities.GetLocalPlayer()

    local material = custom_materials[1]
    material:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )
    material:SetMaterialVarFlag( MATERIAL_VAR_WIREFRAME, true )
    if not me and not me:IsValid() then return end
    if not ent or ent:IsValid() ~= true then
        local model_name = ctx:GetModelName()
        -- print( model_name )
        if string.find( model_name, 'c_models' ) then 
            ctx:ForcedMaterialOverride( material ) 
            ctx:DrawExtraPass()
        end
        
        return
    end
    -- print(me:GetPropEntity( 'm_hViewModel[0]' ))
    local str = string.format( 'id: %s, name: %s, class: %s', ent:GetIndex(), ent:GetName(), ent:GetClass() )
    -- print( str )

    if ent:IsWeapon() then
        ctx:ForcedMaterialOverride( material )
    elseif ent:GetClass() == 'CDynamicProp' then
        ctx:ForcedMaterialOverride( material ) -- medibox
    elseif me:IsAlive() and ent:GetClass() == 'CTFViewModel' then
        local color = me:GetTeamNumber() == 3 and blue or red
        local r, g, b, a = table.unpack( color )
        material:ColorModulate( r, g, b )
        -- material:SetShaderParam( "$color2", Vector3( r, g, b, a ) )
        ctx:ForcedMaterialOverride( material )
    elseif ent:GetClass() == 'CTFWearable' then
        local owner = ent:GetPropEntity( 'm_hOwnerEntity' )
        if owner:IsAlive() then
            local itemDefinitionIndex = ent:GetPropInt( 'm_iItemDefinitionIndex' )
            local itemDefinition = itemschema.GetItemDefinitionByID( itemDefinitionIndex )
            print( itemDefinition:GetLoadoutSlot(), itemDefinition:GetName() )
            if (itemDefinition:GetLoadoutSlot() == LOADOUT_POSITION_MISC) then ctx:ForcedMaterialOverride( material ) end
        end
    end
    -- buf:write(str)
end )
--  for proc in io.popen(string.format([[code %q]], os.getenv('LOCALAPPDATA'))):lines() do print(proc) end

-- purpose : get pair entries length
local pairlen = function( t )
    local i, k = 0, nil
    repeat
        k = next( t, k )
        i = i + 1
    until k == nil
    return i
end
