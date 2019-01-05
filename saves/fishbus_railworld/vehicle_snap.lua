-- Vehicle Snap.

-- Derived from:
-- https://mods.factorio.com/mods/Zaflis/VehicleSnap

-- License: MIT.

-- snap amount is the amount of different angles car can drive on, 
-- (360 / vehiclesnap_amount) is the difference between 2 axis
-- car will slowly turn towards such angle axis
local vehiclesnap_amount = 16.0

vs = {}

function vs.init()
	if not global.vsnap then
		global.vsnap = {
			lastorientation = {},
			player_ticks = {},
			tick = 2,
			driving_players = {},
			enabled_for = {},
		}
	end
	kw_connectButton("btn_toolbar_vehiclesnap", vs.toggleForPlayer)
end

function vs.toggleForPlayer(event)
	local player = game.players[event.player_index]
	global.vsnap.enabled_for[player.index] = not global.vsnap.enabled_for[player.index]
	if global.vsnap.enabled_for[player.index] then
		player.print({'vsnap.enabled'})
	else
		player.print({'vsnap.disabled'})
	end
end

Event.register(Event.core_events.init, vs.init)
Event.register(Event.def("softmod_init"), vs.init)

Event.register(defines.events.on_player_created, function(event)
	local player = game.players[event.player_index]
	global.vsnap.enabled_for[player.index] = true
end)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	kw_newToolbarButton(player, "btn_toolbar_vehiclesnap", {'vsnap.buttonname'}, {'vsnap.button_tooltip'}, 'entity/tank', nil)
end)

Event.register(defines.events.on_tick, function(event)
    global.vsnap.tick = global.vsnap.tick - 1
    if global.vsnap.tick == 0 then
		-- If noone is in vehicles, take longer delay to do this whole check
		global.vsnap.tick = 40
		for _, player in pairs(game.connected_players) do
			if player.vehicle and player.vehicle.valid and global.vsnap.enabled_for[player.index] then
				local v = player.vehicle.type
				if v == "car" or v == "tank" then
					local index = player.index
					global.vsnap.tick = 2
					if player.vehicle.speed > 0.1 then
						local o = player.vehicle.orientation
						if global.vsnap.lastorientation[index] == nil then global.vsnap.lastorientation[index] = 0 end
						if global.vsnap.player_ticks[index] == nil then global.vsnap.player_ticks[index] = 0 end
						if math.abs(o - global.vsnap.lastorientation[index]) < 0.001 then
							if global.vsnap.player_ticks[index] > 1 then
								local o2 = math.floor(o * vehiclesnap_amount + 0.5) / vehiclesnap_amount
								o = (o * 4.0 + o2) * 0.2
								player.vehicle.orientation = o
							else
								global.vsnap.player_ticks[index] = global.vsnap.player_ticks[index] + 1
							end
						else
							global.vsnap.player_ticks[index] = 0
						end
						global.vsnap.lastorientation[index] = o;
					end
				end
			end
		end
    end
end)

