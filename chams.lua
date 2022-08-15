local function round( x, p )
    local power = 10 ^ (p or 0)
    return (x * power + 0.5 - (x * power + 0.5) % 1) / power
end

-- disclaimer I have no idea what any of the math does
local function rgb_to_hsl( obj )
    local r = obj.r or obj[1]
    local g = obj.g or obj[2]
    local b = obj.b or obj[3]

    local R, G, B = r / 255, g / 255, b / 255
    local max, min = math.max( R, G, B ), math.min( R, G, B )
    local l, s, h

    -- Get luminance
    l = (max + min) / 2

    -- short circuit saturation and hue if it's grey to prevent divide by 0
    if max == min then
        s = 0
        h = obj.h or obj[4] or 0
        return
    end

    -- Get saturation
    if l <= 0.5 then
        s = (max - min) / (max + min)
    else
        s = (max - min) / (2 - max - min)
    end

    -- Get hue
    if max == R then
        h = (G - B) / (max - min) * 60
    elseif max == G then
        h = (2.0 + (B - R) / (max - min)) * 60
    else
        h = (4.0 + (R - G) / (max - min)) * 60
    end

    -- Make sure it goes around if it's negative (hue is a circle)
    if h ~= 360 then
        h = h % 360
    end

    return h, s, l
end

-- no clue about any of this either
local function hsl_to_rgb( obj )
    local h = obj.h or obj[1]
    local s = obj.s or obj[2]
    local l = obj.l or obj[3]

    local temp1, temp2, temp_r, temp_g, temp_b, temp_h

    -- Set the temp variables
    if l <= 0.5 then
        temp1 = l * (s + 1)
    else
        temp1 = l + s - l * s
    end

    temp2 = l * 2 - temp1

    temp_h = h / 360

    temp_r = temp_h + 1 / 3
    temp_g = temp_h
    temp_b = temp_h - 1 / 3

    -- Make sure it's between 0 and 1
    if temp_r ~= 1 then
        temp_r = temp_r % 1
    end
    if temp_g ~= 1 then
        temp_g = temp_g % 1
    end
    if temp_b ~= 1 then
        temp_b = temp_b % 1
    end

    local rgb = {}

    -- Bunch of tests
    -- Once again I haven't the foggiest what any of this does
    for _, v in pairs( { { temp_r, "r" }, { temp_g, "g" }, { temp_b, "b" } } ) do

        if v[1] * 6 < 1 then
            rgb[v[2]] = temp2 + (temp1 - temp2) * v[1] * 6
        elseif v[1] * 2 < 1 then
            rgb[v[2]] = temp1
        elseif v[1] * 3 < 2 then
            rgb[v[2]] = temp2 + (temp1 - temp2) * (2 / 3 - v[1]) * 6
        else
            rgb[v[2]] = temp2
        end

    end

    return math.floor( rgb.r * 255 ), math.floor( rgb.g * 255 ), math.floor( rgb.b * 255 )
end

----

