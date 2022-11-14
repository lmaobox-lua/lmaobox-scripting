local function add_search_path(path)
    if not package.path:match( path ) then
        local to_add = {
            path .. [[\?.lua]],
            path .. [[\?.lc]],
            path .. [[\?\init.lua]],
        }
        package.path = package.path .. table.concat(to_add, ';')
    else
        print("already existed")
    end
end
