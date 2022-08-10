local material = {}
local custom_materials = { {
    name = 'nitro',
    vmt = [[
        "VertexLitGeneric"
        {
            "$basetexture"						"vgui/white_additive"
            "$bumpmap"							"models/player/shared/shared_normal"
            "$envmap"							"skybox/sky_dustbowl_01"
            "$envmapfresnel"					"1"
            "$phong"							"1"
            "$phongfresnelranges"				"[0 0.05 0.1]"
            "$selfillum"						"1"
            "$selfillumfresnel"					"1"
            "$selfillumfresnelminmaxexp"		"[0.4999 0.5 0]"
            "$envmaptint"						"[ 1 0.05 0.05 ]"
            "$selfillumtint"					"[ 0.03 0.03 0.03 ]"
        }
        ]]
 }, {
    name = 'shine',
    vmt = [[
    "VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"vgui/white_additive"
        "$color2"							"[25 0.5 0.5]"
        "$envmap"							"cubemaps/cubemap_sheen002"
        "$phong"							"1"
        "$selfillum"						"1"
        "$selfillumfresnel"					"1"
        "$selfillumfresnelminmaxexp"		"[0.1 0.2 0.3]"
        "$selfillumtint"					"[0 0.3 0.6]"
    }
    ]]
 }, {
    name = 'shine2',
    vmt = [[
    "VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"vgui/white_additive"
        "$envmap"							"cubemaps/cubemap_sheen001"
        "$phong"							"1"
        "$selfillum"						"1"
        "$selfillumfresnel"					"1"
        "$selfillumfresnelminmaxexp"		"[-0.25 1 1]"
    }
    ]]
 }, {
    name = 'fresnel',
    vmt = [["VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"models/player/shared/shared_normal"
        "$envmap"							"skybox/sky_dustbowl_01"
        "$envmapfresnel"					"1"
        "$phong"							"1"
        "$phongfresnelranges"				"[0 0.05 0.1]"
        "$selfillum"						"1"
        "$selfillumfresnel"					"1"
        "$selfillumfresnelminmaxexp"		"[0.5 0.5 0]"
        "$selfillumtint"					"[0 0 0]"
        "$envmaptint"						"[0 1 0]"
    }
    ]]
 } }

local config = {
    model = {},
    enemy = true,
    team = false,
    ignore_dead = true
 }

do
    for index, mat in ipairs( custom_materials ) do
        local name = mat.name:lower()
        local found_material = materials.Find( name )
        material[name] = found_material or materials.Create( name, mat.vmt )
    end
end

local function Color( r, g, b )
    r, g, b = r / 255, g / 255, b / 255
    return Vector3( r, g, b )
end

callbacks.Register( 'DrawModel', function( ctx )
    local ent, model = ctx:GetEntity(), ctx:GetModelName():gsub( '%.[^.]+$', '' )

    if not ent then
        goto model
    end

    do
        local model = model:match( 'models/(.*)' )
        -- print( model )

        -- player
        if ent:IsPlayer() then
            return ctx:ForcedMaterialOverride( material['shine2'] )
        end

        -- player's viewmodel
        if ent:GetClass() == "CTFViewModel" then
            return ctx:ForcedMaterialOverride( material['shine'] )
        end

        -- player held this wepaon
        if ent:IsWeapon() and ent:GetPropEntity( 'm_hOwner' ) then
            return ctx:ForcedMaterialOverride( material['nitro'] )
        end

        -- on ground weapon
        if model:find( 'weapons/c_models/(.*)/(.*)' ) then
            return ctx:ForcedMaterialOverride( material['shine2'] )
        end

        -- projectile & explosive (rocket, ...)
        if model:find( 'weapons/w_models/(.*)' ) then
            -- print(model)
            return ctx:ForcedMaterialOverride( material['fresnel'] )
        end

        if model:find( 'items/ammopack' ) then
            return ctx:ForcedMaterialOverride( material['shine'] )
        end

        if model:find( 'items/medkit' ) then
            return ctx:ForcedMaterialOverride( material['fresnel'] )
        end

        return
    end

    ::model::

    -- viewmodel
    if model:find( 'c_models' ) then
        ctx:ForcedMaterialOverride( material['nitro'] )
    end

end )

do
    local textureGroup = {}
    materials.Enumerate( function( mat )
        if not textureGroup[mat:GetTextureGroupName()] then
            textureGroup[mat:GetTextureGroupName()] = 0
        end
        textureGroup[mat:GetTextureGroupName()] = textureGroup[mat:GetTextureGroupName()] + 1

        if mat:GetTextureGroupName() == "SkyBox textures" then
            mat:SetShaderParam( '$color', Color( 157, 71, 71 ) )
        end

        if mat:GetTextureGroupName() == "World textures" then
            mat:SetShaderParam( '$color', Color( 25, 25, 45 ) )
            mat:SetShaderParam( '$alpha', 1 )
            mat:SetMaterialVarFlag( MATERIAL_VAR_FLAT, true )
        end

    end )
    printLuaTable( textureGroup )
end