local __custom_materials = { {
    name = 'flat',
    vmt = [[
    "UnlitGeneric"
    {
        "$basetexture"		"vgui/white_additive"
    }
    ]]
 }, {
    name = 'shaded',
    vmt = [["VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"vgui/white_additive"
        "$selfillum"						"1"
        "$selfillumfresnel"					"1"
        "$selfillumfresnelminmaxexp"		"[-0.25 1 1]"
    }
    ]]
 }, {
    name = 'brick',
    vmt = [[
    "VertexLitGeneric"
    {
        "$basetexture"					    "brick/brickwall031b"
        "$additive"						    "1"
        "$phong"						    "1"
        "$phongfresnelrangse"			    "[0 0.5 10]"
        "$envmap"						    "cubemaps/cubemap_sheen001"
        "$envmapfresnel"				    "1"
        "$selfillum"					    "1"
        "$rimlight"						    "1"
        "$rimlightboost"				    "100"
        "$envmapfresnelminmaxexp"		    "[0 1 2]"
    }]]
 }, {
    name = 'plastic',
    vmt = [[
    "VertexLitGeneric"
    {
        "$basetexture"					    "models/player/shared/ice_player"
        "$bumpmap"						    "models/player/shared/shared_normal"
        "$phong"						    "1"
        "$phongexponent"				    "10"
        "$phongboost"					    "1"
        "$phongfresnelranges"			    "[0 0 0]"
        "$basemapalphaphongmask"		    "1"
        "$phongwarptexture"				    "models/player/shared/ice_player_warp"
    }
    ]]
 }, {
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
    name = 'shiny',
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
        "$selfillumfresnelminmaxexp"		"[0.5 0.5 0]"
        "$selfillumtint"					"[0 0 0]"
        "$envmaptint"						"[0 1 0]"
    }
    ]]
 }, {
    -- $color2 25, 213, 48
    name = 'toxic',
    vmt = [[
    "VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"vgui/white_additive"
        "$color2"							"[1 100 1]"
        "$selfillum"						"1"
        "$selfIllumFresnel"					"1"
        "$selfIllumFresnelMinMaxExp"		"[0 0.18 0.1]"
        "$selfillumtint"					"[0.3 0.001 0.1]"
    }
    ]]
 } }

local _, custom_materials = {}, {}
for index, mat in ipairs( __custom_materials ) do
    custom_materials[mat.name:lower()] = mat.vmt
end

--
--- todo we need a color library!
--

local function Color( r, g, b )
    r, g, b = r / 255, g / 255, b / 255
    return Vector3( r, g, b )
end

local function unsigned_pack( ... )
    local v = { ... }
    local len, i = #v, 0
    for j = len, 1, -1 do
        i = i | math.floor( v[len - j + 1] ) << ((8 * (j - 1)) & 0xFF)
    end
    return i
end

local function unsigned_unpack( i )
    i = math.abs(i)
    local size, unsigned = math.floor( (math.log( i, 2 ) / 8) + 1 ), {}
    for j = size, 1, -1 do
        unsigned[#unsigned + 1] = i >> ((j * 8) - 8) & 0xFF
    end
    return unsigned
end

--- 

local config = {
    model = {},
    enemy = true,
    team = false,
    ignore_dead = true
 }

local ok, material_override = pcall( require, "cache_material_override" )
if type( material_override ) ~= 'table' then
    material_override = {}
end

local removals = { 'effects/imcookin', 'effects/jarate_overlay', 'effects/bleed_overlay', 'effects/stealth_overlay',
                   'effects/dodge_overlay' }

local me_team

-- todo, fix vmt table structure.
local __fontpage_size, __fontpage_iter = 0, 0
local function reload_texture_on_map_update()
    materials.Enumerate( function( mat )
        local name, group = mat:GetName(), mat:GetTextureGroupName()
        local mapname = engine.GetMapName()
        if not material_override[group] then
            material_override[group] = {}
        end

        if group == "SkyBox textures" then
            if true then
                mat:SetShaderParam( '$color', Color( 157, 71, 71 ) )
            end
        end

        if group == "World textures" then
            if true then
                mat:SetShaderParam( '$color', Color( 25, 25, 45 ) )
                mat:SetShaderParam( '$alpha', 1 )
                mat:SetMaterialVarFlag( MATERIAL_VAR_FLAT, true )
            end
        end

        if group == "Other textures" then
            local vmt = custom_materials[name]
            if vmt then
                _[name] = mat
            end

            if name == 'effects/tracer1' or name:find( 'particle/impacts' ) then
                mat:SetShaderParam( '$color', Color( 255, 150, 197 ) )
            end

            if name == '__fontpage' then
                __fontpage_size = __fontpage_size + 1
                mat:SetShaderParam( '$color', Color( 255, 255, 255 ) )
                mat:AlphaModulate( 1 )
            end
        end

        -- haven't tested thuruli. ClientEffect textures
        for i, effect in ipairs( removals ) do
            if name == effect then
                mat:SetMaterialVarFlag( MATERIAL_VAR_NO_DRAW, true )
            end
        end

    end )

    materials.Enumerate( function( mat )
        local name, group = mat:GetName(), mat:GetTextureGroupName()
        if name == '__fontpage' then
            __fontpage_iter = __fontpage_iter + 1
            if __fontpage_size - __fontpage_iter <= 2 then
                local h, s, l = rgb_to_hsl( unsigned_unpack( gui.GetValue( 'gui color' ) ) )
                l = l + .2
                local r, g, b = hsl_to_rgb( { h, s, l } )
                mat:SetShaderParam( '$color', Color( r, g, b ) ) -- Color( 158, 224, 158 ) )
                mat:AlphaModulate( 0.9 )
            end
        end
    end )
