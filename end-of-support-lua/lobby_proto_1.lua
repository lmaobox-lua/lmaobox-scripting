-- made exclusively for discord: 232641555398131712
local command = {}

local function parser( self, args )
    local fn = self[args[1]]
    if fn then
        return fn( { table.unpack( args, 2, #args ) } )
    end
end

local function tokenizer( text )
    if #text == 0 then
        return
    end
    local args = {}
    for token in text:lower():gmatch( "%g+" ) do
        args[#args + 1] = token
    end
    return parser( command, args )
end

local var = setmetatable( {}, {
    __index = {
        var = function( name, value, mt )
            local t = type( value )
            if t == 'table' then
                if not mt then
                    mt = {
                        __call = function( self, args )
                            if #args == 0 and self.__description__ then
                                print(self.__description__)
                                return false
                            end
                            return parser( self, args )
                        end
                     }
                end
                setmetatable( value, mt )
            elseif t ~= 'function' then
                return
            end
            command[name] = value
        end,
        description = function( self, text )
            command[self.name].__description__ = text 
        end
     },
    __call = function( self, name, value, mt )
        self.name = name:lower()
        self.var( self.name, value, mt )
        return self
    end,
    __newindex = function( self, index, value )
        if self[index] == nil then
            rawset( self, index, value )
        end
    end
 } )

callbacks.Register( 'SendStringCmd', function( cmd )
    if tokenizer( cmd:Get() ) ~= false then
        cmd:Set( '' )
    end
end )

var( 'queue', {}, {
    __call = function( self, args )
       
    end
 } )

 var('info', {
    ['leader'] = function( args )
        print( type(args) ) 
    end
 }):description([[
    [description] info <command>
        leader    : show leader steamid64
        members   : show memeber steamid64
 ]])

var( 'b', function( args )
    printLuaTable( args )
end )