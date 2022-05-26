UnloadScript( GetScriptName() )

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
    printc( 255 // (argc * 0.01), 255, 255 // (argc * 0.03), 255, string.format( 'argument count: %d', argc ) )
    print( table.concat( { ... }, '\n' ) )
end )

-- endregion:

local self_unload_module = (function()
    local _, __, filepath = pcall( debug.getlocal, 4, 1 )
    for id, lib in pairs( package.loaded ) do
        local matched = string.match( GetScriptName(), id, 1, true )
        if matched then
            printc( 0, 255, 0, 255, string.format( '[packages.loaded]| found: %q', matched ) )
            package.loaded[matched] = undef
            printc( 0, 255, 255, 255, string.format( '[packages.loaded]| %q is unloaded (method called on : %q)', matched, filepath ) )
        end
    end
end)

local make_unique_string = function( prefix ) return table.concat( { prefix or '', engine.RandomFloat( 0, 1 ), GetScriptName() }, '_' ) end

local main = function() end

if pcall( debug.getlocal, 4, 1 ) then
    -- executed as module
    print( 'this message appears when module entries packages.loaded' )
    return {
        self_unload_module = self_unload_module,
        make_unique_string = make_unique_string,
     }
else
    -- executed as main script
    self_unload_module()
    main()
end


local osEnv = {}

for line in io.popen("set"):lines() do
  envName = line:match("^[^=]+")
  osEnv[envName] = os.getenv(envName)
  if envName == nil or os.getenv(envName) == nil then return nil else
  print(tostring(envName)..' = '..osEnv[envName])
  end
end

--[[
    local win = string.format( [[
        lllllllllllllll  lllllllllllllll    %s
        lllllllllllllll  lllllllllllllll    %s@%s - %s
        lllllllllllllll  lllllllllllllll    ~.~.~.~.~.~.~.~.~.~.~.~.~.~
        lllllllllllllll  lllllllllllllll    Resolution: %s
        lllllllllllllll  lllllllllllllll    SteamID: %s
        lllllllllllllll  lllllllllllllll    Name: %s
        lllllllllllllll  lllllllllllllll    GCConnected: %s
                                            SignonState: %s
        lllllllllllllll  lllllllllllllll    IsPremium: %s
        lllllllllllllll  lllllllllllllll    
        lllllllllllllll  lllllllllllllll
        lllllllllllllll  lllllllllllllll
        lllllllllllllll  lllllllllllllll
        lllllllllllllll  lllllllllllllll
        lllllllllllllll  lllllllllllllll
    ]]--[[,os.date( '%c' ), os.getenv( 'USERNAME' ), os.getenv( 'COMPUTERNAME' ), os.getenv( 'OS' ),
    table.concat( { draw.GetScreenSize() }, 'x' ), steam.GetSteamID(), steam.GetPlayerName( steam.GetSteamID() ),
    gamecoordinator.ConnectedToGC(), clientstate.GetClientSignonState(), not client.IsFreeTrialAccount() )
]]