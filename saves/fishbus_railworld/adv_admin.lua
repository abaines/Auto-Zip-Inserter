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

	advadmin_gui.lua - FishBus Advanced Admin GUI
	
	Inspired by ExplosiveGaming's Admin GUI
	
	Designed to handle the needs of the server owner.
	
--]]


require 'lib/event_extend'
require 'mod-gui'

require 'lib/kwidgets'
require 'lib/kwidget_playertable'
require 'permissions'
require 'lib/fb_util'

function create_liquid_field_at(player, type, quantity, richness, variance)
	local amount = 0
	local position = player.position
	
	for i = 1, quantity do
		-- figure out a random direction to take, max of 15 units
		local xmove = math.random(30) - 15
		local ymove = math.random(30) - 15
		position.x = position.x + xmove
		position.y = position.y + ymove
		-- i/2+1.5 creates a very obvious * shape with larger fields.
		local res_position = player.surface.find_non_colliding_position(type, 
			position, 0, 4)
		if position then 
			local variation = math.random(variance * 2)
			local value = (richness - variance + variation)
			player.surface.create_entity({name="crude-oil", amount=value, position=res_position})
			amount = amount + value
		end
	end	
	return amount
end

function adjacent_water_tiles(surface, position)
	local water_tiles = {}
	for idx = -1, 1 do
		for jdx = -1, 1 do
			pos = { x = position.x + idx, y = position.y + jdx }
			tile = surface.get_tile(pos)
			if tile.name == 'water' then
				table.insert(water_tiles, tile)
			end
		end
	end
	return water_tiles
end

function create_ore_field_at(player, resource, radius, density, taper, variance, pointcount)
	local total_amount = 0
	local center_area = radius - taper
	local points = {}
	local topleft = {}
	local bottomright = {}
	
	for idx = 1, pointcount do
		points[idx] = {
			x = player.position.x + math.random(radius),
			y = player.position.y + math.random(radius),
			distances = {},
		}
	end
	topleft = { x = points[1].x, y = points[1].y }
	bottomright = { x = points[1].x, y = points[1].y }
	-- calculate point positions.
	for idx = 1, pointcount do
		topleft = {
			x = math.min(topleft.x, points[idx].x - radius),
			y = math.min(topleft.y, points[idx].y - radius),
		}
		-- I don't know why the taper is messed up on the bottom & right.
		-- only happens in multipoint designs.
		bottomright = {
			x = math.max(bottomright.x, points[idx].x + radius),
			y = math.max(bottomright.y, points[idx].y + radius),
		}
		for jdx = 1, pointcount do
			-- determine distance from other points.
			local x = points[idx].x - points[jdx].x
			local y = points[idx].y - points[jdx].y
			points[idx].distances[jdx] = math.sqrt(x * x + y * y)
		end
	end
	for pos_x = topleft.x, bottomright.x do
		for pos_y = topleft.y, bottomright.y do
			local distances = {}
			for idx = 1, pointcount do
				local x = points[idx].x - pos_x
				local y = points[idx].y - pos_y
				distances[idx] = math.sqrt(x * x + y * y)
			end
			
			-- adjust percentage weight based on distance from points
			local percent = 1 / radius
			local drop = false
			if 0 == #adjacent_water_tiles(player.surface, {x = pos_x, y = pos_y}) then
				for idx = 1, pointcount do
					local distance = distances[idx]
					if distance-0.5 < radius then
						drop = true
						if distance - center_area > 0 then
							percent = percent + (taper - (distance - center_area) + 1) / (taper + 1)
						else
							percent = 1
						end
					end
				end
			end
			if drop then
				local variation = 0
				if variance > 0 then
					variation = math.random(variance * 2)
				end
				local value = (density - variance + variation) * math.min(percent, 1)
				local position = {
					x = pos_x,
					y = pos_y,
				}
				player.surface.create_entity({
					name = resource,
					amount = value,
					position = position,
				})
				total_amount = total_amount + value
			end
		end
	end
	return total_amount
