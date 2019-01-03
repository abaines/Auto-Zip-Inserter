-- Kizrak

local json = require 'utils.json'
local Event = require 'utils.event'

local function on_player_changed_position(event)
	local player = game.players[event.player_index]

	player.print("Kizrak was here", {r = 255, g = 102, b = 0})
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
	"raw-wood",
	"coal",
	"iron-plate",
	"copper-plate",
	"stone-brick",
	"iron-gear-wheel",
	"copper-cable"
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

local function random_infinity_chests()
	if not global.infinity_chests_spawned then
		global.infinity_chests_spawned = {}
	end

	print("#infinity_chests_order "..#infinity_chests_order)
	
	for i=1,22,1 do
		game.print(i.. '='..infinity_chest(i) )
	end
	
	table.insert(global.infinity_chests_spawned, thing)
end


local function playground(event)
	game.print("play")
	
	--game.print(json.stringify(infinity_chests_order))
	
	random_infinity_chests()
	
	--game.print("json:" .. json.stringify(global.infinity_chests_spawned))
	
	game.write_file("global.json",json.stringify(global))
end

commands.add_command("speed", "Set game speed", setSpeed)

commands.add_command("play", "Playground",playground)

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
