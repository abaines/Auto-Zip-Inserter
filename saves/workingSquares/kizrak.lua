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
	--index2 = math.fmod(index,#infinity_chests_order)
	a = index-1
	b = #infinity_chests_order+0
	index2 = math.floor( a - math.floor(a/b)*b )+1
	
	thing = infinity_chests_order[index2]
	print( index .. ' ' .. index2 .. ' ' .. (thing or "!"))
	return thing
end

local function random_infinity_chests()
	if not global.infinity_chests_spawned then
		global.infinity_chests_spawned = {}
	end

	--[[
	local math_random = math.random
	local x = math_random(1, #infinity_chests_order)
	local thing = infinity_chests_order[x]
	game.print('thing:'..(thing))
	]]--
	
	print("#infinity_chests_order "..#infinity_chests_order)
	
	for i=1,33,1 do
		infinity_chest(i)
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
