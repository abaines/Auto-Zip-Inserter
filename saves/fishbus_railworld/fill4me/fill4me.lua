--[[
Copyright 2018 "Kovus" <kovus@soulless.wtf>

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

	Fill4Me.lua

Fill4Me is a script to place fuel & ammo into entities when you place them.

Inspired by AutoFill, but disappointed by the newer version of AutoFill, I set
out to create a replacement.  The functionality of AutoFill(v1) was great for
vanilla, but suffered when given mods.  It also required manual updates in the
event that new entities were added.  Fill4Me's goals (through a complete rewrite)
include:
- performing fuel/ammo filling of entities upon placement;
- learning and discarding entity data as mods change (or when told);
- being able to be turned on/off per-player (though, most love it); and
- being easy to maintain.

--]]

require 'stdlib/event/event'
require 'lib/event_extend'

require 'fill4me/ammo'
require 'fill4me/fuel'
require 'fill4me/loadable_entities'

-- production score is used in lieu of being able to evaluate the damage of
-- smoke-based entities/items.  There is a failing in the code exposed to lua
-- which prevents being able to identify the base damage of things like 
-- poison-capsule (item) / poison-cloud (entity)
require 'production-score' -- for production_score.generate_price_list()

fill4me = {}

function fill4me.initMod(event)
	if not global.fill4me then
		global.fill4me = {
			initialized = false,
			fuels = {},
			ammos = {},
			loadable_entities = {},
			players = {},
		}
	end
	if not global.fill4me.initialized then
		fill4me.evaluate_items()
		fill4me.evaluate_entities()
		global.fill4me.initialized = true
	end
end
function fill4me.reInitMod(event)
	if global.fill4me then
		global.fill4me.initialized = false
	end
	fill4me.initMod(event)
end

-- Entity built by player.  Evaluate for inserting fuel & ammo.
function fill4me.built_entity(event)
	local pldata = fill4me.player(event.player_index)
	if pldata.enable and event.created_entity.valid then
		pldata.ft_offset = 0
		local entity = event.created_entity
		local lent = fill4me.for_player(pldata, "loadable_entities")[entity.name]
		if lent then
			if lent.fuel_categories then
				fill4me.load_fuel(entity, lent, event.player_index)
			end
			if lent.guns or lent.ammo_category then
				fill4me.load_ammo(entity, lent, event.player_index)
			end
		end
	end
end

-- Scan through entities, finding those that take fuel & ammo.
function fill4me.evaluate_entities()
	global.fill4me.loadable_entities = {}
	local lent = global.fill4me.loadable_entities
	for _, entdata in pairs(LoadEnts.list_of_fireables()) do
		lent[entdata.name] = table.merge(lent[entdata.name] or {}, entdata)
	end
	for _, entdata in pairs(LoadEnts.list_of_fuelables()) do
		lent[entdata.name] = table.merge(lent[entdata.name] or {}, entdata)
	end
end

-- Scan through items, finding fuels & ammos
function fill4me.evaluate_items()
	global.fill4me.fuels = {}
	global.fill4me.ammos = {}
	
	-- evaluate fuel items
	local fuels = global.fill4me.fuels
	local fcategories = Fuel.categories()
	for idx, name in pairs(fcategories) do
		fuels[name] = {}
	end
	for idx, fuel in pairs(Fuel.list()) do
		table.insert(fuels[fuel.category], fuel)
	end
	for idx, fuellist in pairs(fuels) do
		table.sort(fuellist, fill4me.fuel_sort_high)
	end
	
	-- evaluate ammunition items
	local ammos = global.fill4me.ammos
	for idx, name in pairs(Ammo.categories()) do
		ammos[name] = {}
	end
	for idx, ammo in pairs(Ammo.list()) do
		table.insert(ammos[ammo.category], ammo)
	end
	for name, itemlist in pairs(ammos) do
		table.sort(itemlist, fill4me.item_dmg_sort_high)
	end
end

function fill4me.fuel_sort_high(a, b)
	return a.value > b.value
end

function fill4me.getFromInventory(player, item_name, max_size)
	local pldata = fill4me.player(player.index)
	local amount_to_get = math.min(max_size, pldata.max_load)
	local inventory = player.get_inventory(defines.inventory.player_main)
	local available = inventory.get_item_count(item_name)
	removed = 0
	if available > 0 then
		removed = math.min(amount_to_get, math.ceil(available*pldata.max_load_percent))
		inventory.remove({name=item_name, count=removed})
	end
	return removed
end

function fill4me.item_dmg_sort_high(a, b)
	if a.damage == b.damage then
		return a.craft_value > b.craft_value
	end
	return a.damage > b.damage
end

