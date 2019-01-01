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



local infinity_chests_order = {
	"iron-ore",
	"copper-ore",
	"stone",
	"raw-wood",
	"coal",
	"coal",
	"stone",
	"stone",
	"iron-ore",
	"iron-ore",
	"iron-ore",
	"copper-ore",
	"copper-ore",
	"iron-plate",
	"copper-plate",
	"stone-brick",
	"iron-gear-wheel",
	"copper-cable"
}

local function random_infinity_chests()
	if not global.infinity_chests_spawned then
		global.infinity_chests_spawned = {}
	end

	local math_random = math.random
	local x = math_random(1, #infinity_chests_order)
	local thing = infinity_chests_order[x]
	game.print('thing:'..(thing))
	
	table.insert(global.infinity_chests_spawned, thing)
end


local function playground(event)
	game.print("play")
	
	--game.print(json.stringify(infinity_chests_order))
	
	random_infinity_chests()
	
	game.print("json:" .. json.stringify(global.infinity_chests_spawned))
	
	game.write_file("global.json",json.stringify(global))
end

commands.add_command("speed", "Set game speed", setSpeed)

commands.add_command("play", "Playground",playground)

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
