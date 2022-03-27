--[[
  author:pred#2448
  For LMAOBOX.net
]] local screen_x, screen_y = draw.GetScreenSize()
local font_calibri = draw.CreateFont( "calibri", 20, 20 )

local function anim( speed )
    return math.sin( math.abs( -math.pi + (globals.CurTime() * speed) % (math.pi * 2) ) )
end

local function paint_spy()
    local players = entities.FindByClass( "CTFPlayer" )
    local localplayer = entities.GetLocalPlayer()

    for i, v in pairs( players ) do
        repeat
            local team = v:GetPropInt( "m_iTeamNum" )
            if v == localplayer or team == localplayer:GetPropInt( "m_iTeamNum" ) then
                break
            end
            local player_class = v:GetPropInt( "m_iClass" )

            if player_class ~= 8 then
                break
            end

            local spy_origin = v:GetAbsOrigin()
            local local_origin = localplayer:GetAbsOrigin()
            local spy_distance = vector.Distance( spy_origin, local_origin )

            if spy_distance > 350 then
                break
            end

            draw.SetFont( font_calibri )
            local str = string.format( "A spy is nearby! - %s[%s]", v:GetName(), math.floor( spy_distance ) )
            local text_x, text_y = draw.GetTextSize( str )
            draw.Color( 255, 0, 0, math.floor( 255 * anim( 3.5 ) ) )
            draw.TextShadow( screen_x / 2 - math.floor( text_x / 2 ), math.floor( screen_y / 1.9 ) + 16 * i, str )
        until true
    end
end
callbacks.Register( "Draw", "unique_draw_test", paint_spy )
