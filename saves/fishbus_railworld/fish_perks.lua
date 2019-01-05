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


	fish_perks.lua

FishBus Perks.

As a group, we decided we like the perk concept for becoming more awesome at
the game, but it was a bit annoying for the perks to come from fish/currency
which could be mined.

So, we needed a new solution.  The best thing we could come up with was one
that gave you bonuses for doing things in the game, and the bonus would be
based on what you were doing.  So if you were mining, you would mine faster;
running would make you run faster, etc, etc.

I like the idea, but it seemed to me that it would be also useful to have some
sort of skill list that you could additionally choose from when being useful.

--]]

require 'lib/event_extend'
require 'lib/fb_util' -- for arr_contains & player lookup

require 'production-score' -- for production_score.generate_price_list()

require 'lib/event_health_regen'
require 'lib/player_distance'

local perk_defs = require 'fish_perks_definition'

FishPerks = {}

local function initMod(event)
	if not global.fbperks then
		global.fbperks = {
			players = {},
			price_list = {},
			defs = perk_defs,
		}
		FishPerks.regenPriceList()
	end
end

-- Core functionality for all perks.
function FishPerks.checkPromotion(perkname, player_index, newvalue, quiet)
	local perkplayer = FishPerks.getPlayerByID(player_index)
	local player = game.players[player_index]
	if not player.character then
		-- for most things, we cannot check or upgrade players who are dead
		-- or in non-corporeal state.
		return
	end
	local perkdef = global.fbperks.defs[perkname]
	local curlevel = math.floor(newvalue / perkdef.base_units_per_level)
	local pplevel = perkplayer:level(perkname)
	local leveldelta = 0
	local curbonus = 0
	if pplevel.value < curlevel and pplevel.value < perkdef.max_level then
		leveldelta = math.min(curlevel, perkdef.max_level) - pplevel.value
		pplevel.value = math.min(curlevel, perkdef.max_level)
		if type(perkdef.perk) == "string" then
			local perkValue = game.players[player_index][perkdef.perk]
			game.players[player_index][perkdef.perk] = perkValue + (perkdef.increase * leveldelta)
			curbonus = game.players[player_index][perkdef.perk]
		end
		if type(perkdef.perk) == "table" then
			for _, perkname in ipairs(perkdef.perk) do
				local perkValue = game.players[player_index][perkname]
				game.players[player_index][perkname] = perkValue + (perkdef.increase * leveldelta)
			end
		end
		if not quiet then
			local toNextLevel = math.min(curlevel+1,perkdef.max_level) * perkdef.base_units_per_level - newvalue
			player.print({
				"fish_perks.levelup."..perkdef.name, 
				pplevel.value, -- current level
				curbonus, -- current bonus
			})
			if toNextLevel > 0 then
				player.print({
					"fish_perks.nextlevel."..perkdef.name,
					math.ceil(toNextLevel),
				})
			else
				player.print({
					"fish_perks.levelup.max_level",
				})
			end
		end
	end
	return leveldelta
end

function FishPerks.getPlayerByID(index)
	local rpgplayer = global.fbperks.players[index]
	if not rpgplayer then
		-- create shell of player.
		rpgplayer = {
			state = {
				idx = index,
				experiences = {},
				levels = {},
				track_xp = nil,
			},
			lastvalues = {},
		}
		global.fbperks.players[index] = rpgplayer
		rpgplayer.__index = rpgplayer
		function rpgplayer:xp(name)
			if not self.state.experiences[name] then
				self.state.experiences[name] = { value = 0 }
			end
			return self.state.experiences[name]
		end
		function rpgplayer:percent(name)
			local cur = self:xp(name).value
			local lev = self:level(name).value
			local perlev = global.fbperks.defs[name].base_units_per_level
			local in_lev = cur - (lev*perlev)
			--local nextlev = (lev+1) * perlev
			return math.min(in_lev / perlev, 1)
		end
		function rpgplayer:level(name)
			if not self.state.levels[name] then
				self.state.levels[name] = { value = 0 }
			end
			return self.state.levels[name]
		end
		function rpgplayer:selected_perk_count()
			local lvl = self:level('selectable')
			if not lvl.bonuses then lvl.bonuses = {} end
			local count = 0
			for name, perkdata in pairs(lvl.bonuses) do
				count = count + perkdata.level
			end
			return count
		end
		function rpgplayer:get_track()
			return self.state.track_xp
		end
		function rpgplayer:set_track(name)
			self.state.track_xp = name
		end
		function rpgplayer:valueDiff(perk, value)
			if not self.lastvalues[perk] then
				self.lastvalues[perk] = 0
			end
			local diff = value - self.lastvalues[perk]
			self.lastvalues[perk] = value
			return diff
		end
	end
	return rpgplayer
