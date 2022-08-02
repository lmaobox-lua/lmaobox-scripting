local materialList = {}
materials.Enumerate( function( mat )
    local group, name = mat:GetTextureGroupName(), mat:GetName()
    if not materialList[group] then
        materialList[group] = {}
    end
    table.insert( materialList[group], name )

    if string.find( group, 'Model' ) then
        if string.find( name, 'door_slide' ) then
            mat:SetMaterialVarFlag( MATERIAL_VAR_WIREFRAME, false )
        end
        -- mat:AlphaModulate( 1 );
        -- mat:ColorModulate( 158, 193, 207 )
        -- mat:SetMaterialVarFlag( MATERIAL_VAR_IGNOREZ, false )
    end

    if string.find( group, 'SkyBox' ) then
        mat:ColorModulate( 0, 0, 0 )
        -- netprop m_skybox3d : You can do it easier by setting m_skybox3d.area which is a netvar to 255
    end
end )

local doors = {
    'door_slide',
    'main_entrance_door'
}
materials.Enumerate( function(mat) 
    for i, name in ipairs(doors) do
        if string.find( mat:GetName(), name ) then
            print(mat:GetName())
            mat:SetMaterialVarFlag( MATERIAL_VAR_WIREFRAME, true )
        end
    end
end)

callbacks.Register( 'SendStringCmd', function( cmd )
    local i, j = cmd:Get():find( 'mat' )
    if i == 1 and j == #cmd:Get() then
        cmd:Set( '' )
        local mapname = engine.GetMapName()
        local filename = engine.GetGameDir() .. '\\..\\materialdump.lua'
        local file = io.open( filename, 'w' )

        for key, texture_group in pairs( materialList ) do
            printc( 253, 253, 151, 255, key )
            file:write( string.format( 'local %s = {\n', key:gsub( '%s', '_' ) ) )
            for i, texture_name in ipairs( texture_group ) do
                printc( 158, 224, 158, 255, '    ' .. texture_name )
                file:write( string.format( '    %q,\n', texture_name ) )
                if i == #texture_group then
                    file:write( '}\n' )
                end
            end
        end

        file:flush()
        file:close()
        os.execute( 'start /B explorer ' .. filename )
    end
end )

local customColor = (function( name )
    return materials.Find( name ) or materials.Create( name, string.format( 
        [["VertexLitGeneric"
        {
            $basetexture "vgui/white_additive"
            $bumpmap "vgui/white_additive"
            $color2 "[3 2 111]" 
            $selfillum "1"
            $selfIllumFresnel "1"
            $selfIllumFresnelMinMaxExp "[0 0.18 0.1]"
            $selfillumtint "[0.3 0.001 0.1]"
        }
        ]], name ) )
end)( 'dawdawdwa' )

--[[
callbacks.Register( 'DrawModel', function( ctx )
    local name = ctx:GetModelName()

    if string.find( name, 'models/props_' ) then
        customColor:SetShaderParam( "$color2", "[1 1 1]" )
        ctx:ForcedMaterialOverride( customColor )
    end

end )]]
