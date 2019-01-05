--[[
Copyright 2017-2018 "Kovus" <kovus@soulless.wtf>

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	flashlight_off.lua - Softmod to disable player flashlights
	
--]]

fl = {}

function fl.init()
	if not global.flashlight_init then
		global.flashlight_init = true
		global.flashlight = false
		global.flashlight_enable_on_battery = true
	end
end

function fl.setFlashlight(player)
	if player.character and player.character.valid then
		if player.vehicle then
			player.character.enable_flashlight()
		else
			if fl.isEnabled() then
				player.character.enable_flashlight()
			else
				player.character.disable_flashlight()
			end
		end
	end
end

function fl.disableFlashlights()
	global.flashlight = false
	-- only need to iterate through connected players, as this state will be
	-- (re)set upon a player joining.
	for idx, player in pairs(game.connected_players) do
		if player.character and player.character.valid then
			player.character.disable_flashlight()
		end
	end
end

function fl.enableFlashlights()
	global.flashlight = true
	-- only need to iterate through connected players, as this state will be
	-- (re)set upon a player joining.
	for idx, player in pairs(game.connected_players) do
		if player.character and player.character.valid then
			player.character.enable_flashlight()
		end
	end
end

function fl.researchFinished(event)
	if global.flashlight_enable_on_battery then
		if event.research.name == 'battery' then
			game.print({'flashlight.auto_enable_msg'})
			fl.enableFlashlights()
		end
	end
end

function fl.isEnabled()
	return global.flashlight
end

function fl.playerEvent(event)
	fl.setFlashlight(game.players[event.player_index])
end

remote.add_interface("flashlight", {
	disable = fl.disableFlashlights,
	enable = fl.enableFlashlights,
	is_enabled = fl.isEnabled,
})

if Event then
	-- typically, this is part of a softmod pack, so let's just assume we got
	-- dropped into an existing save, and init on first player join/create
	Event.register(defines.events.on_player_joined_game, fl.init)
	Event.register(defines.events.on_player_created, fl.init)
	Event.register(defines.events.on_player_joined_game, fl.playerEvent)
	Event.register(defines.events.on_player_respawned, fl.playerEvent)
	Event.register(defines.events.on_player_driving_changed_state, fl.playerEvent)
	Event.register(defines.events.on_research_finished, fl.researchFinished)
else
	script.on_init(fl.init)
	script.on_event(defines.events.on_player_joined_game, fl.playerEvent)
	script.on_event(defines.events.on_player_respawned, fl.playerEvent)
	script.on_event(defines.events.on_player_driving_changed_state, fl.playerEvent)
	script.on_event(defines.events.on_research_finished, fl.researchFinished)
end
