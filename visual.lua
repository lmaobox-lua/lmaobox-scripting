local round_number = function( num )
    num = (num - math.floor( num ) > 0.5) and math.ceil( num ) or math.floor( num )
    return num
end

local initFont = (function( path, name, height, weight )
    return (draw.AddFontResource( path ) ~= nil and draw.CreateFont( name, height, weight ))
end)

local roundVec = function( vec, numDecimalPlaces )
    local x, y, z = vec:Unpack()
    if not (numDecimalPlaces) then
        return math.floor( x ), math.floor( y ), math.floor( z )
    else
        local mult = 10 ^ numDecimalPlaces
        return math.floor( x * mult + 0.5 ) / mult, math.floor( y * mult + 0.5 ) / mult,
            math.floor( z * mult + 0.5 ) / mult
    end
end

-- draw helper
local dh = { width, height }
function dh:init( x, y )
    dh.width, dh.height = x, y
end
function dh:next_text( text, offset, fn )
    fn = fn or draw.Text
    local x, y = 0, 0
    if (type( offset ) == 'table') then
        x, y = table.unpack( offset )
    end
    fn( self.width + x, self.height + y, text )
    self.height = self.height + select( 2, draw.GetTextSize( text ) )
end
--

local TFTeamName = {}

local to_team_name = (function( team_number )
    return (team_number == 3 and "Blu") or (team_number == 2 and "Red") or (team_number == 1 and "Spectator") or
               (team_number == 0 and "Unassigned")
end)

local myfont = draw.CreateFont( "Verdana", 16, 800 )
doDraw = function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        return
    end

    local me = entities.GetLocalPlayer()
    local players = entities.FindByClass( "CTFPlayer" )
    for i, p in ipairs( players ) do
        if p:IsAlive() and not p:IsDormant() and not (p == me) then
        --if p:IsValid() and not p:IsDormant() and not (p == me) then
            local screenPos = client.WorldToScreen( p:GetAbsOrigin() )
            if screenPos ~= nil then
                draw.SetFont( myfont )
                draw.Color( 255, 255, 255, 255 )
                dh:init( screenPos[1], screenPos[2] )
                dh:next_text( p:GetName() )
                dh:next_text( table.concat( { "index: " .. p:GetIndex(), "team: " .. p:GetTeamNumber() }, ', ' ) )
                local m_vecOrigin = table.concat( table.pack( roundVec( p:GetAbsOrigin() ) ), ', ' )
                dh:next_text( m_vecOrigin )
                dh:next_text( table.concat( table.pack( roundVec( p:GetMins() ) ), ' ' ) )
                dh:next_text( table.concat( table.pack( roundVec( p:GetMaxs() ) ), ' ' ) )
                dh:next_text( table.concat( { p:GetHealth(), p:GetMaxHealth(), p:GetMaxBuffedHealth() }, " / " ) )
                draw.OutlinedRect( 10, 10, 20, 20 )
                --draw.OutlinedRect()
                local m1, m2 = client.WorldToScreen(p:GetMins()), client.WorldToScreen( p:GetMaxs() )
                local x, y = draw.GetScreenSize()

            end
        end
    end
end

callbacks.Unregister( "Draw", "mydraw", doDraw )
callbacks.Register( "Draw", "mydraw", doDraw )
