--[[local function interp( s, tab )
    return (s:gsub( s, function( w )
        print("hi")
        for i, s1 in pairs( tab ) do
            local idx0, idx1 = 0, 0
            if type( s1 ) == 'string' then
                local substr_find, replace_with
                substr_find = s1:match( '[^:]+' )
                replace_with = s1:sub( #substr_find + 2, #s1 )
                s = s:gsub( substr_find, function( match )
                    if s:find( match ) > idx1 then
                        idx0, idx1 = s:find( match )
                        return replace_with
                    end
                    return match
                end )
            end
        end
        return s
    end ))
end
getmetatable( '' ).__mod = interp

local name = 'blue hello world world?'
print( name % { 'hello:xd', 'world:\x01->%1<-\x02', 'world:big shit' } )
local expect = 'hello ->world<- big shit'
-- broken]]