end


local function advadmin_init()
	global.advadmin_modifiers = {
		{parm="manual_mining_speed_modifier", default=0, min=0, max=10},
		{parm="manual_crafting_speed_modifier", default=0, min=0, max=10},
		{parm="character_running_speed_modifier", default=0, min=-1, max=50},
		{parm="worker_robots_speed_modifier", default=0, min=-1, max=50},
		{parm="worker_robots_storage_bonus", default=0, min=0, max=50},
		{parm="character_build_distance_bonus", default=0, min=0, max=50},
		{parm="character_item_drop_distance_bonus", default=0, min=0, max=50},
		{parm="character_reach_distance_bonus", default=0, min=0, max=50},
		{parm="character_resource_reach_distance_bonus", default=0, min=0, max=50},
		{parm="character_item_pickup_distance_bonus", default=0, min=0, max=50},
		{parm="character_loot_pickup_distance_bonus", default=0, min=0, max=50},
	}
	global.advadmin_ores = {
		'coal',
		'copper-ore',
		'iron-ore',
		'stone',
		'uranium-ore',
	}
	global.advadmin_liquids = {
		'crude-oil',
	}
	
	local kframe = kw_newTabDialog('advadmin', 
		{caption={'advadmin.name'}, style='frame'},
		{position='center', defaultTab='commands'},
		function(dialog) -- instantiation
			dialog:addTab('commands', 
				{caption = {'advadmin.commands.name'}, tooltip = {'advadmin.commands.tooltip'}, }, 
				function(dialog, tab) -- tab instantiation.  
					-- Connect our buttons here.
					kw_connectButton('advadmin.new_fishmarket', function(event)
						local player = game.players[event.player_index]
						if remote.interfaces['fish_market'] and remote.interfaces['fish_market']['spawnMarketOn'] then
							remote.call('fish_market', 'spawnMarketOn', player)
							player.print({'advadmin.commands.spawned_market'})
						else
							player.print({'advadmin.commands.market_not_avail'})
						end
					end)
					kw_connectButton('advadmin.rem_fishmarket', function(event)
						local player = game.players[event.player_index]
						if remote.interfaces['fish_market'] and remote.interfaces['fish_market']['removeMarketsNear'] then
							local count = remote.call('fish_market', 'removeMarketsNear', player, 10)
							if count > 0 then
								player.print({'advadmin.commands.removed_markets', count})
							else
								player.print({'advadmin.commands.no_markets_removed'})
							end
						else
							player.print({'advadmin.commands.market_not_avail'})
						end
					end)
					kw_connectButton('advadmin.set_flashlight', function(event)
						if remote.interfaces['flashlight'] then
							local player = game.players[event.player_index]
							local fl_state = event.element.parent.fl_state.selected_index
							if fl_state == 1 then
								remote.call('flashlight', 'disable')
								player.print{'advadmin.commands.set_fl_state', {'advadmin.commands.fl_state_disabled_text'}}
							else
								remote.call('flashlight', 'enable')
								player.print{'advadmin.commands.set_fl_state', {'advadmin.commands.fl_state_enabled_text'}}
							end
						end
					end)
					kw_connectButton('advadmin.revive_ents', function(event)
						local player = game.players[event.player_index]
						local range = tonumber(event.element.parent.parent.range_dist.text)
						if range then
							if range > 200 then
								player.print({'advadmin.commands.revive_range_excessive', 200})
							else
								local count = 0
								local region = {{player.position.x-range, player.position.y-range}, {player.position.x+range, player.position.y+range}}
								for key, entity in pairs(game.surfaces[1].find_entities_filtered({area=region, type = "entity-ghost"})) do
									entity.revive()
									count = count + 1
								end
								player.print({'advadmin.commands.revive_count_msg', count})
							end
						else
							player.print({'advadmin.commands.range_not_number'})
						end
					end)
					kw_connectButton('advadmin.remove_aliens', function(event)
						local player = game.players[event.player_index]
						local range = tonumber(event.element.parent.parent.range_dist.text)
						if range then
							if range > 200 then
								player.print({'advadmin.commands.remove_range_excessive', 200})
							else
								local count = 0
								local region = {{player.position.x-range, player.position.y-range}, {player.position.x+range, player.position.y+range}}
								for key, entity in pairs(game.surfaces[1].find_entities_filtered({area=region, force="enemy"})) do
									entity.destroy()
									count = count + 1
								end
								player.print({'advadmin.commands.remove_count_msg', count})
							end
						else
							player.print({'advadmin.commands.range_not_number'})
						end
					end)
					kw_connectButton('advadmin.revive_all_ents', function(event)
						local player = game.players[event.player_index]
						local count = 0
						for key, entity in pairs(game.surfaces[1].find_entities_filtered({type = "entity-ghost"})) do
							entity.revive()
							count = count + 1
						end
						player.print({'advadmin.commands.revive_count_msg', count})
					end)
					kw_connectButton('advadmin.remove_all_aliens', function(event)
						local player = game.players[event.player_index]
						local count = 0
						for key, entity in pairs(game.surfaces[1].find_entities_filtered({force='enemy'})) do
							entity.destroy()
							count = count + 1
						end
						player.print({'advadmin.commands.remove_count_msg', count})
					end)
					kw_connectButton('advadmin.cheat', function(event)
						local player = game.players[event.player_index]
						player.cheat_mode = not player.cheat_mode
						player.print({'advadmin.commands.cheat_msg_'..serpent.block(player.cheat_mode)})
					end)
				end,
				function(player, dialog, container) -- tab render
					-- fish market
					if remote.interfaces['fish_market'] then
						local subcont = container.add({type='flow', name='fishmarket', direction='horizontal'})
						kw_newButton(subcont, 'advadmin.new_fishmarket', {'advadmin.commands.new_fm_title'}, {'advadmin.commands.new_fm_tooltip'}, nil, nil)
						kw_newButton(subcont, 'advadmin.rem_fishmarket', {'advadmin.commands.rem_fm_title'}, {'advadmin.commands.rem_fm_tooltip'}, nil, nil)
					end
					if remote.interfaces['flashlight'] then
						local subcont = container.add({type='flow', name='flashlight', direction='horizontal'})
						subcont.add({type='label', caption={'advadmin.commands.set_fl_state_label'}})
						local fl_state_dd = subcont.add({name='fl_state', type='drop-down'})
						kw_applyStyle(fl_state_dd, global.kw_style.sort_dropdown)
						fl_state_dd.add_item({'advadmin.commands.fl_state_disabled_text'})
						fl_state_dd.add_item({'advadmin.commands.fl_state_enabled_text'})
						fl_state_dd.selected_index = 1
						if remote.call('flashlight', 'is_enabled') then
							fl_state_dd.selected_index = 2
						end
						kw_newButton(subcont, 'advadmin.set_flashlight', {'advadmin.commands.set_fl_title'}, {'advadmin.commands.set_fl_tooltip'}, nil, 'auth_actions_button')
					end
					-- range-based
					local subcont = container.add({type='table', name='range-based', column_count=3})
					subcont.add({name='range_label', type='label', caption={'advadmin.commands.range'}})
					subcont.add({name='range_dist', type='textfield', text='100'})
					local rangebuttons = subcont.add({name='buttons', type='flow', direction='vertical'})
					kw_newButton(rangebuttons, 'advadmin.revive_ents', {'advadmin.commands.revive_ents_name'}, {'advadmin.commands.revive_ents_tooltip'}, nil, nil)
					kw_newButton(rangebuttons, 'advadmin.remove_aliens', {'advadmin.commands.remove_aliens_name'}, {'advadmin.commands.remove_aliens_tooltip'}, nil, nil)
					
					container.add({name='all_op_warning', type='label', caption={'advadmin.commands.warning_all_ops'}})
					container.all_op_warning.style.maximal_width = container.style.maximal_width
					container.all_op_warning.style.single_line = false

					subcont = container.add({type='flow', name='fullmap_operations', direction='horizontal'})
					kw_newButton(subcont, 'advadmin.revive_all_ents', {'advadmin.commands.revive_all_ents_name'}, {'advadmin.commands.revive_all_ents_tooltip'}, nil, nil)
					kw_newButton(subcont, 'advadmin.remove_all_aliens', {'advadmin.commands.remove_all_aliens_name'}, {'advadmin.commands.remove_all_aliens_tooltip'}, nil, nil)
					
					kw_hline(container)
					kw_newButton(container, 'advadmin.cheat', {'advadmin.commands.cheat_name'}, {'advadmin.commands.cheat_tooltip'}, nil, nil)
				end
			)
			dialog:addTab('mods', 
				{caption = {'advadmin.mods.name'}, tooltip = {'advadmin.mods.tooltip'}, }, 
				function(dialog, tab) -- tab instantiation.
					kw_connectButton('advadmin.mods.apply', function(event)
						local player = game.players[event.player_index]
						local force = player.force
						local subtable = event.element.parent.modtable
						for idx, mod in pairs(global.advadmin_modifiers) do
							local value = tonumber(subtable[mod.parm].text)
							if value and value ~= force[mod.parm] then
								local orig = force[mod.parm]
								force[mod.parm] = value
								player.print({'advadmin.mods.updated_parm', mod.parm, orig, value})
							end
						end
						Event.dispatch({name = Event.def("advadmin.update_modifiers"), tick=game.tick, player_index=event.player_index})
					end)
				end,
				function(player, dialog, container) -- tab render
					container.add({name='aboutmsg', type='label', caption={'advadmin.mods.aboutmsg'}})
					container.aboutmsg.style.single_line = false
					container.aboutmsg.style.maximal_width = container.style.maximal_width
					kw_newButton(container, 'advadmin.mods.apply', {'advadmin.mods.apply'}, nil, nil, nil)
					
					local subtable = container.add({name='modtable', type='table', column_count=4})
					-- headers
					subtable.add({type='label', caption={'advadmin.mods.header_field'}, })
					subtable.add({type='label', caption={'advadmin.mods.header_value'}, })
					subtable.add({type='label', caption={'advadmin.mods.header_current'}, })
					subtable.add({type='label', caption={'advadmin.mods.header_info'}, })
					for idx, mod in pairs(global.advadmin_modifiers) do
						subtable.add({type='label', caption=mod.parm})
						subtable.add({name=mod.parm, type='textfield', text=player.force[mod.parm]})
						subtable.add({name='cur.'..mod.parm, type='label', caption=player.force[mod.parm]})
						-- #TODO: use a sprite here, if we can.  Just for looks.
						kw_newButton(subtable, 'info.'..mod.parm, '?', {'advadmin.mods.infoblurb', {'advadmin.mods.info_'..mod.parm}, mod.default, mod.min, mod.max}, nil, nil)
					end
				end
			)
			dialog:addTab('add_ore', 
				{caption = {'advadmin.add_ore.name'}, tooltip = {'advadmin.add_ore.tooltip'}, }, 
				function(dialog, tab) -- tab instantiation
					kw_connectButton('advadmin.add_ore.create', function(event)
						local player = game.players[event.player_index]
						local force = player.force
						local subtable = event.element.parent.oretable
						local resource = global.advadmin_ores[subtable.ore_type.selected_index]
						local surface = player.surface
						
						local radius   = tonumber(subtable.radius.text)
						local density  = tonumber(subtable.density.text)
						local taper    = tonumber(subtable.taper.text)
						local variance = tonumber(subtable.variance.text)
						local points   = tonumber(subtable.points.text)
						
						if not (radius and density and taper and variance and points) then
							player.print({'advadmin.add_ore.invalid_params'})
							return
						end
						
						local total_amount = create_ore_field_at(player, resource, radius, density, taper, variance, points)
						
						player.print({'advadmin.add_ore.finished', math.floor(total_amount), resource})
					end)
				end,
				function(player, dialog, container) -- tab render
					container.add({name='aboutmsg', type='label', caption={'advadmin.add_ore.aboutmsg'}})
					container.aboutmsg.style.maximal_width = container.style.maximal_width
					container.aboutmsg.style.single_line = false
					
					local subtable = container.add({name='oretable', type='table', column_count=3})
					
					-- ore type
					subtable.add({type='label', caption={'advadmin.add_ore.type'}, })
					subtable.add({name='ore_type', type='drop-down'})
					for idx, ore in pairs(global.advadmin_ores) do
						subtable.ore_type.add_item(game.entity_prototypes[ore].localised_name)
					end
					subtable.ore_type.selected_index = 1
					kw_newButton(subtable, 'add_ore.info.type', '?', {'advadmin.add_ore.info_type'}, nil, nil)
					
					-- size
					subtable.add({type='label', caption={'advadmin.add_ore.size'}, })
					subtable.add({type='textfield', name='radius', text='5'})
					kw_newButton(subtable, 'add_ore.info.size', '?', {'advadmin.add_ore.info_size'}, nil, nil)
					
					-- density
					subtable.add({type='label', caption={'advadmin.add_ore.density'}, })
					subtable.add({type='textfield', name='density', text='5000'})
					kw_newButton(subtable, 'add_ore.info.density', '?', {'advadmin.add_ore.info_density'}, nil, nil)
					
					-- taper tiles
					subtable.add({type='label', caption={'advadmin.add_ore.taper'}, })
					subtable.add({type='textfield', name='taper', text='3'})
					kw_newButton(subtable, 'add_ore.info.taper', '?', {'advadmin.add_ore.info_taper'}, nil, nil)
					
					-- variance
					subtable.add({type='label', caption={'advadmin.add_ore.variance'}, })
					subtable.add({type='textfield', name='variance', text='600'})
					kw_newButton(subtable, 'add_ore.info.variance', '?', {'advadmin.add_ore.info_variance'}, nil, nil)
					
					-- center points
					subtable.add({type='label', caption={'advadmin.add_ore.points'}, })
					subtable.add({type='textfield', name='points', text='2'})
					kw_newButton(subtable, 'add_ore.info.points', '?', {'advadmin.add_ore.info_points'}, nil, nil)
					
					kw_newButton(container, 'advadmin.add_ore.create', {'advadmin.add_ore.create'}, nil, nil, nil)
				end
			)
			dialog:addTab('add_liquid', 
				{caption = {'advadmin.add_liquid.name'}, tooltip = {'advadmin.add_liquid.tooltip'}, }, 
				function(dialog, tab) -- tab instantiation
					kw_connectButton('advadmin.add_liquid.create', function(event)
						local player = game.players[event.player_index]
						local force = player.force
						local subtable = event.element.parent.resTable
						local resource = global.advadmin_liquids[subtable.res_type.selected_index]
						local surface = player.surface
					
						local quantity = tonumber(subtable.quantity.text)
						local richness = tonumber(subtable.richness.text)
						local variance = tonumber(subtable.variance.text)

						if not (quantity and richness and variance) then
							player.print({'advadmin.add_ore.invalid_params'})
							return
						end
						
						total_amount = create_liquid_field_at(player, resource, quantity, richness, variance)
						
						player.print({'advadmin.add_liquid.finished', math.floor(total_amount), resource})
					end)
				end,
				function(player, dialog, container) -- tab render
					container.add({name='aboutmsg', type='label', caption={'advadmin.add_liquid.aboutmsg'}})
					container.aboutmsg.style.maximal_width = container.style.maximal_width
					container.aboutmsg.style.single_line = false
					
					local subtable = container.add({name='resTable', type='table', column_count=3})
					
					-- ore type
					subtable.add({type='label', caption={'advadmin.add_liquid.type'}, })
					subtable.add({name='res_type', type='drop-down'})
					for idx, res in pairs(global.advadmin_liquids) do
						subtable.res_type.add_item(game.entity_prototypes[res].localised_name)
					end
					subtable.res_type.selected_index = 1
					kw_newButton(subtable, 'add_liquid.info.type', '?', {'advadmin.add_liquid.info_type'}, nil, nil)
					
					-- size
					subtable.add({type='label', caption={'advadmin.add_liquid.quantity'}, })
					subtable.add({type='textfield', name='quantity', text='5'})
					kw_newButton(subtable, 'add_liquid.info.quantity', '?', {'advadmin.add_liquid.info_quantity'}, nil, nil)
					
					-- density
					subtable.add({type='label', caption={'advadmin.add_liquid.richness'}, })
					subtable.add({type='textfield', name='richness', text='60000'})
					kw_newButton(subtable, 'add_liquid.info.richness', '?', {'advadmin.add_liquid.info_richness'}, nil, nil)
					
					-- taper tiles
					subtable.add({type='label', caption={'advadmin.add_liquid.variance'}, })
					subtable.add({type='textfield', name='variance', text='30000'})
					kw_newButton(subtable, 'add_liquid.info.variance', '?', {'advadmin.add_liquid.info_variance'}, nil, nil)
					
					kw_newButton(container, 'advadmin.add_liquid.create', {'advadmin.add_liquid.create'}, nil, nil, nil)
				end
			)
		end,
		function(player, widget, container) -- dialog render
		end
	)