end

function FishPerks.getPlayerByName(name)
	local pl = getPlayerNamed(name)
	return FishPerks.getPlayerByID(pl.index)
end

function FishPerks.increaseValue(perk, player_index, value)
	local perkplayer = FishPerks.getPlayerByID(player_index)
	local xp = perkplayer:xp(perk)
	if value ~= 0 then
		-- increase selectable perk value based on diff...
		if perk ~= "selectable" then
			local diff = value / global.fbperks.defs[perk].base_units_per_level * 100
			diff = diff * global.fbperks.defs.selectable.rate
			FishPerks.increaseValue('selectable', player_index, diff)
		end
		xp.value = xp.value + value
		return FishPerks.checkPromotion(perk, player_index, xp.value)
	end
	return 0
end

function FishPerks.join(event)
	-- player joined into game, init their Perks data.
	local rpgplayer = FishPerks.getPlayerByID(event.player_index)
end

function FishPerks.regenPriceList()
	global.fbperks.price_list = production_score.generate_price_list()
end

function FishPerks.setRawValue(perk, player_index, value)
	local perkplayer = FishPerks.getPlayerByID(player_index)
	local xp = perkplayer:xp(perk)
	xp.value = value
	return FishPerks.checkPromotion(perk, player_index, xp.value, true)
end

function FishPerks.setValue(perk, player_index, value)
	local perkplayer = FishPerks.getPlayerByID(player_index)
	-- increase selectable perk value based on diff...
	local diff = perkplayer:valueDiff(perk, value)
	if diff ~= 0 then
		return FishPerks.increaseValue(perk, player_index, diff)
	end
	return 0
end

function FishPerks.select_bonus(player_index, bonusname, quiet)
	local bonus = global.fbperks.defs.selectable.selectable_perks[bonusname]
	if not bonus then game.print("DEBUG: bonus '"..bonusname.."' not found.") return end
	local perkplayer = FishPerks.getPlayerByID(player_index)
	local player = game.players[player_index]
	local lvldata = perkplayer:level('selectable')
	if lvldata.value > perkplayer:selected_perk_count() then
		if not lvldata.bonuses[bonusname] then
			lvldata.bonuses[bonusname] = { level = 0 }
		end
		if lvldata.bonuses[bonusname].level < bonus.max_level then
			-- we can apply a bonus point here.
			if not quiet then
				player.print({'fish_perks.levelup.apply_selectable', {'fish_perks.gui.select.'..bonusname}})
			end
			lvldata.bonuses[bonusname].level = lvldata.bonuses[bonusname].level + 1
			if bonus.perk then
				player[bonus.perk] = player[bonus.perk] + bonus.per_level
			end
		end
	end
	if not quiet then
		FishPerks.updateEvent('selectable', player_index)
	end
end

function FishPerks.updateEvent(perkname, player_index)
	Event.dispatch({
		name=Event.def("perk_update"),
		tick=game.tick,
		perk=perkname,
		player_index = player_index,
	})
end

--
-- Individual perk functionality
--

function FishPerks.crafted_item(event)
	if not global.fbperks.defs['handcrafted'].enabled then
		return
	end
	local prodcost = global.fbperks.price_list[event.item_stack.name]
	if not prodcost then
		-- If it failed, then it probably means someone added a mod during
		-- the game (eg, added between saves).  So let's regen the list.
		FishPerks.regenPriceList()
		prodcost = global.fbperks.price_list[event.item_stack.name]
	end
	prodcost = prodcost * event.item_stack.count
	FishPerks.increaseValue('handcrafted', event.player_index, prodcost)
	FishPerks.updateEvent('handcrafted', event.player_index)
end

