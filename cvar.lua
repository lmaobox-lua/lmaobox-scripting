-------------------------------------------------^-------------------------------------------------
local author<const>, version<const> = 'Moonverse#9320', 1
-------------------------------------------------^-------------------------------------------------

local GetScriptFileName = function( s )
    s = s or GetScriptName()
    local _, p = s:find( '.*[/\\]' )
    local _, q = s:find( '.*[.]' )
    return s:sub( p + 1, q - 1 ), s:sub( p + 1, #s )
end

-- Configuration
local unique_callback_mutex<const> = 'cvar-8b9cb50f-987f-4975-a24c-8b4378281ea0'
local is_convar_case_sensitive<const> = false

--
local filename, filename_ext = GetScriptFileName()
local verbose = {
    '[%s] (i) %s: %q is already registered',
    '[%s] (i) %s: %q is already registered in another script',
    '[%s] (i) %s: %q is not registered',
    '[%s] (i) %s freed it\'s registered convar.',
 }
function verbose:find( index, prop_name, filepath ) return string.format( verbose[index], filename_ext, select(2, GetScriptFileName( filepath )), prop_name )  end

local owner, convar = {}, {}

local register = function( name, callback )
    assert( type( name ) == 'string' )
    assert( type( callback ) == 'function' )
    local _, __, filepath = pcall( debug.getlocal, 4, 1 )
    name = is_convar_case_sensitive == true and name or name:lower()
    local id = filepath .. '-' .. name

    if not convar[name] then
        owner[id], convar[name] = name, callback
        return true
    end

    printc( 0, 170, 218, 255, verbose:find( owner[id] == name and 1 or 2, name, filepath ) )
    return false
end

local unregister = function( name )
    assert( type( name ) == 'string' )
    local _, __, filepath = pcall( debug.getlocal, 4, 1 )
    local id = filepath .. '-' .. name

    if owner[id] then
        convar[name], owner[id] = undef, undef
        return true
    end

    printc( 0, 170, 218, 255, verbose:find( owner[id] == name and 2 or 3, name, filepath ) )
    return false
end

local release = function()
    local _, __, filepath = pcall( debug.getlocal, 4, 1 )
    for id, name in pairs( owner ) do
        local substr_init, substr_end = id:find( filepath, 1, true )
        if substr_init == 1 then
            convar[name] = undef
            owner[id] = undef
        end
    end
    printc( 172, 209, 175, 255, verbose:find( 4, '', filepath ) )
end

local SendStringCmd = function( stringCmd )
    local message, seperated_by_space = stringCmd:Get(), {}

    for v in message:gmatch( '%S+' ) do
        seperated_by_space[#seperated_by_space + 1] = v
    end

    local func, method = convar[seperated_by_space[1]], nil

    if func then
        table.remove( seperated_by_space, 1 )
        method = 1
        goto invoke_cvar
    end

    for name, _ in pairs( convar ) do
        local iter, seperated_by_space = false, {}
        local message_alt = message:gsub( name, function( c )
            if not iter then
                iter = true
                return name .. ' '
            end
        end )
        local substr_init, substr_end = message_alt:find( name, 1, true )
        if substr_init == 1 then
            for v in message_alt:sub( substr_end + 1, #message_alt ):gmatch( '%S+' ) do
                print( v )
                seperated_by_space[#seperated_by_space + 1] = v
            end
            func = _
            method = 2
        end
    end

    ::invoke_cvar::
    local cvar = {}
    function cvar:Method() return method end
    function cvar:Set( ... ) return stringCmd:Set( ... ) end
    function cvar:Get() return seperated_by_space end
    function cvar:GetOnlyNum() end
    function cvar:GetOnlyString() end
    return type( func ) == 'function' and func( cvar )
end

local unload_module = function()
    local cur = GetScriptName()
    for id, lib in pairs( package.loaded ) do
        local lib = string.match( cur, id, 1, true )
        if lib then
            package.loaded[lib] = undef
            printc( 218, 196, 0, 255, string.format( '[%s] (a) package.loaded[%q] = undef', filename_ext, lib ) )
        end
    end
    UnloadScript( cur )
    printc( 255, 125, 100, 255, string.format( '[%s] (a) UnloadScript([[%s]])', filename_ext, cur ) )
end

callbacks.Register( 'SendStringCmd', unique_callback_mutex, SendStringCmd )
-- lua callbacks.Unregister( 'SendStringCmd', unique_callback_mutex )

return {
    register = register,
    unregister = unregister,
    release = release,
    unload_module = unload_module,
 }
