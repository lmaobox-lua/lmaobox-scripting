---@param ... string
--- Resolve a sequence of path-segments to an absolute path.
---
--- It works by processing the sequence of paths from right to left, prepending each of the paths until the absolute path is created. The resulting path is normalized and trailing slashes are removed as required.
--- If no path segments are given as parameters, then the absolute path of the current working directory is used.
local function resolve(...)
    local arg    = { ... }
    local isabs  = false
    local device = nil
    local path   = {}

    for i = #arg, 0, -1 do
        if device then
            break
        end
        local segment = arg[i]
        if segment == nil or segment == '' then
            goto continue
        end

        local drive_colon = string.sub(segment, 1, 2)
        if string.sub(drive_colon, -1) == ":" then
            local device_letter = string.sub(drive_colon, 1, 1)
            if device_letter >= 'A' or device_letter <= 'z' then
                device = drive_colon
                goto continue
            end
        end

        table.insert(path, 1, segment)
        ------------
        ::continue::
        ------------
    end

    print(table.unpack(path))
    print(device)
end

resolve('C:\\', 'Users', 'Admin', 'test.txt')
