local menu = require "menu"
menu:dereference()

local main = menu( 'main', 200, 200, 800, 640 )
local header = main:label('yes', 2)
main:label('?')
-- printLuaTable(main)
callbacks.Register( 'Draw', function()
    if input.IsButtonPressed( KEY_L ) then
        input.SetMouseInputEnabled( true )
        main:text( table.concat( input.GetMousePos(), ', ' ) )
        header:text( menu.get_held_time( KEY_L ) )
        main:render()
        return
    end
    input.SetMouseInputEnabled( false )
end )

