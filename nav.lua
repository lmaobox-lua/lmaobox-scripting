local struct = require 'struct'
struct.unload()
local unpack = table.unpack
local struct_buffer_mt = {
    __index = {
        seek = function( self, seek_val, seek_mode )
            if seek_mode == nil or seek_mode == 'CUR' then
                self.offset = self.offset + seek_val
            elseif seek_mode == 'END' then
                self.offset = self.len + seek_val
            elseif seek_mode == 'SET' then
                self.offset = seek_val
            end
        end,
        unpack = function( self, format_str )
            local unpacked = { struct.unpack( format_str, self.raw, self.offset ) }

            if self.size_cache[format_str] == nil then
                self.size_cache[format_str] = struct.pack( format_str, unpack( unpacked ) ):len()
            end
            self.offset = self.offset + self.size_cache[format_str]

            return unpack( unpacked )
        end,
        unpack_vec = function( self )
            local x, y, z = self:unpack( 'fff' )
            return {
                x = x,
                y = y,
                z = z
             }
        end
     }
 }

local function struct_buffer( raw )
    return setmetatable( {
        raw = raw,
        len = raw:len(),
        size_cache = {},
        offset = 1
     }, struct_buffer_mt )
end

local function parse( raw )
    local buf = struct_buffer( raw )

    local self = {}
    self.magic, self.major, self.minor, self.bspsize, self.analyzed, self.places_count = buf:unpack( 'IIIIbH' )

    assert( self.magic == 0xFEEDFACE, 'invalid magic, expected 0xFEEDFACE' )
    assert( self.major == 16, 'invalid major version, expected 16' )
    assert( self.minor == 2, 'invalid minor version, expected 2' )

    -- TF2 does not use places
    -- place names
    self.places = {}
    for i = 1, self.places_count do
        local place = {}
        place.name_length = buf:unpack( 'H' )

        -- read but ignore null byte
        place.name = buf:unpack( string.format( 'c%db', place.name_length - 1 ) )

        self.places[i] = place
    end

    -- areas
    self.has_unnamed_areas, self.areas_count = buf:unpack( 'bI' )
    self.areas = {}
    for i = 1, self.areas_count do

        local area = {}
        area.id, area.flags = buf:unpack( 'II' )

        area.north_west = buf:unpack_vec()
        area.south_east = buf:unpack_vec()
        area.north_east_y, area.south_west_y = buf:unpack( 'ff' )

        area.center = {}
        area.center.x = (area.north_west.x + area.south_east.x) / 2
        area.center.y = (area.north_west.y + area.south_east.y) / 2
        area.center.z = (area.north_west.y + area.south_east.y) / 2

        --[[
			if ((area.m_seCorner.x - area.m_nwCorner.x) > 0.0f && (area.m_seCorner.y - area.m_nwCorner.y) > 0.0f)
			{
				area.m_invDxCorners = 1.0f / (area.m_seCorner.x - area.m_nwCorner.x);
				area.m_invDzCorners = 1.0f / (area.m_seCorner.z - area.m_nwCorner.z);
			}
			else
				area.m_invDxCorners = area.m_invDzCorners = 0.0f;

			//Change the tolerance if you wish
			area.m_minZ = min(area.m_seCorner.z, area.m_nwCorner.z) - 18.f;
			area.m_maxZ = max(area.m_seCorner.z, area.m_nwCorner.z) + 18.f;
		]]

        -- connections
        area.connections = {}
        for dir = 1, 4 do
            local connections_dir = {}
            connections_dir.count = buf:unpack( 'I' )
            connections_dir.connections = {}
			print(connections_dir.count)
            for i = 1, connections_dir.count do
                local target
                target = buf:unpack( 'I' )
                if target == area.id then
                    goto f
                end
                connections_dir.connections[i] = target
				::f::
            end
            area.connections[dir] = connections_dir
        end

        -- hiding spots
        area.hiding_spots_count = buf:unpack( 'B' )
        area.hiding_spots = {}
        for i = 1, area.hiding_spots_count do
            local hiding_spot = {}
            hiding_spot.id = buf:unpack( 'I' )
            hiding_spot.location = buf:unpack_vec()
            hiding_spot.flags = buf:unpack( 'b' )
            area.hiding_spots[i] = hiding_spot
        end

        -- encounter paths
        area.encounter_paths_count = buf:unpack( 'I' )
        area.encounter_paths = {}
        for i = 1, area.encounter_paths_count do
            local encounter_path = {}
            encounter_path.from_id, encounter_path.from_direction, encounter_path.to_id, encounter_path.to_direction, encounter_path.spots_count =
                buf:unpack( 'IBIBB' )

            encounter_path.spots = {}
            for i = 1, encounter_path.spots_count do
                encounter_path.spots[i] = {}
                encounter_path.spots[i].order_id, encounter_path.spots[i].distance = buf:unpack( 'IB' )
            end
            area.encounter_paths[i] = encounter_path
        end

        area.place_id = buf:unpack( 'H' )

        -- TF2 does not use ladders either
        -- ladders
        area.ladders = {}
        for i = 1, 2 do
            area.ladders[i] = {}
            area.ladders[i].connection_count = buf:unpack( 'I' )

            area.ladders[i].connections = {}
            for i = 1, area.ladders[i].connection_count do
                area.ladders[i].connections[i] = buf:unpack( 'I' )
            end
        end
        -- todo: work find L184 in CNAVFile.h
        area.earliest_occupy_time_first_team, area.earliest_occupy_time_second_team = buf:unpack( 'ff' )
        area.light_intensity_north_west, area.light_intensity_north_east, area.light_intensity_south_east, area.light_intensity_south_west =
            buf:unpack( 'ffff' )

        -- visible areas
        area.visible_areas = {}
        area.visible_area_count = buf:unpack( 'I' )
        for i = 1, area.visible_area_count do
            area.visible_areas[i] = {}
            area.visible_areas[i].id, area.visible_areas[i].attributes = buf:unpack( 'Ib' )
        end
        area.inherit_visibility_from_area_id = buf:unpack( 'I' )

        -- garbage?
        area.garbage_count = buf:unpack( 'b' )
        buf:seek( area.garbage_count * 14 )

        self.areas[i] = area
    end

    -- ladders
    self.ladders_count = buf:unpack( 'I' )
    self.ladders = {}
    for i = 1, self.ladders_count do
        local ladder = {}
        ladder.id, ladder.width = buf:unpack( 'If' )

        ladder.top = buf:unpack_vec()
        ladder.bottom = buf:unpack_vec()

        ladder.length, ladder.direction = buf:unpack( 'fI' )

        ladder.top_forward_area_id, ladder.top_left_area_id, ladder.top_right_area_id, ladder.top_behind_area_id = buf:unpack( 'IIII' )
        ladder.bottom_area_id = buf:unpack( 'I' )

        self.ladders[i] = ladder
    end

    -- Unknown 4 bytes
    self.unk = buf:Unpack( 'I' )

    return self
end

local struct = require 'struct'

local fs = io.open( engine.GetGameDir() .. '/../test.nav', 'r' )
local function readNav()
    local a = parse( fs:read( 'a' ) )
    printLuaTable( a )
end
readNav()
fs:flush()
fs:close()
