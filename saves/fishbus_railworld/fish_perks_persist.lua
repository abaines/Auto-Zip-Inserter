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


	fish_perks_persist.lua

FishBus Perks Persistence module.

Uses keystore concept to store user data.

--]]

require 'lib/event_extend'
require 'lib/fb_util' -- for arr_contains & player lookup

require 'fish_perks'

FishPerksPersist = {}

function FishPerksPersist.init(event)
	if not global.fppersist then
		global.fppersist = {
			debug = false,
			players = {},
		}
	end
	if not remote.interfaces['keystore'] then
		error("Unable to initialize Perk Persistence, keystore module not loaded.")
	end
end

function FishPerksPersist.getPlayer(index)
	if not global.fppersist.players[index] then
		global.fppersist.players[index] = {
			save_tick = game.tick - ticksPerMin(1),
			loaded = false, -- This should be set to true fairly quickly.
			fetched = false, -- Set to true after results are found.
		}
	end
	return global.fppersist.players[index]
end

function FishPerksPersist.join(event)
	-- load data from keystore
	local plPersist = FishPerksPersist.getPlayer(event.player_index)
	local player = game.players[event.player_index]
	plPersist.loaded = true
	plPersist.fetched = false
	local player = game.players[event.player_index]
	remote.call('keystore', 'get', 'perks.player', player.name, FishPerksPersist.loadPlayerData, true)
	player.print({'fish_perks.persist.fetching'})
end

function FishPerksPersist.leave(event)
	-- save data to keystore
	FishPerksPersist.savePlayerData(event.player_index)
end

function FishPerksPersist.loadPlayerData(data)
	-- keystore result.
	if data.status and data.status == "success" then
		local playerName = data.field
		local player = getPlayerNamed(playerName)
		local oldstate = data.value
		player.print({'fish_perks.persist.loaded'})
		
		local plPlayer = FishPerksPersist.getPlayer(player.index)
		plPlayer.fetched = true
		-- replace state data...
		perkplayer = FishPerks.getPlayerByID(player.index)
		for name, perk in pairs(global.fbperks.defs) do
			if perk.enabled then
				if oldstate.experiences[perk.name] then
					FishPerks.setRawValue(perk.name, player.index, oldstate.experiences[perk.name].value)
				end
			end
		end
		local oldbonuses = oldstate.levels.selectable.bonuses
		for name, sperk in pairs(global.fbperks.defs.selectable.selectable_perks) do
			if oldbonuses[sperk.name] then
				for count = 1, oldbonuses[sperk.name].level do
					FishPerks.select_bonus(player.index, sperk.name, true)
				end
			end
		end
		perkplayer:set_track(oldstate.track_xp)
	elseif data.error then
		local playerName = data.field
		local player = getPlayerNamed(playerName)
		if player then
			if data.error == "key not found" and data.field then
				player.print({'fish_perks.persist.new'})
				local plPlayer = FishPerksPersist.getPlayer(player.index)
				plPlayer.fetched = true
			else
				player.print({'fish_perks.persist.load_error', serpent.line(data.error)})
			end
		end
	end
end

function FishPerksPersist.perk_update(event)
	-- save data to keystore (limit X times per Y ticks)
	-- once every minute.  
	local persist_data = FishPerksPersist.getPlayer(event.player_index)
	if event.tick - persist_data.save_tick > ticksPerMin(1) then
		FishPerksPersist.savePlayerData(event.player_index)
	end
end

function FishPerksPersist.savePlayerData(index)
	local plPersist = FishPerksPersist.getPlayer(index)
	-- only save if the data has been 'fetched'
	if plPersist.fetched then
		plPersist.save_tick = game.tick
		local player = game.players[index]
		local perkstate = global.fbperks.players[index].state
		remote.call('keystore', 'set', 'perks.player', player.name, perkstate, nil, true)
		if global.fppersist.debug then
			player.print({'fish_perks.persist.save'})
		end
	end
end

Event.register(Event.core_events.init, FishPerksPersist.init)
Event.register(Event.def("softmod_init"), FishPerksPersist.init)

Event.register(defines.events.on_player_joined_game, FishPerksPersist.join)
Event.register(defines.events.on_player_left_game, FishPerksPersist.leave)
Event.register(Event.def("perk_update"), FishPerksPersist.perk_update)
