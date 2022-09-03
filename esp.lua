local font = draw.CreateFont( 'Tahoma', 13, 400, FONTFLAG_DROPSHADOW )
callbacks.Register( 'Draw', function()
    draw.SetFont( font )
    for i = 0, 1 << 11 do
        local ent = entities.GetByIndex( i )
        if ent then
            local name, world_pos, vec2, x, y, tx, ty, wx
            name = ent:GetClass()
            world_pos = ent:GetAbsOrigin()
            vec2 = client.WorldToScreen( world_pos )
            if vec2 then
                x, y = vec2[1], vec2[2]
                tx, ty = draw.GetTextSize( name )
                wx = x - math.min( tx, 10 )
                draw.Color( 158, 193, 207, 100 )
                draw.FilledRect( wx, y, x + tx, y + ty )
                draw.Color( 253, 253, 151, 200 )
                draw.FilledRect( wx, y, wx + 4, y + ty )
                draw.Color( 255, 255, 255, 255 )
                draw.Text( (wx + x + 4) // 2, y, name )
            end
        end
    end
end )
