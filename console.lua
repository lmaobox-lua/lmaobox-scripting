UnloadScript( GetScriptName() )
callbacks.Unregister( 'SendStringCmd', 'cli-parse')

local cvar, var = {}, {}
cvar.RegisterCommand = function( name, callback )
    if type( var[name] ) ~= 'nil' then return false end
    var[name] = callback
    return true
end
cvar.UnregisterCommand = function( name )
    if type( var[name] ) == 'nil' then return false end
    var[name] = undef
    return true
end
local VarSetInfo = function( name, val ) client.Command( string.format( 'setinfo %q %q', name, val or '' ), true ) end

callbacks.Register( 'SendStringCmd', 'cli-parse', function( cmd )
    local feed = cmd:Get()
    for name, callback in pairs( var ) do
        local i, j = string.find( feed, name, 1, true )
        if i == 1 then
            local a = {}
            for w in feed:sub( j + 1, #feed ):gmatch( '%S+' ) do a[#a + 1] = w end
            cvar.Set = function( any ) return cmd:Set( any ) end
            return callback( #a, table.unpack( a ) )
        end
    end
end )

cvar.RegisterCommand( 'info', function( argc, ... )
    cvar.Set( '' )
    local argcc = argc > 0 and argc or 1
    printc( 255 // (argc * 0.01), 255, 255 // (argc * 0.03), 255, string.format( 'current script: %s', GetScriptName() ) )
    printc( 255 // (argc * 0.01), 255, 255 // (argc * 0.03), 255, string.format( 'argument count: %d', argc ) )
    print( table.concat( { ... }, '\n' ) )
end )

-- because unload command is used in beta version of the cheat to uninject.
cvar.RegisterCommand( 'lua_unload', function( argc, to_unload )
    cvar.Set( '' )
    local argcc = argc > 0 and argc or 1
    local dir = os.getenv('LOCALAPPDATA')
    local absolute = dir .. "//" .. to_unload
    if type( to_unload ) == 'string' and #to_unload > 0 then
        printc( 255 // (argc * 0.01), 255, 255 // (argc * 0.03), 255, string.format( 'unloading %s (result: %s)', absolute, UnloadScript( absolute ) ) )   
    end
end )