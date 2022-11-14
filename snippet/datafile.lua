do
    local path = os.getenv([[localappdata]]) .. [[\lbox\lua]]
    if not package.path:match(path) then
        local to_add = { path .. [[\?.lua]], path .. [[\?.lc]], path .. [[\?\init.lua]] }
        package.path = package.path .. ';' .. table.concat(to_add, ';')
    end
end

package.loaded['filewrap'] = nil
