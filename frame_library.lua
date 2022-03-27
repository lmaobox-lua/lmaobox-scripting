-- Frame Library
-- Help with rendering 
-- Container for rendering element
-- Status : BROKEN, UNTESTED

local initFont = (function( path, name, height, weight )
    return (draw.AddFontResource( path ) ~= nil and draw.CreateFont( name, height, weight ))
end)

local Frame = {
    startPosition = {},
    moveUp = 0,
    moveDown = 0,
    moveRight = 0,
    moveLeft = 0
 }

-- https://lmaobox.net/lua/Lua_Libraries/draw/
-- http://lua-users.org/wiki/SwitchStatement
Frame.elem_type = {
    space_t = function( direction, offset )
        offset = offset or 0
        for _, v in ipairs( direction ) do
            if type( Frame[v] ) == "number" then
                Frame[v] = Frame[v] + offset
                return Frame[v]
            end
        end
    end,

    text_t = function( direction, fn, text, xs, ys )
        xs, ys = xs, ys or 0, 0
        local height, width = Frame.startPosition
        local x, y = draw.GetTextSize( text )
        if (direction == Frame.moveUp) or (direction == Frame.moveDown) then
            Frame.elem_type.space_t( direction, x )
        else
            if (direction == Frame.moveUp) or (direction == Frame.moveDown) then
                Frame.elem_type.space_t( direction, y )
            end
        end
        return fn( height + xs, width + ys, text )
    end

 }

-- Call this at the start of function
function Frame:Setup( position_x, position_y )
    Frame.startPosition = table.pack( position_x, position_y )
    self:Clear()
    return true
end

function Frame:Append( elem_type, ... )
    for _, v in ipairs( elem_type ) do
        local s = type( Frame.elem_type[v] ) == "function" do
            Frame.elem_type[v]( ... )
        end 
    end
end

function Frame:Clear()
    for i = 2, #self do
        self[i] = 0
    end
end

-- @example 
local myfont = draw.CreateFont( "Verdana", 16, 800 )
local render_helper = Frame
doDraw = function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        return
    end

    local me = entities.GetLocalPlayer()
    local players = entities.FindByClass( "CTFPlayer" )

    for i, p in ipairs( players ) do
        if p:IsAlive() and not p:IsDormant() and not (p == me) then

            local screenPos = client.WorldToScreen( p:GetAbsOrigin() )
            if screenPos ~= nil then

                draw.SetFont( myfont )
                draw.Color( 255, 255, 255, 255 )
                render_helper:Setup()
                --render_helper:Append( render_helper.elem_type.text_t( render_helper.moveDown, Draw, p:GetName() ) )
            end
        end
    end
end

callbacks.Unregister( "Draw", "mydraw" )
callbacks.Register( "Draw", "mydraw", doDraw )
