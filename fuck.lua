callbacks.Register( 'SendStringCmd', function( cmd )
    local p = cmd:Get()
    local i = #p
    if i > 0 then
        printc( 255, 255, 0, 255, p )
    end
end )

