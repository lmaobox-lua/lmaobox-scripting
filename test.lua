local t = {} -- original table (created somewhere)

-- keep a private access to original table
local _t = t

-- create proxy
t = {}

-- create metatable
local mt = {
    __index = function( t, k )
        print( "*access to element " .. tostring( k ) )
        return _t[k] -- access the original table
    end,

    __newindex = function( t, k, v )
        print( "*update of element " .. tostring( k ) .. " to " .. tostring( v ) )
        _t[k] = v -- update original table
    end,

    __len = function()
        return #_t
    end,

    __pairs = function( self )
        local k
        return function( t, k )
            local v
            k, v = next( t, k )
            if nil ~= v then
                return k, v
            end
        end, _t, nil
    end

 }
setmetatable( t, mt )

table.insert( t, { 'sus' } )
table.insert( t, 'beeem' )
table.insert( t, 'YOOOO' )
table.remove( t, 1 )

for k, v in ipairs( t ) do
    print( k, v )
end
