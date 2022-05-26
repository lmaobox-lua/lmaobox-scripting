local myfont = draw.CreateFont( "Verdana", 16, 800 )

local did_hit = function( trace )
    return (trace.fraction < 1.0) or trace.startsolid == true or trace.allsolid == true -- Returns true if there was any kind of impact at all
end

local is_visible = function( source, destination )
    local trace = engine.TraceLine( source, destination, (MASK_SHOT | CONTENTS_GRATE) )
    local result = not did_hit( trace )
    return trace, result
end

callbacks.Register( "Draw", function()
    local me = entities.GetLocalPlayer();
    local source = me:GetAbsOrigin()
    for i, p in ipairs( entities.FindByClass( 'CTFPlayer' ) ) do
        if not p:IsDormant() and p:IsAlive() then
            local abs = p:GetAbsOrigin()
            local bbox_min, bbox_max = table.unpack( p:HitboxSurroundingBox() )
            local trace, result = is_visible( source, abs )
            local trace1, result1 = is_visible( source, bbox_min )
            local trace2, result2 = is_visible( source, bbox_max )
            if trace1.fraction > 0.97 or trace2.fraction > 0.97 then
                local screenPos = client.WorldToScreen( p:GetAbsOrigin() )
                local screenPos1, screenPos2 = client.WorldToScreen( bbox_min ), client.WorldToScreen( bbox_max )
                if screenPos ~= nil and p ~= me then
                    draw.SetFont( myfont )
                    draw.Color( 255, 255, 255, 255 )
                    draw.Text( screenPos[1], screenPos[2], "o" )
                    draw.Text( screenPos1[1], screenPos1[2], "-" )
                    draw.Text( screenPos2[1], screenPos2[2], "+" )
                end
            end
        end
    end
end )

UnloadScript( GetScriptName() )