callbacks.Unregister( 'Draw', 'settimeout_timer' )
local queueFN = {}
local settimeout = function( milisecond, fn, loop_forever )
    local expire = (milisecond / 1000) + globals.RealTime()
    -- print( 'index: ' .. #_queue+1 .. ' registered, run at: ' .. expire )
    if (loop_forever) then
        table.insert( queueFN, { expire, fn, milisecond } )
    else
        table.insert( queueFN, { expire, fn, 0 } )
    end
end

local settimeout_timer = function()
    local now = globals.RealTime()
    for k, v in ipairs( queueFN ) do
        local expire, fn, milisecond = v[1], v[2], v[3]
        if not (expire > now) then
            -- print( 'index: ' .. k .. ' expired' .. ' at: ' .. now )
            fn()
            table.remove( queueFN, k )
            if (milisecond > 0) then
                settimeout( milisecond, fn, true )
            end
        end
    end
end
callbacks.Register( 'Draw', 'settimeout_timer', settimeout_timer )
local last = 1
settimeout( 1000, function()
    local ping = clientstate.GetLatencyOut()
    print( (ping + last) / 2 )
    last = ping
end, true )
