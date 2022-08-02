----------------------------
---    utility library   ---
---- also known as      ----    Thanks, very cool.
--- ulitmate library lol ---    Didn't ask, who?
-- o . o  bluffing  o . o --
local __WHO, __VERSION, __NAME = 'Moonverse#9320', 1, 'utils'



local get_script_name = function( filepath )
    if not filepath then
        filepath = select( 3, pcall( debug.getlocal, 4, 1 ) )
    end
    local i, j, l = 0, 1, nil
    local tree = {
        substr_start = {},
        substr_end = {},
     }
    for path in filepath:gmatch( '[^\\/]+' ) do
        j, l = filepath:find( path, j, true )
        i = i + 1
        tree[i], tree.substr_start[i], tree.substr_end[i] = path, j, l
    end
    tree.file_name_ext = tree[#tree]
    tree.file_name = tree.file_name_ext:sub( 1, select( 2, tree.file_name_ext:find( '.*[.]' ) ) - 1 )
    function tree:parent_dir( file, level, fmt )
        level = level or 1
        local j, l = filepath:find( file, 1, true )
        for i, v in ipairs( tree.substr_start ) do
            if v == j then
                local buf = {}
                for init = level, 1, -1 do
                    i = i - 1
                    if not tree[i] then
                        break
                    end
                    table.insert( buf, 1, tree[i] )
                end
                return table.concat( buf, fmt or '\\' )
            end
        end
    end
    return tree, tree.file_name_ext, tree.file_name
end

local _, filename, filename_ext = get_script_name( GetScriptName() )

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

local print_tag_color = {
    ['d'] = function() return 172, 209, 175, 255 end, -- debug rgba(172, 209, 175, 255)
    ['i'] = function() return 0, 170, 218, 255 end, -- info rgba(0, 170, 218, 255)
    ['w'] = function() return 218, 196, 0, 255 end, -- warn rgba(218, 196, 0, 255)
    ['e'] = function() return 255, 125, 100, 255 end, -- error rgba(255, 125, 100, 255)
 }
local print_tag = ''
local set_print_tag = function( v ) print_tag = tostring( v ) end
local print = function( level, ... )
    local r, g, b, a = type( print_tag_color[level] ) == 'function' and print_tag_color[level]() or 255, 255, 255, 255
    printc( r, g, b, a, string.format( '%s: (%s) %s', print_tag, level, table.concat({...}) ) )
end


-- region: 


-- endregion:

-- region: string

local localize_string = function( v )
    v = client.Localize( tostring( v ) )
    return utf8.char( string.byte( v, 1, #v ) )
end

local to_plain_string = function( v ) return tostring( v ):sub( '%c', '' ):sub( '%%', '%%%%' ) end

local pad_string = function( v, substr, prefix, suffix )
    return tostring( v ):gsub( substr, prefix or '' .. '%1' ):gsub( substr, '%1' .. suffix or '' )
end

-- endregion:

_G.get_script_name = get_script_name
return {
    unload_module = unload_module,
    get_script_name = get_script_name,
    print = print,
    set_print_tag = set_print_tag,
 }

-- lua for proc in io.popen( 'set' ):lines() do print( proc )end