function FishPerks.health_regen(event)
	if not global.fbperks.defs['healed'].enabled then
		return
	end
	--local player = game.players[event.player_index]
	--game.print("DEBUG: Regen " .. player.name .. " gained " .. event.generated .. " health")
	local ret = FishPerks.increaseValue('healed', event.player_index, event.generated)
	if ret > 0 then
		-- level up occurred.  Increase their health by the level diff.
		local healthdiff = ret * global.fbperks.defs['healed'].increase
		healthregen_add_health_without_event(event.player_index, healthdiff)
	end
	FishPerks.updateEvent('healed', event.player_index)
end

function FishPerks.mined_item(event)
	if not global.fbperks.defs['mined'].enabled then
		return
	end
	local check_types = {'resource', 'tree'}
	local check_names = {
		['rock-huge']=25, ['rock-big']=20, ['rock-medium']=15, ['rock-small']=10,
		['rock-tiny']=5, 
		['sand-rock-big']=20, ['sand-rock-medium']=15, ['sand-rock-small']=10,
	}
	local value = 0
	if arr_contains(check_types, event.entity.type) then
		value = (
			global.fbperks.price_list[event.entity.name] or 
			(global.fbperks.price_list['raw-wood'] * 2)
		)
	end
	if check_names[event.entity.name] then
		value = check_names[event.entity.name] * global.fbperks.price_list['stone']
	end
	if value > 0 then
		FishPerks.increaseValue('mined', event.player_index, value)
		FishPerks.updateEvent('mined', event.player_index)
	end
end

function FishPerks.placed_item(event)
	if not global.fbperks.defs['placed'].enabled then
		return
	end
	if event.created_entity and event.created_entity.valid then
		if event.created_entity.type == "entity-ghost" then
			-- ghosts don't count!
			return
		end
	end
	-- Just improve per item....
	FishPerks.increaseValue('placed', event.player_index, 1)
	FishPerks.updateEvent('placed', event.player_index)
end

function FishPerks.reapplyPerks(event)
	-- quietly apply the perks to a player.
	-- This is done when players respawn, to put their entries back.
	local perkplayer = FishPerks.getPlayerByID(event.player_index)
	local player = game.players[event.player_index]
	for name, perk in pairs(global.fbperks.defs) do
		if perk.enabled then
			local leveldelta = perkplayer:level(perk.name).value
			if type(perk.perk) == "string" then
				player[perk.perk] = perk.increase * leveldelta
			end
			if type(perk.perk) == "table" then
				for _, perkname in ipairs(perk.perk) do
					player[perkname] = perk.increase * leveldelta
				end
			end
		end
	end
	local existbonus = perkplayer:level('selectable').bonuses
	if existbonus then
		for name, sperk in pairs(global.fbperks.defs.selectable.selectable_perks) do
			if existbonus[sperk.name] then
				player[sperk.perk] = existbonus[sperk.name].level + sperk.per_level
			end
		end
	end
end

function FishPerks.travelled(event)
	-- interest in walked distance.
	if global.fbperks.defs['walked'].enabled then
		local distance = remote.call('pdistance', 'walked', event.player_index)
		--player.print("DEBUG: Travel: Distance: " .. distance)
		local newvalue = FishPerks.setValue('walked', event.player_index, distance)
		FishPerks.updateEvent('walked', event.player_index)
	end

	-- interest in distance driven...
	if global.fbperks.defs['driven'].enabled then
		-- Can't implement with current design, as it's a value that would need
		-- to be set every time you jump into a vehicle.
		--distance = remote.call('pdistance', 'driven', event.player_index)
		--player.print("DEBUG: Travel: Driven Distance: " .. distance)
		--newvalue = FishPerks.setValue('driven', event.player_index, distance)
		FishPerks.updateEvent('driven', event.player_index)
	end
end

Event.register(Event.core_events.init, initMod)
Event.register(Event.def("softmod_init"), initMod)

Event.register(defines.events.on_player_joined_game, FishPerks.join)

Event.register(defines.events.on_player_built_tile, FishPerks.placed_item)
Event.register(defines.events.on_built_entity, FishPerks.placed_item)
Event.register(defines.events.on_player_crafted_item, FishPerks.crafted_item)
Event.register(defines.events.on_pre_player_mined_item, FishPerks.mined_item)
Event.register(Event.def("player_distance_update"), FishPerks.travelled)
Event.register(Event.def("player_health_regen"), FishPerks.health_regen)

Event.register(defines.events.on_player_respawned, FishPerks.reapplyPerks)