end

gui.SetValue( 'night mode color', unsigned_pack( 170, 170, 208, 255 ) )
reload_texture_on_map_update()

for name, vmt in pairs( custom_materials ) do
    if type( vmt ) ~= "userdata" then
        _[name] = materials.Create( name, vmt )
    end
end

callbacks.Register( 'DrawModel', function( ctx )
    local ent, model = ctx:GetEntity(), ctx:GetModelName():gsub( '%.[^.]+$', '' )

    if not ent then
        goto model
    end

    do
        local model, class = model:match( 'models/(.*)' ), ent:GetClass()
        -- print( model )

        -- player
        if ent:IsPlayer() then
            -- handle player condition, health level, priority logic here.
            return ctx:ForcedMaterialOverride( _['nitro'] )
        end

        -- player's wearable
        if class == "CTFWearable" or class == 'CTFPowerupBottle' then
            local player = ent:GetPropEntity( 'm_hOwnerEntity' )
            return ctx:ForcedMaterialOverride( _['nitro'] )
        end

        -- player's viewmodel
        if class == "CTFViewModel" then
            return ctx:ForcedMaterialOverride( _['shine'] )
        end

        -- player held this wepaon
        if ent:IsWeapon() and ent:GetPropEntity( 'm_hOwner' ) then
            return ctx:ForcedMaterialOverride( _['nitro'] )
        end

        -- on ground weapon
        if model:find( 'weapons/c_models/(.*)/(.*)' ) then
            return ctx:ForcedMaterialOverride( _['brick'] )
        end

        -- projectile & explosive (rocket, ...)
        if model:find( 'weapons/w_models/(.*)' ) then
            -- print(model)
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        if model:find( 'items/ammopack' ) then
            return ctx:ForcedMaterialOverride( _['shine'] )
        end

        if model:find( 'items/medkit' ) then
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        -- todo : for buildings check state (maybe the only way?) thru netprop to avoid override the buildbox
        if model:find( 'buildables/sentry' ) then
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        if model:find( 'buildables/dispenser' ) then
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        if model:find( 'buildables/teleporter' ) then
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        if model:find( 'flag/briefcase' ) then
            return ctx:ForcedMaterialOverride( _['fresnel'] )
        end

        return
    end

    ::model::

    -- player viewmodel's weapon
    if model:find( 'c_models' ) then
        ctx:ForcedMaterialOverride( _['nitro'] )
    end

end )

callbacks.Register( 'FireGameEvent', function( e )
    local name = e:GetName()
    if name == 'localplayer_respawn' or name == 'localplayer_changeteam' then
        me_team = assert( entities.GetLocalPlayer():GetTeamNumber() )
    end
    if name == 'game_newmap' then
        callbacks.Register( 'Draw', function()
            if clientstate.GetClientSignonState() == 6 then
                gui.SetValue( 'night mode color', unsigned_pack( 170, 170, 208, 255 ) )
                reload_texture_on_map_update()
                callbacks.Unregister( 'Draw', '' )
            end
        end )
    end
end )

local function cache()
    package.loaded["cache_material_override"] = material_override
end

callbacks.Register( 'Unload', cache )
