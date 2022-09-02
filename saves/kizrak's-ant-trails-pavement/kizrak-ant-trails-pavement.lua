-- Kizrak

local sb = serpent.block -- luacheck: ignore 211

log("kizrak-ant-trails-pavement.lua")


local ant_trails_pavement = {}

local on_player_changed_position = function(event)
	log('on_player_changed_position')
	log(sb(event))
	local player = game.players[event.player_index]
	
end

ant_trails_pavement.events =
{
	[defines.events.on_player_changed_position] = on_player_changed_position
}

ant_trails_pavement.on_configuration_changed = function()
	log("on_configuration_changed")
end

ant_trails_pavement.on_init = function()
	log("on_init")
end

-- script.on_event(defines.events.on_player_changed_position, on_player_changed_position)


return ant_trails_pavement
