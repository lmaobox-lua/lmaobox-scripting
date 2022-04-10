

print( "VM Override Loaded!" )
engine.PlaySound( "buttons/button3.wav" )

callbacks.Register( "Draw", "draw", function()
    local x, y, z = math.random( 1, 10 ), math.random( 1, 10 ),  math.random( 1, 10 )
    client.Command( table.concat( { "tf_viewmodels_offset_override", x, y, z }, " " ), true )
end )
