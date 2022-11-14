--- copied from / heavily inspired by: 
--- https://lua.neverlose.cc/documentation/variables/_g#new_class

local function new_class()
    local proxy, real = {}, {}
    setmetatable(proxy, {
        __index = function(self, key)
            if key ~= 'struct' then
                return real[key]
            end
            return function(self, k)
                return function(t)
                    real[k] = t
                    setmetatable(real[k], {
                        __index = function(self, kk)
                            return rawget(real, kk)
                        end
                     })
                    return proxy
                end
            end
        end
     })
    return proxy
end

local ctx = new_class():struct 'struct_one' {
    variable = 1,

    some_function = function(self)
        print(string.format('variable from struct_two: %d', self.struct_two.variable))
    end
 }:struct 'struct_two' {
    variable = 2,

    some_function = function(self)
        print(string.format('variable from struct_one: %d', self.struct_one.variable))
    end
 }
ctx.struct_two:some_function()
ctx.struct_one:some_function()

local ctx = new_class():struct 'struct_one' {
    variable1 = 'test',

    some_function = function(self, arg1)
        print(arg1)
        print(string.format('Hello World (%s)', self.variable1))
    end
 }

ctx.struct_one:some_function('test')
