local benchmark
do
    local units = {
        ['seconds'] = 1,
        ['milliseconds'] = 1000,
        ['microseconds'] = 1000000,
        ['nanoseconds'] = 1000000000
    }

    function benchmark(unit, decPlaces, n, f, ...)
        local elapsed = 0
        local multiplier = units[unit]
        for i = 1, n do
            local now = os.clock()
            f(...)
            elapsed = elapsed + (os.clock() - now)
        end
        print(string.format('Benchmark results:\n  - %d function calls\n  - %.' ..
            decPlaces .. 'f %s elapsed\n  - %.' .. decPlaces .. 'f %s avg execution time.', n, elapsed * multiplier, unit
            , (elapsed / n) * multiplier, unit))
    end
end

local function print(s)
    return s
end

local is_canadian = true
local sayit, sayit2
do
    local t
    function sayit(letters)
        t = t or {
            a = "aah",
            b = "bee",
            c = "see",
            ['?'] = function() return is_canadian and "zed" or "zee" end
        }
        for _, v in ipairs(letters) do
            local s = type(t[v]) == "function" and t[v]() or t[v] or "blah"
            print(s)
        end
    end
end

--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
do
    function sayit2(letters)
        for ____, char in ipairs(letters) do
            do
                repeat
                    local ____switch5 = char
                    local ____cond5 = ____switch5 == "a"
                    if ____cond5 then
                        print("aah")
                        goto __continue4
                    end
                    ____cond5 = ____cond5 or ____switch5 == "b"
                    if ____cond5 then
                        print("bee")
                        goto __continue4
                    end
                    ____cond5 = ____cond5 or ____switch5 == "c"
                    if ____cond5 then
                        print("see")
                        goto __continue4
                    end
                    ____cond5 = ____cond5 or ____switch5 == "?"
                    if ____cond5 then
                        if is_canadian then
                            print("zed")
                            goto __continue4
                        end
                        print("zee")
                        goto __continue4
                    end
                    do
                        print("blah")
                        goto __continue4
                    end
                until true
            end
            ::__continue4::
        end
    end
end

benchmark('milliseconds', 3, 1000000, sayit, { 'a', 'b', 'c', 'l', 'o', '?' })
benchmark('milliseconds', 3, 1000000, sayit2, { 'a', 'b', 'c', 'l', 'o', '?' })