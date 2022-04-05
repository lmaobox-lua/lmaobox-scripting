--[[
    callbacks.Unregister( 'Draw', 'settimeout_timer' )
local callback_delay_call = {}
local callback_time_out = function( milisecond, fn, runForever )
    local expire = (milisecond / 1000) + globals.RealTime()
    -- print( 'index: ' .. #_queue+1 .. ' registered, run at: ' .. expire )
    if (runForever) then
        table.insert( callback_delay_call, { expire, fn, milisecond } )
    else
        table.insert( callback_delay_call, { expire, fn, 0 } )
    end
end

callbacks.Register( 'Draw', 'settimeout_timer', function()
    local now = globals.RealTime()
    for k, v in ipairs( callback_delay_call ) do
        local expire, fn, milisecond = v[1], v[2], v[3]
        if not (expire > now) then
            -- print( 'index: ' .. k .. ' expired' .. ' at: ' .. now )
            fn()
            table.remove( callback_delay_call, k )
            if (milisecond > 0) then
                callback_time_out( milisecond, fn, true )
            end
        end
    end
end )
]] --
local delayed_call, delayed_call_on_index_remove = {}, {}

delayed_call.remove = function( index )
    assert( type( delayed_call[index] ) == "table", ".remove fails to remove callback, index: " .. tostring( index ) )
    delayed_call[index] = undef
    delayed_call_on_index_remove[index] = undef
    return true
end

delayed_call.add = function( interval, callback, repeated )
    local index = #delayed_call + 1
    local expired
    expired = (interval / 1000) + globals.RealTime()
    delayed_call[index] = { expired, interval, callback, repeated }
    ---
    local method = {
        interval = interval
     }
    function method:new_interval( interval )
        self.interval = interval
        repeated = true
        delayed_call[index] = { expired, interval, callback, repeated }
        return true
    end
    function method:queue_remove()
        delayed_call_on_index_remove[index] = index
    end
    return method
end

callbacks.Unregister( 'Draw', 'delayed_call_timer' )
callbacks.Register( 'Draw', 'delayed_call_timer', function()
    local now = globals.RealTime()
    for i, v in ipairs( delayed_call ) do
        repeat
            local expired, interval, callback, repeated = table.unpack( v )
            if (now < expired) then
                break
            end
            callback()
            if repeated and not (delayed_call_on_index_remove[i] == i) then
                expired = (interval / 1000) + globals.RealTime()
                delayed_call[i][1] = expired
            else
                delayed_call.remove( i )
            end
        until true
    end
end )

local reference_leak
local e = delayed_call.add( 1000, function()
    -- printLuaTable( reference_leak )
    if reference_leak.interval ~= 3000 then
        reference_leak:new_interval( 3000 )
    end
    reference_leak:queue_remove()
end, true )
reference_leak = e

local i = 0
local ref_lek
local t = delayed_call.add( 1000, function()
    i = i + 1
    if i > 10 then
        print("Reached end.")
        ref_lek:queue_remove()
    end
end, true )
ref_lek = t

local g = delayed_call.add( 30, function()
    print( i )
end, true )


-- bad example above
-- rewrite