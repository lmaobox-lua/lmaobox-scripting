--[[
    author: pred#2448

    for LMAOBOX.net.
]] local font_verdana = draw.CreateFont( "verdana", 14, 510 )
local screen_x, screen_y = draw.GetScreenSize()
local logs = {}

local function handle_events( ev )
    if ev:GetName() ~= "player_hurt" then
        return
    end
    local localplayer = entities.GetLocalPlayer()
    local victim_entity = entities.GetByUserID( ev:GetInt( "userid" ) )
    local attacker_entity = entities.GetByUserID( ev:GetInt( "attacker" ) )
    local victim_remains = ev:GetInt( "health" )
    local vitcim_dmg = ev:GetInt( "damageamount" )
    local vitcim_ping = entities.GetPlayerResources():GetPropDataTableInt( "m_iPing" )[victim_entity:GetIndex()]
    local is_crit = ev:GetString( "crit" )
    local is_minicrit = ev:GetString( "minicrit" )
    if attacker_entity ~= localplayer then
        return
    end
    local crit_flag = is_crit and "C" or ""
    local mcrit_flag = is_minicrit and "M" or ""
    local flag = crit_flag .. mcrit_flag
    print( string.format( "[LMAOBOX] Hit %s for %s damage (%s health remaining) (flags: %s) (ping: %s)",
        victim_entity:GetName(), vitcim_dmg, victim_remains, flag, vitcim_ping ) )
    table.insert( logs, {
        victim = victim_entity:GetName(),
        victim_ping = vitcim_ping,
        damage = vitcim_dmg,
        health = victim_remains,
        flag = flag,
        x = -50,
        alpha = 0,
        delay = globals.RealTime() + 5
     } )
end

local function round( num, numDecimalPlaces )
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor( num * mult + 0.5 ) / mult
end

local function paint_logs()
    draw.SetFont( font_verdana )
    for i, v in pairs( logs ) do
        local victim = v.victim
        local ping = v.victim_ping
        local damage = tostring( v.damage )
        local health = tostring( v.health )
        local flag = v.flag
        local x = math.floor( v.x )
        local alpha = math.floor( v.alpha )
        local str = string.format( "Hit %s for %s damage (%s health remaining) (flags: %s) (ping: %s)", victim, damage,
            health, flag, ping )
        local text_x, text_y = draw.GetTextSize( str )
        draw.Color( 255, 255, 255, alpha )
        print("x : " .. math.floor( screen_x / 2 - math.floor( text_x / 2 ) + x),"y: " .. math.floor( screen_y / 1.5 + 16 * i ))
        draw.Text(math.floor( screen_x / 2 - math.floor( text_x / 2 ) + x), math.floor( screen_y / 1.5 + 16 * i ), str)
    end
end

local function animation()
    for i, v in pairs( logs ) do
        if v.delay > globals.RealTime() then
            -- move in
            v.alpha = math.min( v.alpha + globals.FrameTime() * 450, 255 )
            v.x = math.min( v.x + globals.FrameTime() * 170, 0 )
        else
            -- move out
            v.alpha = math.min( v.alpha - globals.FrameTime() * 450, 255 )
            v.x = math.min( v.x + globals.FrameTime() * 170, 50 )
            if v.alpha <= 0 then
                table.remove( logs, i )
            end
        end
    end
end
local function draw_cb()
    paint_logs()
    animation()
end

callbacks.Register( "FireGameEvent", "hitlog_event", handle_events )
callbacks.Register( "Draw", "hitlog_draw", draw_cb )
