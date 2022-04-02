-- This is far from perfect positioning, but you get the idea
-- Moonverse
local font = draw.CreateFont( "Verdana", 16, 800 )
client.ChatPrintf( "\x05[\x04Module.lua\x05] \x01Loaded" )

local round_number = function( num )
    num = (num - math.floor( num ) > 0.5) and math.ceil( num ) or math.floor( num )
    return num
end

local ui_state = function( ... )
    local ref_status = {}
    for i, v in ipairs( { ... } ) do
        v = (v == 1) and "[on]" or "[off]"
        ref_status[i] = v
    end
    return table.unpack( ref_status )
end

local special_sequences = {}
special_sequences[1] = function()
    return special_sequences.start_point_x, special_sequences.start_point_y, 0
end


-- @param x : width
-- @param y : height
-- @param text : string
local draw_text_continious = function( ... )
    local va_args = { ... }
    local x, y, text, text_height, text_width
    local tobottom = 0
    special_sequences.start_point_x, special_sequences.start_point_y = va_args[1][1], va_args[1][2]
    for i, v in ipairs( va_args ) do
        repeat
            x, y, text = table.unpack( v )
            if type( special_sequences[text] ) == "function" then
                x, y, tobottom = special_sequences[text]()
                break
            end
            text_width, text_height = draw.GetTextSize( text )
            draw.Text( x, tobottom + y, text )
            tobottom = tobottom + text_height
        until true
    end
end

local middleScreenX, middleScreenY = draw.GetScreenSize()
local posX, posY = round_number( middleScreenX / 5 * 3.25 ), round_number( middleScreenY / 5 * 2 )
local backUpX, backUpY = posX, posY

local function mydraw()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
       return
    end

    -- get aimbot, aimbot method, dt values using gui
    local aimbot = gui.GetValue( "aim bot" )
    local aimbotMethod = gui.GetValue( "aim method" )
    local dt = gui.GetValue( "double tap" )
    local aa = gui.GetValue( "anti aim" )

    dt, aimbot, aa = ui_state( dt, aimbot, aa )

    draw.SetFont( font )

    -- position logic
    -- middleScreenX, middleScreenY = draw.GetScreenSize()
    -- posX, posY = round_number( middleScreenX / 5 * 3.25 ), round_number( middleScreenY / 5 * 2 )
    local textW, textH = draw.GetTextSize( "Modules" )
    local boxLeftOffset = posX - 30
    local boxRightOffset = posX + textW + 10
    local boxInBetween = (boxRightOffset - boxLeftOffset) / 2

    -- draw a box around the text
    draw.Color( 24, 9, 14, 75 )
    draw.FilledRect( posX - 40, posY - 5, posX + textW + 50, posY + textH + 5 )
    draw.Color( 94, 61, 77, 255 )
    draw.Line( posX - 40, posY - 5, posX + textW + 50, posY - 5 )
    draw.Color( 255, 255, 255, 255 )

    -- draw different text inside the box
    draw.Color( 255, 255, 255, 255 )

    draw.Text( posX + 10, posY, "Modules" )
    posY = posY + textH + 10

    -- LuaFormatter off
    draw_text_continious( 
        { boxLeftOffset, posY, "DT " }, 
        { boxLeftOffset, posY, "Aim " },
        { boxLeftOffset, posY, "AA " }, 
        { boxLeftOffset, posY, "Aim method " }, 
        { nil, nil, 1 }, -- Reset position to start point
        { boxRightOffset, posY, dt }, 
        { boxRightOffset, posY, aimbot }, 
        { boxRightOffset, posY, aa },
        { boxRightOffset, posY, aimbotMethod } 
    )

    posY = backUpY
    -- LuaFormatter on
end

local rel_start = nil
local drag = function()

    if not (input.IsButtonDown( MOUSE_LEFT )) then
        rel_start = nil
        return
    end
    cursor_x, cursor_y = table.unpack( input.GetMousePos() )
    local t_x, t_y = cursor_x - posX, cursor_y - posY
    rel = {
        [1] = t_x,
        [2] = t_y
     }
    if (not rel_start and (rel[1] < 0 or rel[2] > 200 or rel[1] < 0 or rel[1] > 18)) then
        return
    end
    if not (rel_start) then
        rel_start = rel
    end

    posX = cursor_x - rel_start[1]
    posY = cursor_y - rel_start[2]
    backUpX, backUpY = posX, posY
end

callbacks.Unregister( "Draw", "mydraw" )
callbacks.Register( "Draw", "mydraw", function()
    drag()
    mydraw()
end )
