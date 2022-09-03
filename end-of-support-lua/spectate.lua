local spectate_mode = {
    [0] = 'none', -- not in spectator mode
    'death cam', -- special mode for death cam animation
    'freeze cam', -- zooms to a target, and freeze-frames on them
    'fixed', -- view from a fixed camera position
    '1st person', -- follow a player in first person view
    '3rd person', -- follow a player in third person view
    'spy cam', -- PASSTIME point of interest - game objective, big fight, anything interesting; added in the middle of the enum due to tons of hard-coded "<ROAMING" enum compares 
    'flight' -- free roaming
 }

local team_name = {
    [0] = 'unassigned',
    'spectator',
    'red',
    'blue'
 }

local team_color = {
    [0] = { 255, 255, 255, 255 },
    { 204, 204, 204, 255 },
    { 255, 64, 64, 255 },
    { 153, 204, 255, 255 }
 }

local f, l = 200, 200 * 4
local font = draw.CreateFont( 'Tahoma', 13, 400, FONTFLAG_DROPSHADOW )

callbacks.Register( 'Draw', function()
    draw.SetFont( font )
    local x, y = draw.GetScreenSize()
    x, y = x // 2, y // 2

    local players = entities.FindByClass( 'CTFPlayer' )
    -- players[client.GetLocalPlayerIndex()] = nil

    for index, player in pairs( players ) do
        if player:IsAlive() or player:IsDormant() then
            goto em
        end
        local observer_mode = player:GetPropInt( 'm_iObserverMode' )
        local observer_target = player:GetPropEntity( 'm_hObserverTarget' )
        local team = player:GetTeamNumber()
        local info = string.format( '%s (%s)', player:GetName(), spectate_mode[observer_mode] )
        local tx, ty, txx = draw.GetTextSize( info .. ': ' .. observer_target:GetName() )
        y = y + ty + 4
        txx = (x + tx) // 2
        tx = (x + tx) // 2
        draw.Color( table.unpack( team_color[team] ) )
        draw.Text( tx, y, info )
        draw.Color( table.unpack( team_color[observer_target:GetTeamNumber()] ) )
        draw.Text( txx, y, ': ' .. observer_target:GetName() )
        ::em::
    end
end )

if false then
    draw.SetFont( font )
    draw.Color( 255, 255, 255, 50 )
    draw.FilledRect( l - 40, l - 40, l + 40, l + 40 )
    draw.Color( 35, 35, 35, 200 )
    draw.FilledRect( f, f, l, l )
    draw.FilledRect( f, f, l, f + 25 )
    draw.Color( 75, 125, 125, 200 )
    draw.FilledRect( f, f, l, f + 23 )
    draw.Color( 96, 55, 255, 200 )
    draw.FilledRect( f, f, l, f + 21 )
    draw.Color( 255, 255, 255, 255 )
    draw.TextShadow( f, f, 'LBY' )
    draw.Text( l - 220, f, os.date( '%A, %c' ) )
    return
end

-- 21, 23 looks good, 25 is underline, 27, 29, 31, 35 is esp small font, 40 could be LBY font
-- vgui_spew_fonts 
-- HFONT ClientScheme.res ? fontname tall
-- '', 14, 400
-- Arial, 11, 900
-- Tahoma, 12, 500 
-- Tahoma, 13, 400, FONTFLAG_DROPSHADOW
-- Tahoma, 16, 700
-- Tahoma, 16, 400
-- Small Fonts, 8, 400
-- 'Small Fonts', 14, 400
-- Code Pro Fonts
-- 200, 200, 200, 255
-- 200, 0, 0, 255
-- 208, 143, 40, 255 
-- 0, 100, 0, 255
-- FONTFLAG_ROTARY -> strike middle of word
