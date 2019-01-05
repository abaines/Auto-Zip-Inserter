-- Show the health of a player as a small piece of colored text above their head
-- A 3Ra Gaming creation

-- Modified for FishBus Gaming
-- Added a player button to disable show-health on "my player."
-- Currently still displays other people's health even if disabled for "me."

require 'lib/event_extend'

if not global.show_health_settings then
	global.show_health_settings = {}
end

local function showhealth (event)
	if game.tick % 30 ~= 0 then return end
	for k, player in pairs(game.connected_players) do
		if global.show_health_settings[player.name].show then
			if player.character then
				if player.character.health == nil then return end
				local index = player.index
				local health = math.ceil(player.character.health)
				if global.player_health == nil then
					global.player_health = {}
				end
				if global.player_health[index] == nil then
					global.player_health[index] = health
				end
				if global.player_health[index] ~= health then
					global.player_health[index] = health
					if health < 250 then
						if health > 125 then
							player.surface.create_entity { name = "flying-text", color = { b = 0.2, r = 0.1, g = 1, a = 0.8 }, text = (health), position = { player.position.x, player.position.y - 2 } }
						elseif health > 74 then
							player.surface.create_entity { name = "flying-text", color = { r = 1, g = 1, b = 0 }, text = (health), position = { player.position.x, player.position.y - 2 } }
						else
							player.surface.create_entity { name = "flying-text", color = { b = 0.1, r = 1, g = 0, a = 0.8 }, text = (health), position = { player.position.x, player.position.y - 2 } }
						end
					end
				end
			end
		end
	end
end

local function drawShowHealthButton(player)
	local frame = mod_gui.get_button_flow(player)
	if not frame.btn_toolbar_showHealth then
		fbgui.createButton(frame, "btn_toolbar_showHealth", "Health", "Show/hide a floating health value for your player when damaged.")
	end
end
fbgui.connectButton("btn_toolbar_showHealth", function(player, event)
	global.show_health_settings[player.name].show = not global.show_health_settings[player.name].show
	if global.show_health_settings[player.name].show then
		player.print("[Health] Showing floating health.")
	else
		player.print("[Health] No longer showing floating health.")
	end
end)

Event.register(defines.events.on_tick, showhealth)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	if not global.show_health_settings[player.name] then
		global.show_health_settings[player.name] = {["show"] = true}
	end
	drawShowHealthButton(player)
end)
