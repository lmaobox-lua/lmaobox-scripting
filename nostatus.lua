local function onStringCmd( stringCmd )

    if stringCmd:Get() == "status" then
        stringCmd:Set( "echo No status for you!" )
    end
end

callbacks.Register( "SendStringCmd", "hook", onStringCmd )