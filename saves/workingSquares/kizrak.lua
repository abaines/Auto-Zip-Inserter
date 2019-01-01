-- Kizrak

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

commands.add_command("speed", "Set game speed", setSpeed)

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
