local cvar = require 'cvar'

cvar.add_cvar("Info", function( cvar )
    cvar:Set("")

end)

cvar.remove_cvar("info")

cvar.add_cvar("Info", function( cvar )
    cvar:Set("")
    
end)