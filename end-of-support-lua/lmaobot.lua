local sourcenav = require "sourcenav"

SIGNONSTATE_NONE = 0 -- no state yet, about to connect
SIGNONSTATE_CHALLENGE = 1 -- client challenging server, all OOB packets
SIGNONSTATE_CONNECTED = 2 -- client is connected to server, netchans ready
SIGNONSTATE_NEW = 3 -- just got serverinfo and string tables
SIGNONSTATE_PRESPAWN = 4 -- received signon buffers
SIGNONSTATE_SPAWN = 5 -- ready to receive entity packets
SIGNONSTATE_FULL = 6 -- we are fully connected, first non-delta packet received
SIGNONSTATE_CHANGELEVEL = 7 -- server is changing level, please wait

local nav_area_attributes = {
    CROUCH = 0x1, --must crouch to use this node/area
    JUMP = 0x2, --must jump to traverse this area (only used during generation)
    PRECISE = 0x4,	--do not adjust for obstacles, just move along area
    NO_JUMP = 0x8,	--inhibit discontinuity jumping
    STOP = 0x10, --must stop when entering this area
    RUN = 0x20,	--must run to traverse this area
    WALK = 0x40, --must walk to traverse this area
    AVOID = 0x80, --avoid this area unless alternatives are too dangerous
    TRANSIENT = 0x100, --area may become blocked, and should be periodically checked
    DONT_HIDE = 0x200, --area should not be considered for hiding spot generation
    STAND = 0x400, --bots hiding in this area should stand
    NO_HOSTAGES = 0x800, --hostages shouldn't use this area
    STAIRS = 0x1000, --this area represents stairs, do not attempt to climb or jump them - just walk up
    NO_MERGE = 0x2000, --don't merge this area with adjacent areas
    OBSTACLE_TOP = 0x4000, --this nav area is the climb point on the tip of an obstacle
    CLIFF = 0x8000, --this nav area is adjacent to a drop of at least CliffHeight

    FIRST_CUSTOM = 0x10000, --apps may define custom app-specific bits starting with this value
    LAST_CUSTOM = 0x4000000, --apps must not define custom app-specific bits higher than with this value
    FUNC_COST = 0x20000000, --area has designer specified cost controlled by func_nav_cost entities

    HAS_ELEVATOR = 0x40000000, --area is in an elevator's path
    NAV_BLOCKER = 0x80000000, --area is blocked by nav blocker ( Alas, needed to hijack a bit in the attributes to get within a cache line [7/24/2008 tom])
}

local map_name, nav_instance
local function open_nav_file( map_name, basedir )
    if map_name:len() < 1 then
        return
    end

    local filename, file, content, nav
    basedir = basedir or engine.GetGameDir()
    filename = string.format( '%s/%s', basedir, map_name:gsub( '.bsp$', '.nav' ) )

    file = io.open( filename, 'rb' )
    assert( file, string.format( 'filename: %s does not exist', filename ) )
    content = file:read( 'a' )
    file:close()

    nav = sourcenav.parse( content )
    assert( nav.minor == 2, "invalid minor version, must be 2" )
    assert( nav.analyzed == 1, "invalid nav mesh: not analyzed" )
    return nav
end

printLuaTable(open_nav_file('maps/ctf_2fort.bsp'))

callbacks.Register( 'FireGameEvent', function( event )

    if event:GetName() == 'player_connect_full' then
        
    end

    if event:GetName() == 'round_prestart' then
        
    end

    if event:GetName() == 'player_spawn' then
        
    end

end )

