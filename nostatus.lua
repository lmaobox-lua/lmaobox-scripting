local function onStringCmd( stringCmd )
    local cmd = stringCmd:Get()

    if string.find( cmd, "say" ) then
        stringCmd:Set( "echo No status for you!" )
    end
end

callbacks.Unregister( "SendStringCmd", "hook" )
callbacks.Register( "SendStringCmd", "hook", onStringCmd )