end

local function toggleTools(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('advadmin')
	dialog:toggleShow(player)
end

local function showAdvAdminButton(player)
	if perms.userHasPermission(player.name, 'advadmin.tool') then
		kw_newToolbarButton(player, 'advadmin_toggle', {'advadmin.btn_name'}, {'advadmin.btn_tooltip'}, nil, toggleTools)
	else
		kw_delToolbarButton(player, 'advadmin_toggle')
		local dialog = kw_getWidget('advadmin')
		dialog:hide(player)
	end
end

Event.register(Event.def("softmod_init"), function(event)
	advadmin_init()
	perms.registerPermission('advadmin.tool')
end)


Event.register(Event.def("advadmin.update_modifiers"), function(event)
	for idx, player in pairs(game.connected_players) do
		local dialog = kw_getWidget('advadmin')
		local container = dialog:container(player)
		if container and container.tabPane.modtable then
			local modtable = container.tabPane.modtable
			for jdx, mod in pairs(global.advadmin_modifiers) do
				modtable['cur.'..mod.parm].caption = player.force[mod.parm]
			end
		end
	end
end)

Event.register(Event.def('perms.user_group_change'), function(event)
	local player = game.players[event.player_index]
	--game.print("DEBUG: AdvAdmin button check for " .. player.name)
	if player and player.connected then
		showAdvAdminButton(player)
	end
end)

local function permchange_checkbuttons(event)
	if event.permName == 'advadmin.tool' then
		perms.executeOnGroupUsers(event.groupName, true, false, {}, function(playerName)
			local player = getPlayerNamed(playerName)
			--game.print("DEBUG AdvAdmin button check for " .. playerName)
			if player and player.connected then
				showAdvAdminButton(player)
			end
		end)
	end
end
Event.register(Event.def('perms.group_perm_add'), permchange_checkbuttons)
Event.register(Event.def('perms.group_perm_remove'), permchange_checkbuttons)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	showAdvAdminButton(player)
end)

