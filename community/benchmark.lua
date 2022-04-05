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
        print(string.format('Benchmark results: %d function calls | %.'.. decPlaces ..'f %s elapsed | %.'.. decPlaces ..'f %s avg execution time.', n, elapsed * multiplier, unit, (elapsed / n) * multiplier, unit))
    end
end


function test(n)
    local t = {}
    for i = 1, n do
        t[i] = i
    end
end

benchmark('milliseconds', 2, 500, test, 10000)