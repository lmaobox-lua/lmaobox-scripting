-- made exclusively for discord: 232641555398131712
local command = {}

local function parser( self, args )
    local fn = self[args[1]]
    if fn then
        return fn( { table.unpack( args, 2, #args ) } )
    end
end

local function tokenizer( text )
    if #text == 0 then
        return
    end
    local args = {}
    for token in text:lower():gmatch( "%g+" ) do
        args[#args + 1] = token
    end
    return parser( command, args )
end

local function var( name, val, mt )
    local t = type( val )
    if t == 'table' then
        if not mt then
            mt = {
                __call = parser
             }
        end
        setmetatable( val, mt )
    elseif t ~= 'function' then
        return
    end
    command[name:lower()] = val
end

local predict_match_group = {}
do
    local matchgroups = party.GetAllMatchGroups()
    for k in pairs( matchgroups ) do
        local i = 1
        for j = 2, #k do
            local s = k:sub( i, j )
            predict_match_group[s:lower()] = k
            predict_match_group[s] = k
        end
    end
end

local queue_func = function( str )
    local matchgroups = party.GetAllMatchGroups()
    for k, mode in pairs( matchgroups ) do
        if predict_match_group[str] == k then
            local reasons = party.CanQueueForMatchGroup( mode )
            if reasons == true then
                party.QueueUp( mode )
            else
                for k, v in pairs( reasons ) do
                    -- print( v )
                end
            end
        end
    end
end

local q__proxy = {}
local q___mt = setmetatable( {
    count = 0
 }, {
    __index = q__proxy,
    __newindex = function( self, index, value )
        local c, v = self.count, self.index
        if not value and v then
            q__proxy[index] = nil
            c = c - 1
        elseif value and not v then
            q__proxy[index] = {}
            q__proxy[index]['delay'] = value
            q__proxy[index]['time'] = os.clock() + value
            c = c + 1
        elseif value and v then
            q__proxy[index]['delay'] = value
            q__proxy[index]['time'] = os.clock() + value
            c = c
        end
        self.count = c
        callbacks.Unregister( 'Draw', 'auto_queue' )
        if c > 0 then
            callbacks.Register( 'Draw', 'auto_queue', function()
                for k, t in pairs( q__proxy ) do
                    if os.clock() > t['time'] then
                        t.time = os.clock() + t['delay']
                        queue_func( predict_match_group[k] )
                    end
                end
            end )
        end
    end
 } )

var( 'queue', {}, {
    __call = function( self, args )
        local str, time = table.unpack( args )
        if not time then
            q___mt[predict_match_group[str]] = nil
        else
            q___mt[predict_match_group[str]] = tonumber( time )
        end
        queue_func( str )
    end
 } )

callbacks.Register( 'SendStringCmd', function( cmd )
    if tokenizer( cmd:Get() ) ~= false then
        cmd:Set( '' )
    end
end )
