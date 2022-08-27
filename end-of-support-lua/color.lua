local Color = {
    r = 0,
    g = 0,
    b = 0,
    a = 255
 }

---@alias constructor
-- /
---| '"rgb(250, 0,0)"'
---| '"hsl(0, 100%, 50%)"'
---| '"#ff0000"'
---| '"red"'
---| '0xff0000'
-- /
---| '"rgba(250, 0, 0, 255)"'
---| '"hsla(0, 100%, 50%, 1)"'
---| '"#ff0000ff"'
---| '"red"'
---| '0xff0000'

local function from_table( self, t )
    local ordered_keys = { 'r', 'g', 'b', 'a' }
    for k, v in pairs( t ) do
        if type( k ) == 'number' then
            k = ordered_keys[k]
        end
        if v ~= nil then
            if type( v ) == 'string' then
                v = tonumber( v )
            end
            self[k] = v
        end
    end
    return Color
end

local function from_rgba( self, ... )
    return self:from_table( { ... } )
end

local function from_Unsigned( self, dec )
    local size, t = math.floor( (math.log( dec, 2 ) / 8) + 1 ), {}
    for j = size, 1, -1 do
        t[#t + 1] = dec >> ((j * 8) - 8) & 0xFF
    end
    return self:from_table( t )
end

local function from_HEX8( self, hex )
    local dec = tonumber( '0x' .. hex:sub( 2, #hex ) )
    return self:from_Unsigned( dec )
end

local pattern = {
    ['rgba'] = '^rgba%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$',
    ['hsva'] = '^hsva%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$',
    ['hsla'] = '^hsla%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$',
    ['rgb'] = '^rgb%s*%(([^,]+),([^,]+),([^,]+)%)$',
    ['hsv'] = '^hsv%s*%(([^,]+),([^,]+),([^,]+)%)$',
    ['hsl'] = '^hsl%s*%(([^,]+),([^,]+),([^,]+)%)$'
 }

local function from_CSS( self, css )
    local lazy = pattern[css:sub( 1, 4 ):gsub( '%(', '' )]
    local r, g, b, a = css:match( lazy )
    return self:from_table( { r, g, b, a } )
end

local function from_ColorDict( self, k )

end

setmetatable( Color, {
    __call = function( self, ... )
        local args = { ... }
        local var, len = args[1], #args

        if len == 0 then
            return Color
        end

        if type( var ) == 'string' then
            return from_HEX8( var )
        end
    end,

    __index = {
        from_rgba = from_rgba,
        from_table = from_table,
        from_HEX8 = from_HEX8,
        from_CSS = from_CSS,
        from_ColorDict = from_ColorDict
     },

    __newindex = function( t, k, v )
        print( k, v )
    end
 } )

Color:from_CSS( 'rgb(255, 255, 255)' )

