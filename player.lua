for playerindex, ent in pairs( entities.FindByClass( 'CTFPlayer' ) ) do
    print( playerlist.GetPriority( ent ) )
    --playerlist.SetPriority( ent, -1 )
    print(playerlist.GetColor(ent))

end
