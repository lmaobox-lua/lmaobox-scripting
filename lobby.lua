-- made exclusively for discord: 232641555398131712
local command = {}

local function parser( self, args )
    local fn = self[args[1]]
    if fn then
        return fn( { table.unpack( args, 2, #args ) } )
    end
    return false
end

local function tokenizer( text )
    if #text == 0 then
        return
    end
    local args = {}
    for token in text:gmatch( "%g+" ) do
        if #args == 0 then
            token = token:lower()
        end
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

local function is_lobby_leader( steamid )
    if not steamid then
        steamid = steam.GetSteamID()
    end
    return party.GetLeader() == steamid
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
        local c, k = self.count, q__proxy[index]
        index = predict_match_group[index]
        if not index then
            return
        end
        if not value and k then
            q__proxy[index] = nil
            c = c - 1
        elseif value and not k then
            q__proxy[index] = {}
            c = c + 1
            goto assign
        elseif value and k then
            c = c
            goto assign
        end
        goto continue
        ::assign::
        value = math.min( math.max( math.abs( value ), 0.75 ), 7200 )
        q__proxy[index]['delay'] = value
        q__proxy[index]['time'] = os.clock() + value
        ::continue::
        self.count = c
        callbacks.Unregister( 'Draw', 'auto_queue' )
        if c > 0 then
            callbacks.Register( 'Draw', 'auto_queue', function()
                for mode, t in pairs( q__proxy ) do
                    if os.clock() > t['time'] then
                        t['time'] = os.clock() + t['delay']
                        queue_func( mode )
                    end
                end
            end )
        end
    end
 } )

-- TODO : rework queue -> support queue standby + clear nextgame queue + clear standby queue
var( 'queue', function( args )
    local str, time = table.unpack( args )

    if str == 'clear' then
        for k, g in pairs( party.GetAllMatchGroups() ) do
            party.CancelQueue( g )
        end
        q__proxy = {}
        q___mt.count = 0
        return callbacks.Unregister( 'Draw', 'auto_queue' )
    end

    q___mt[predict_match_group[str]] = tonumber( time )
    queue_func( str )
end )

-- tf_party_debug
-- tf_party_incoming_invites_debug 

local session_ban = {}
local ban_duration = 600 -- 10 minutes

local function leader_lobby_method( args, callback, fmt )
    if not is_lobby_leader() then
        return print( 'I\'m not lobby leader.' )
    end
    local any = table.concat( args, ' ' )
    local guessName = any:match( "^[\"']+(.-)[\"']+$" ) -- pattern devil
    local indexOrSteam64 = tonumber( any )
    local stack = party.GetMembers()
    for index, steam3 in ipairs( stack ) do
        local name = steam.GetPlayerName( steam3 )
        local steam64 = steam.ToSteamID64( steam3 )
        -- LuaFormatter off 
        if indexOrSteam64   == index 
        or indexOrSteam64   == steam64
        or guessName        == name 
        or any              == steam3 then
        -- LuaFormatter on 
            local template = {
                ['party_member_index'] = index,
                ['steam3'] = steam3,
                ['steam64'] = steam64,
                ['name'] = name
             }
            if fmt then
                print( (fmt:gsub( '(%b{})', function( w )
                    return template[w:sub( 2, -2 )] or w
                end )) )
            end
            return callback( steam3 ), steam3
        end
    end
end

var( 'invite', function( args )
    local ref = 'share my lobby' 
    local original = gui.GetValue(ref)
    local steam64 = steam.ToSteamID64( args[1] )
    gui.SetValue( ref, true )
    client.Command( 'tf_party_force_update', true )
    client.Command( 'tf_party_invite_user %d', true )

end )

-- tf_party_request_join_user 

var( 'kick', function( args )
    leader_lobby_method( args, party.KickMember,
        '[SUISEX] Kicking : {name}, index: {party_member_index}, steamid3: {steam3}' )
end )

var( 'transfer', function( args )
    leader_lobby_method( args, party.PromoteMemberToLeader,
        '[SUISEX] Giving lobby ownership to : {name}, index: {party_member_index}, steamid3: {steam3}' )
end )

var( 'ban', function( args )
    local _, steam3 = leader_lobby_method( args, party.KickMember,
        '[SUISEX] Temp Banning : {name}, index: {party_member_index}, steamid3: {steam3}' )
    if steam3 then
        session_ban[steam3] = os.clock() + ban_duration
    end
end )

-- TODO: ...
local e = {
    ['lobby_updated'] = function( event )
        for index, steam3 in ipairs( party.GetPendingMembers() ) do
            if session_ban[steam3] < os.clock() then
                party.KickMember( steam3 )
                print( '[SUISEX] Expected ' .. steam3 .. ' cannot join for:' .. os.clock() - session_ban[steam3] )
            end
        end
    end
 }

callbacks.Register( 'FireGameEvent', function( event )
    local v = e[event:GetName()]
    if v then
        v( event )
    end
end )

callbacks.Register( 'SendStringCmd', function( cmd )
    if tokenizer( cmd:Get() ) ~= false then
        cmd:Set( '' )
    end
end )

