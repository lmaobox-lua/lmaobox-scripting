-- LuaFormatter off 
local cur_script_name = GetScriptName():match( '[^\\/]+$' ) .. ' - '
local ok, json = pcall( require, 'dkjson' ) ; assert( ok, cur_script_name .. '(missing lib) get dkjson.lua: "http://dkolf.de/src/dkjson-lua.fsl/home" ' )
-- local ok, color = pcall( require, 'color' ) ; assert( ok, cur_script_name .. '(missing lib) get color.lua: ? ' )
-- LuaFormatter on

local custom_materials_config = {
    ['flat'] = [[
    "UnlitGeneric"
    {
        "$basetexture"		"vgui/white_additive"
    }
    ]],
    ['shaded'] = [[
    "VertexLitGeneric"
    {
        "$basetexture"						"vgui/white_additive"
        "$bumpmap"							"vgui/white_additive"
        "$selfillum"						"1"
        "$selfillumfresnel"					"1"
        "$selfillumfresnelminmaxexp"		"[-0.25 1 1]"
    }
    ]],
    ['brick'] = [[
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
    }]],
    ['plastic'] = [[
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
    ]],
    ['nitro'] = [[
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
    ]],
    ['shine'] = [[
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
    ]],
    ['shiny'] = [[
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
    ]],
    ['fresnel'] = [[
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
    ]],
    ['toxic'] = [[
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
 }

local screen_space_effect = { 'effects/imcookin', 'effects/jarate_overlay', 'effects/bleed_overlay',
                              'effects/stealth_overlay', 'effects/dodge_overlay', 'effects/water_wrap' }

local function Color( r, g, b )
    r, g, b = r / 255, g / 255, b / 255
    return Vector3( r, g, b )
end

local function fetch( name, fallback )
    local ok, val = pcall( require, name )
    if ok and type( val ) == 'table' then
        return val
    end
    return fallback
end

local m = fetch( 'chams_custom_materials', {} )
local texture_instance = fetch( 'chams_texture_instance', {
    ['World textures'] = {},
    ['SkyBox textures'] = {},
    ['Other textures'] = {},
    ['ClientEffect textures'] = {},
    ['Model textures'] = {}
 } )

local function get_texture_list()
    materials.Enumerate( function( material )
        local name, group = material:GetName(), material:GetTextureGroupName()
        if not texture_instance[group] then
            texture_instance[group] = {}
        end
        -- todo : texture whitelisting.
        texture_instance[group][name] = material
    end )
end

local function modify_world_texture( override )
    for name, material in pairs( texture_instance['World textures'] ) do
        material:SetMaterialVarFlag( MATERIAL_VAR_FLAT, override and true or false )
        material:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )
        material:AlphaModulate( override and 0.65 or 1 )
        material:SetShaderParam( '$color', override and Color( 25, 25, 45 ) or Vector3( 1, 1, 1 ) )
    end
end

local function modify_sky_texture( override )
    for name, material in pairs( texture_instance['SkyBox textures'] ) do
        material:SetShaderParam( '$color', Color( 157, 71, 71 ) )
    end
end

local function modify_screen_space_texture( override )
    for name, material in pairs( texture_instance['Other textures'] ) do

    end
end

local get_texture_list_and_override_texture = function()
    get_texture_list()
    modify_world_texture( true )
    modify_sky_texture( true )
    modify_screen_space_texture( true )
end
get_texture_list_and_override_texture()

for name, vmt in pairs( custom_materials_config ) do
    m[name] = m[name] or texture_instance['Other textures'][name]
    if not m[name] then
        m[name] = materials.Create( name, vmt )
    end
end

callbacks.Register( 'Unload', function()
    get_texture_list()
    modify_world_texture()
    modify_sky_texture()
    modify_screen_space_texture()
    package.loaded['chams_custom_materials'] = m
    package.loaded['chams_texture_instance'] = texture_instance
end )

local me_team_number = 0

local fire_game_event = {
    ['localplayer_respawn'] = function()
        me_team_number = entities.GetLocalPlayer():GetTeamNumber()
    end,
    ['game_newmap'] = function()
        callbacks.Register( 'Draw', function()
            if clientstate.GetClientSignonState() == 6 then
                get_texture_list_and_override_texture()
                callbacks.Unregister( 'Draw', '' )
            end
        end )
    end
 }
fire_game_event['localplayer_changeteam'] = fire_game_event['localplayer_respawn']

callbacks.Register( 'FireGameEvent', function( e )
    local fn = fire_game_event[e:GetName()]
    if fn then
        fn()
    end
end )
fire_game_event['localplayer_respawn']()

local config = {}
setmetatable( config, {
    __call = function( self, ... )
        local args = { ... }
        for i = 1, #args do
            if not rawget( self, args[i] ) then
                self[tostring( args[i] )] = {}
            end
        end
    end,
    __newindex = function( t, k, v )
        if type( v ) == 'table' then
            rawset( v, 'material_var_flag', -1 )
            rawset( v, 'color_modulate', -1 )
            rawset( v, 'material_override', false )
            rawset( t, k, v )
        end
    end,
    __index = {}
 } )

 -- TODO : load config... bruh im tired

-- LuaFormatter off 
config( 'player_opponent', 
        'player_teammate', 
        'building_opponent', 
        'building_teammate', 
        'player_opponent_held_weapon',
        'player_teammate_held_weapon',
        'localplayer',
        'building_localplayer',
        -- also used when localplayer is dead and spectate other player
        'localplayer_viewmodel',
        'localplayer_held_weapon',
        'medkit',
        'ammopack' )
-- LuaFormatter on

callbacks.Register( 'DrawModel', function( ctx )
    local ent, model = ctx:GetEntity(), ctx:GetModelName()

    if not ent then
        goto no_entity
    end

    do
        local class = ent:GetClass()

        --- first person viewmodel
        if class == "CTFViewModel" then
            return ctx:ForcedMaterialOverride( m['shine'] )
        end

        --- player's weapon
        if ent:IsWeapon() and ent:GetPropEntity( 'm_hOwner' ) then
            return ctx:ForcedMaterialOverride( m['shine'] )
        end

        if model:find( 'items/ammopack' ) then
            return ctx:ForcedMaterialOverride( m['shine'] )
        end

        if model:find( 'items/medkit' ) then
            return ctx:ForcedMaterialOverride( m['fresnel'] )
        end

    end

    ::no_entity::
    if model:find( 'c_models', 1, true ) then
        return ctx:ForcedMaterialOverride( m['nitro'] )
    end

    -- if class = 'x' 
    -- material, color = hOwner is valid and team color or default 
    --- TODO : Add 'relative' team based mode chams.

end )
