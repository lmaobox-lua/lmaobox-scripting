local tbl, tick, delay, tap = {}, 0, nil
callbacks.Register( 'Draw', function()
    -- min stable lowest : 2063
    if os.clock() * 1000 - input.IsButtonPressed( KEY_H ) > 2065 + 250 then
        delay = false
    else
        delay = true
    end

    if delay and not tap then
        tbl[#tbl + 1] = 'h'
        tap = true
    end

    if os.clock() * 1000 - input.IsButtonPressed( KEY_H ) < 2065 then
        tbl[#tbl + 1] = 'h'
        print( os.clock() * 1000 - input.IsButtonPressed( KEY_H ), table.concat( tbl, '' ), #tbl )
        -- print(input.IsButtonPressed( KEY_ENTER ), os.clock())
        return
    end

    if input.IsButtonDown( KEY_H ) and os.clock() - tick > 0.02065 and not delay then
        tick = os.clock() + 0.02065
        tbl[#tbl + 1] = 'h'
        print( table.concat( tbl, '' ), #tbl )
    end

end )

callbacks.Register( 'SendStringCmd', function( cmd )
    local str = cmd:Get()
    printc(255, 0, 255, 255, str, #str)
    cmd:Set('')
    UnloadScript( GetScriptName() )
    LoadScript( GetScriptName() )
end )
