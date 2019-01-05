-- Kizrak

local Kizrak = {}

local json = require 'utils.json'
local Event = require 'utils.event'

local function on_player_changed_position(event)
	local player = game.players[event.player_index]

	--player.print("Kizrak was here", {r = 255, g = 102, b = 0})
end

local function setSpeed(event)
	parsedSpeed = tonumber(event.parameter)
	game.speed = parsedSpeed
	game.print("Set game speed to " .. parsedSpeed)
end

local function print(message, color)
	if not color then color={r = 1, g = 1, b = 1} end
	game.print(message, color)
end



local infinity_chests_order = {
	"iron-ore",
	"copper-ore",
	"stone",
	"wood",
	"iron-plate",
	"copper-plate",
	"stone-brick",
	"iron-gear-wheel",
	"copper-cable",
	-- Green sci
	"transport-belt",
	"electronic-circuit",
	"inserter",
	"coal",
	-- Blue Sci
	"firearm-magazine",
	"shotgun-shell",
	"plastic-bar",
	"advanced-circuit",
	"grenade",
	"steel-plate",
	"piercing-rounds-magazine",
	"piercing-shotgun-shell",
	"rail",
	"pipe",
	"engine-unit",
	"gun-turret",
	"electric-mining-drill",
	"uranium-ore",
	"radar",
	"solid-fuel",
	"flamethrower-ammo",
	"cannon-shell",
	"explosives",
	"rocket",
	"defender-capsule",
	-- Purple Sci
	"electric-engine-unit",
	"electric-furnace",
	-- "Rocket Fuel"
	"explosive-cannon-shell",
	"rocket-fuel",
	-- Yellow Sci
	"sulfur",
	"battery",
	"nuclear-fuel",
	"processing-unit",
	"speed-module",
	-- "Robots"
	"low-density-structure",
	"productivity-module",
	"flying-robot-frame",
	"landfill",
	-- anything used to make science
	-- rail?
}

local function infinity_chest(index)
	local a = index-1
	local b = #infinity_chests_order
	local index2 = math.floor( a - math.floor(a/b)*b )+1
	
	local chest = infinity_chests_order[index2] or nil
	--print( index .. ' ' .. index2 .. ' ' .. chest)
	return chest
end

local bag_size = 3

local function short_list_of_chests()
	if not global.infinity_chests_spawned then
		global.infinity_chests_spawned = {}
	end

	function clone(t) -- deep-copy a table
		-- https://gist.github.com/MihailJP/3931841
		if type(t) ~= "table" then return t end
		
		local meta = getmetatable(t)
		local target = {}

		for k, v in pairs(t) do
			if type(v) == "table" then
				target[k] = clone(v)
			else
				target[k] = v
			end
		end
		setmetatable(target, meta)
		return target
	end
	
	local function index_of(tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return index
			end
		end
	end
	
	copySpawned = clone(global.infinity_chests_spawned)


	index = 1
	short_list = {}

	while true do
		chest_i = infinity_chest(index)
		
		local search_index = index_of(copySpawned,chest_i)
		
		if search_index then
			--print('already have : '..chest_i..' @ '..search_index)
			table.remove(copySpawned, search_index)
		else
			--print('adding : '..chest_i)
			table.insert(short_list,chest_i)
			if #short_list>=bag_size then
				return short_list
			end
		end
		
		if index>1000 then
			error()
		end
		
		index = 1 + index
	end

end

function Kizrak.random_infinity_chest()
	short_list = short_list_of_chests()
	--print(json.stringify(short_list_of_chests()))
	
	r = math.random(#short_list)
	--print("random : " .. r)
	
	--print(short_list[r])
	
	chest = short_list[r]
	
	table.insert(global.infinity_chests_spawned,chest)
	
	return chest
	--table.insert(global.infinity_chests_spawned, thing)
end


local function _next(event)
	local player = game.players[event.player_index]
	
	player.print("version : " .. "0.0.0.3")
	
	player.print(json.stringify(global.infinity_chests_spawned),{b=255})
	
	short_list = short_list_of_chests()
	
	player.print(json.stringify(short_list),{g=255})
	
	game.write_file("global.json",json.stringify(global))
end

commands.add_command("speed", "Set game speed", setSpeed)

commands.add_command("next", "next",_next)

Event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Kizrak
