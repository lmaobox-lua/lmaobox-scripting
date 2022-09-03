local menu<close> = require "menu"

local main = menu( 'main', 200, 200, 800, 640 )
--main:controls( )
--main:style( )
main:sharable( true, 'unique-ui' )


main:label( 'Welcome to Moonverse\'s Menu ☜(⌒▽⌒)☞', 2 )
main:label( 'Here\'s where you can find list of controls:\n(i lied)' )


local open, nlast = true, os.clock()
callbacks.Register( 'Draw', function()
    if input.IsButtonPressed( KEY_DELETE ) and os.clock() - nlast >= 0.5 then
        open = not open
    end

    if open then
        input.SetMouseInputEnabled( true )
        main:text( table.concat( input.GetMousePos(), ', ' ) )
        main:render()
        return
    end
    input.SetMouseInputEnabled( false )
end )