function fill4me.load_ammo(entity, lent, plidx)
	local player = game.players[plidx]
	local proto = game.entity_prototypes[entity.name]
	if lent.ammo_category then
		for _, ammo in pairs(fill4me.for_player(plidx, "ammos")[lent.ammo_category]) do
			if proto.attack_parameters and proto.attack_parameters.min_range < ammo.radius then
				-- don't check this one.
			else
				local count = fill4me.getFromInventory(player, ammo.name, ammo.max_size)
				if count > 0 then
					local loaded = fill4me.loadAmmoInto(entity, ammo.name, count)
					if loaded > 0 then
						fill4me.textRemove(player, entity, ammo.i18n, loaded)
					end
					if loaded < count then
						fill4me.loadInto(player, ammo.name, count - loaded)
					end
					break
				end
			end
		end
	end
	if lent.guns then
		for _, gun in pairs(lent.guns) do
			for _, ammo in pairs(fill4me.for_player(plidx, "ammos")[gun.ammo_category]) do
				local count = fill4me.getFromInventory(player, ammo.name, ammo.max_size)
				if count > 0 then
					local loaded = fill4me.loadAmmoInto(entity, ammo.name, count)
					if loaded > 0 then
						fill4me.textRemove(player, entity, ammo.i18n, loaded)
					end
					if loaded < count then
						fill4me.loadInto(player, ammo.name, count - loaded)
					end
					break
				end
			end
		end
	end
end

function fill4me.load_fuel(entity, lent, plidx)
	-- Load fuel from player's inventory into the entity.
	local player = game.players[plidx]
	local found_fuel = false
	for name, t in pairs(lent.fuel_categories) do
		for _, fuel in pairs(fill4me.for_player(plidx, "fuels")[name]) do
			local count = fill4me.getFromInventory(player, fuel.name, fuel.max_size)
			if count > 0 then
				loaded = fill4me.loadFuelInto(entity, fuel.name, count)
				if loaded > 0 then
					fill4me.textRemove(player, entity, fuel.i18n, loaded)
				end
				if loaded < count then
					fill4me.loadInto(player, fuel.name, count - loaded)
				end
				found_fuel = true
				break
			end
		end
		if found_fuel then
			break
		end
	end
end

function fill4me.loadAmmoInto(entity, item_name, quantity)
	-- try both car & turret inventories.
	local inv = entity.get_inventory(defines.inventory.car_ammo)
	local itemstack = { name = item_name, count = quantity }
	if not (inv and inv.valid) then
		inv = entity.get_inventory(defines.inventory.turret_ammo)
	end
	if inv and inv.valid and inv.can_insert(itemstack) then
		return inv.insert(itemstack)
	end
	return 0
end

function fill4me.loadFuelInto(entity, item_name, quantity)
	local inv = entity.get_inventory(defines.inventory.fuel)
	local itemstack = { name = item_name, count = quantity }
	if inv and inv.valid and inv.can_insert(itemstack) then
		return inv.insert(itemstack)
	end
	return 0
end

function fill4me.loadInto(entity, item_name, quantity)
	local itemstack = { name = item_name, count = quantity }
	return entity.insert(itemstack)
end

function fill4me.player(plidx)
	if not global.fill4me.players[plidx] then
		global.fill4me.players[plidx] = {
			enable = true,
			max_load = 25,
			max_load_percent = 0.12,
			loadable_entities = nil,
			fuels = nil,
			ammos = nil,
		}
	end
	return global.fill4me.players[plidx]
end

function fill4me.for_player(player, section)
	-- get the relevent player data for ammo, fuel, etc, or global version.
	local f4m_player = nil
	if type(player) == "number" then
		f4m_player = fill4me.player(player)
	elseif type(player) == "table" then
		if player.online_time then -- factorio player object.  get f4m player.
			f4m_player = fill4me.player(player.index)
		elseif player.max_load then -- f4m player.  check some field.
			f4m_player = player
		end
	end
	if f4m_player then
		if f4m_player[section] and type(f4m_player[section]) == "table" then
			return f4m_player[section]
		end
		return global.fill4me[section]
	end
end

function fill4me.script_built_entity(event)
	if event.created_entity and event.player_index then
		-- Work around scripts which dispatch a script event and THEN
		-- insert fuel/ammo into the entity of interest.
		Event.on_next_tick(fill4me.built_entity, event)
	end
end

function fill4me.textRemove(player, entity, item_name, quantity, color)
	local pos = entity.position
	local pldata = fill4me.player(player.index)
	pos.x = pos.x + 1
	pos.y = pos.y + pldata.ft_offset
	textcolor = {r=1, g=1, b=1, a=1}
	if color then
		textcolor = color
	end
	player.surface.create_entity({ 
		name = "flying-text",
		color = textcolor,
		position = pos,
		text = {'fill4me.removed', quantity, item_name},
	})
	pldata.ft_offset = pldata.ft_offset + 1
end

function fill4me.toggle(plidx)
	local pldata = fill4me.player(plidx)
	local player = game.players[plidx]
	pldata.enable = not pldata.enable
	
	if pldata.enable then
		player.print({'fill4me.prefix', {'fill4me.enabled'} })
	else
		player.print({'fill4me.prefix', {'fill4me.disabled'}})
	end
end

Event.register(Event.core_events.configuration_changed, fill4me.reInitMod)
Event.register(Event.def("softmod_init"), fill4me.initMod)
Event.register(defines.events.on_built_entity, fill4me.built_entity)
Event.register(defines.events.script_raised_built, fill4me.script_built_entity)
