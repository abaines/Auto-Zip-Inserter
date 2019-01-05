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

	admin_gui.lua - Moderator & Admin GUI
	
	Inspired by ExplosiveGaming's Admin GUI

--]]

require 'lib/event_extend'
require 'mod-gui'

require 'lib/kwidgets'
require 'lib/kwidget_playertable'
require 'permissions'
require 'lib/fb_util'

local function playerTableButtonConnections()
	kw_connectButton('admin.btn.tp2you', function(event)
		local player = game.players[event.player_index]
		-- get target player based on the button's container
		local pl_target = getPlayerNamed(event.element.parent.name)
		player.teleport(game.surfaces[pl_target.surface.name].find_non_colliding_position("player", pl_target.position, 32, 1))
		player.print({'admin.actions.teleport_message', player.name, pl_target.name})
	end)
	kw_connectButton('admin.btn.tp2me', function(event)
		local player = game.players[event.player_index]
		-- get target player based on the button's container
		local pl_target = getPlayerNamed(event.element.parent.name)
		pl_target.teleport(game.surfaces[player.surface.name].find_non_colliding_position("player", player.position, 32, 1))
		player.print({'admin.actions.bring_message', player.name, pl_target.name})
	end)
	kw_connectButton('admin.btn.jail', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.set_jail') then
			-- get target player based on the button's container
			local pl_target = getPlayerNamed(event.element.parent.name)
			if perms.playerGroup(pl_target.name).name == 'Jail' then
				-- revert to previous group
				perms.revertGroup(pl_target.name)
				player.print({'admin.actions.jail_unmessage', pl_target.name})
			else
				perms.setUserGroup(pl_target.name, 'Jail')
				player.print({'admin.actions.jail_message', pl_target.name})
			end
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
	kw_connectButton('admin.btn.kill', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.kill') then
			-- get target player based on the button's container
			local pl_target = getPlayerNamed(event.element.parent.name)
			if pl_target.connected and pl_target.character then
				pl_target.character.die()
				player.print({'admin.actions.kill_message', pl_target.name})
			else
				player.print({'admin.actions.kill_fail_message', pl_target.name})
			end
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
	kw_connectButton('admin.btn.ban', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.ban') then
			-- get target player based on the button's container
			local pl_target = game.players[event.element.parent.name]
			if pl_target.connected and pl_target.character then
				pl_target.character.die()
				player.print({'admin.actions.ban_message', pl_target.name})
			else
				player.print({'admin.actions.ban_fail_message', pl_target.name})
			end
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
	kw_connectButton('admin.btn.set_prev_group', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.set_group') then
			-- get target player based on the button's container
			local pl_target = getPlayerNamed(event.element.parent.name)
			perms.revertGroup(pl_target.name)
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
	kw_connectButton('admin.btn.openinv', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.open_inventory') then
			local pl_target = getPlayerNamed(event.element.parent.name)
			player.opened = pl_target
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
	kw_connectButton('admin.btn.dumpinv', function(event)
		local player = game.players[event.player_index]
		if perms.userHasPermission(player.name, 'admin.tool.dump_inventory') then
			local pl_target = getPlayerNamed(event.element.parent.name)
			local inventories = {
				pl_target.get_inventory(defines.inventory.player_main),
				pl_target.get_inventory(defines.inventory.player_quickbar),
				pl_target.get_inventory(defines.inventory.player_armor),
			}
			
			local box = nil
			local box_idx = 1
			local empty = true
			
			for idx, inv in pairs(inventories) do
				if not inv.is_empty() then
					empty = false
					
					for jdx = 1, #inv do
						if inv[jdx].valid_for_read then
							if not box then
								box = createEntityNearPlayer('steel-chest', player, 5)
								box_idx = 1
							elseif not box.get_inventory(defines.inventory.chest).can_insert(inv[jdx]) then
								box = createEntityNearPlayer('steel-chest', player, 5)
								box_idx = 1
							elseif box_idx > #(box.get_inventory(defines.inventory.chest)) then
								box = createEntityNearPlayer('steel-chest', player, 5)
								box_idx = 1
							end
							-- Should have a valid storage chest here, unless we can't
							-- find a suitable location for one.
							if box then
								box.get_inventory(defines.inventory.chest)[box_idx].set_stack(inv[jdx])
								inv.remove(inv[jdx])
								box_idx = box_idx + 1
							else
								player.print({'admin.actions.dumpinv_error', pl_target.name, {'admin.actions.dumpinv_error_create_box'}})
								return
							end
						end
					end
				end
			end
			if empty then
				player.print({'admin.actions.dumpinv_error', pl_target.name, {'admin.actions.dumpinv_error_empty'}})
			else
				player.print({'admin.actions.dumpinv_message', pl_target.name})
			end
		else
			player.print({'permissions.user_no_permission'})
		end
	end)
end

-- this function must be in the global space, presumeably because it gets
-- called as part of a callback from another function
function admin_playerButtons(container, pl_sourceName, pl_targetName)
	-- Use the target player's name for this button container, that
	-- way we can reference it in the button actions.
	local cont2 = container[pl_targetName]
	if cont2 then
		cont2.clear()
	else
		cont2 = container.add({type='flow', name=pl_targetName})
	end
	
	if pl_sourceName == pl_targetName then
		-- no buttons to add to flow, but we have to add *something* (above)
		-- to the container, as it's expecting 1 item.
		--return
	end
	
	-- interesting button styles:
	-- mod_gui_button_style, slot_button_style, search_button_style,
	-- circuit_condition_sign_button_style, crafting_queue_slot_style,
	-- promised_crafting_queue_slot_style,
	-- partially_promised_crafting_queue_slot_style,
	-- auth_actions_button_style
	local button_style = "auth_actions_button"
	kw_newButton(cont2, 'admin.btn.tp2you', {'admin.actions.teleport_name'}, {'admin.actions.teleport_tooltip', pl_targetName}, nil, button_style)
	if perms.userHasPermission(pl_sourceName, 'admin.tool.bring') then
		kw_newButton(cont2, 'admin.btn.tp2me', {'admin.actions.bring_name'}, {'admin.actions.bring_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.set_jail') then
		kw_newButton(cont2, 'admin.btn.jail', {'admin.actions.jail_name'}, {'admin.actions.jail_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.set_prev_group') then
		kw_newButton(cont2, 'admin.btn.prev_group', {'admin.actions.prevgroup_name'}, {'admin.actions.prevgroup_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.kill') then
		kw_newButton(cont2, 'admin.btn.kill', {'admin.actions.kill_name'}, {'admin.actions.kill_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.open_inventory') then
		kw_newButton(cont2, 'admin.btn.openinv', {'admin.actions.openinv_name'}, {'admin.actions.openinv_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.dump_inventory') then
		kw_newButton(cont2, 'admin.btn.dumpinv', {'admin.actions.dumpinv_name'}, {'admin.actions.dumpinv_tooltip', pl_targetName}, nil, button_style)
	end
	if perms.userHasPermission(pl_sourceName, 'admin.tool.ban') then
		kw_newButton(cont2, 'admin.btn.ban', {'admin.actions.ban_name'}, {'admin.actions.ban_tooltip', pl_targetName}, nil, button_style)
	end
	return cont2
end

function admin_drawPlayerTable(container, player)
	--player.print("DEBUG: Trying to sort table by selection: "..container.order_table.order.selected_index)
	kw_playerTable(
		container,
		'playerTable', -- name
		nil, -- players
		{
			row_settings={pl_sourceName=player.name},
			widths = { playername = 125, actions = 300 },
			scrollpane = { width=545, height=235 },
			scroll_horizontal = auto,
			no_icons = true,
		}, -- settings
		admin_filterPlayerStatus, -- filter function
		function(table, rownumber, field, celldata, settings) -- actions
			return admin_playerButtons(table, settings.row_settings.pl_sourceName, celldata.target.name)
		end
	)
end
function admin_filterPlayerStatus(player, settings)
	if settings.row_settings.pl_sourceName then
		local uiplayer = getPlayerNamed(settings.row_settings.pl_sourceName)
		local gsettings = global.admin_settings[uiplayer.index]
		if gsettings.playerStatusFilter then
			if gsettings.playerStatusFilter == kw_playerFilterByname('both') then
				return true
			end
			if gsettings.playerStatusFilter == kw_playerFilterByname('online') then
				return player.connected
			end
			if gsettings.playerStatusFilter == kw_playerFilterByname('offline') then
				return not player.connected
			end
		end
	end
	return true
end
function admin_setPlayerFilterStatus(event)
	local player = game.players[event.player_index]
	local element = event.element
	local gsettings = global.admin_settings[player.index]
	gsettings.playerStatusFilter = element.selected_index
end
function admin_playersFilterChanged(event)
	admin_setPlayerFilterStatus(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawPlayerTable(container, player)
end
function admin_playersSortChanged(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawPlayerTable(container, player)
end
function admin_sortPlayersClicked(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawPlayerTable(container, player)
end

function admin_drawGroupMgmtActions(table, rownumber, field, celldata, settings)
	local pl_sourceName = settings.row_settings.pl_sourceName
	local pl_targetName = celldata.target.name
	local cont2 = table.add({type='flow', name=pl_targetName})
	
	local groups = perms.knownGroups(pl_sourceName)
	arr_remove(groups, perms.playerGroup(pl_sourceName).name)
	if pl_sourceName == pl_targetName then
		return cont2
	end
	if arr_contains(groups, perms.playerGroup(pl_targetName)) then
		cont2.add({name='select', type="checkbox",state=false})
	end
	return cont2
end

function admin_drawGroupMgmtTable(container, player)
	--player.print("DEBUG: Trying to sort table by selection: "..container.order_table.order.selected_index)
	kw_playerTable(
		container,
		'playerTable', -- name
		nil, -- players
		{
			row_settings={pl_sourceName=player.name},
			widths = { actions = 100 },
			scrollpane = { width=545, height=190 },
			no_icons = true,
		}, -- settings
		admin_filterPlayerStatus, -- filter function
		admin_drawGroupMgmtActions
	)
end
function admin_groupPlayerFilterChanged(event)
	admin_setPlayerFilterStatus(event)
	local player = game.players[event.player_index]
	
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawGroupMgmtTable(container, player)
end
function admin_sortGroupMgmtChanged(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawGroupMgmtTable(container, player)
end
function admin_sortGroupMgmtClicked(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('admin'):container(player)['tabPane']
	admin_drawGroupMgmtTable(container, player)
end


local function initDialog()
	kw_newTabDialog('admin', {caption={'admin.name'}}, {position='center'}, 
		function(dialog) -- instantiation.
			-- must do button connections *outside* of any render functions.
			dialog:addTab('commands', 
				{caption={'admin.commands.name'}, tooltip = {'admin.commands.tooltip'} }, 
				function(dialog, tab) -- tab instantiation.  
					-- Connect our buttons here.
					kw_connectButton('admin.btn.automessage', function(event)
						if remote.interfaces['automessage'] then
							remote.call('automessage', 'send')
						else
							local player = game.players[event.player_index]
							player.print({'admin.commands.automessage_notfound'})
						end
					end)
					kw_connectButton('admin.btn.revive_entities', function(event)
						if perms.userHasPermission(player.name, 'admin.tool.revive_ents') then
							local player = game.players[event.player_index]
							local revive = event.element.parent
							local range = tonumber(revive['revive_dist'].text)
							if range then
								if range > 200 then
									player.print({'admin.commands.revive_fail_dist', 200})
									return
								end
								local region = {{player.position.x-range, player.position.y-range}, {player.position.x+range, player.position.y+range}}
								for key, entity in pairs(game.surfaces[1].find_entities_filtered({area=region, type = "entity-ghost"})) do
									entity.revive()
								end
							end
						end
					end)
					kw_connectButton('admin.btn.msg2group', function(event)
						local player = game.players[event.player_index]
						local msg2group = event.element.parent
						local groups = perms.knownGroups(player.name)
						local group = groups[msg2group.group.selected_index]
						local name = (group.i18n_sname or group.i18n_name or group.name)
						--game.print(serpent.block(name))
						perms.executeOnGroupUsers(group.name, true, false, 
							{name = name, message = msg2group.message.text},
							function(playerName, params)
								local player = getPlayerNamed(playerName)
								player.print({'admin.commands.group_message', params.name, params.message})
							end
						)
					end)
					kw_connectButton('admin.btn.tp_all2me', function(event)
						local player = game.players[event.player_index]
						if perms.userHasPermission(player.name, 'admin.tool.bringall') then
							for i,p in pairs(game.connected_players) do
								local pos = game.surfaces[player.surface.name].find_non_colliding_position("player", player.position, 32, 1)
								if p ~= player then
									p.teleport(pos)
								end
							end
						end
					end)
				end,
				function(player, dialog, container) -- tab render
					-- automessage
					if remote.interfaces['automessage'] then
						kw_newButton(container, 'admin.btn.automessage', {'admin.commands.automessage_name'}, {'admin.commands.automessage_tooltip'}, nil, nil)
						kw_space(container)
					end
				
					-- Revive entities button
					if perms.userHasPermission(player.name, 'admin.tool.revive_ents') then
						local revive = container.add({name='revive_table', type='table', column_count=3})
						kw_newButton(revive, 'admin.btn.revive_entities', {'admin.commands.revive_ents_name'}, {'admin.commands.revive_ents_tooltip'}, nil, nil)
						revive.add({name='revive_label', type='label', caption='Range:'})
						revive.add({name='revive_dist', type='textfield', text='100'})
						kw_space(container)
					end
					
					-- Message to group
					local msg2group = container.add({name='msg2group_table', type='table', column_count=4})
					msg2group.add({name='label', type='label', caption={'admin.commands.message_title'}})
					msg2group.add({name='group', type='drop-down'})
					local groups = perms.knownGroups(player.name)
					for _, group in pairs(groups) do
						msg2group.group.add_item(group.i18n_name)
					end
					msg2group.group.selected_index = 1
					msg2group.add({name='message', type='textfield', text='enter msg'})
					kw_newButton(msg2group, 'admin.btn.msg2group', {'admin.commands.message_btn_name'}, {'admin.commands.message_btn_tooltip'}, nil, nil)
					
					-- Teleport all to me.
					if perms.userHasPermission(player.name, 'admin.tool.bringall') then
						kw_space(container)
						kw_newButton(container, 'admin.btn.tp_all2me', {'admin.commands.teleport_name'}, {'admin.commands.teleport_tooltip'}, nil, nil)
					end
				end
			) -- end tab: commands
			
			dialog:addTab('player_actions',
				{caption={'admin.actions.name'}, tooltip = {'admin.actions.tooltip'} }, 
				function(dialog, tab) -- tab instantiation
					kw_connectDropdown('admin_players_filter', admin_playersFilterChanged)
					playerTableButtonConnections()
					--game.print("DEBUG: Tab instantiation: admin, pl.actions")
				end,
				function(player, widget, container) -- tab render
					--game.print("DEBUG: order table is in ".. container.name)
					local sortcont = container.add({name='order_table', type='table', column_count=4})
					local filter_dd = sortcont.add({name='admin_players_filter', type='drop-down'})
					kw_applyStyle(filter_dd, global.kw_style.sort_dropdown)
					for idx, localetext in pairs(kw_playerFilterList()) do
						filter_dd.add_item(localetext)
					end
					filter_dd.selected_index = global.admin_settings[player.index].playerStatusFilter
					
					admin_drawPlayerTable(container, player)
				end
			)
			dialog:addTab('group_mgmt',
				{caption={'admin.groups.name'}, tooltip = {'admin.groups.tooltip'} }, 
				function(dialog, tab) -- tab instantiation
					kw_connectDropdown('admin_group_filter', admin_groupPlayerFilterChanged)
					kw_connectButton('admin.btn.groupmgmt_apply', function(event)
						local player = game.players[event.player_index]
						local tabpane = event.element.parent.parent
						local groups = perms.knownGroups(player.name)
						local selected_group = groups[tabpane.group_apply.groups.selected_index]
						local usertable = tabpane.table_scrollpane.playerTable
						for _,tplayer in pairs(game.players) do
							-- check for existence of checkbox
							if usertable[tplayer.name] and usertable[tplayer.name].select then
								if usertable[tplayer.name].select.state then
									-- set user to group
									-- note: if demoting self (which should not be allowed),
									-- then this code will cause an error
									perms.setUserGroup(tplayer.name, selected_group.name)
									usertable[tplayer.name].select.state = false
								end
							end
						end
						--game.print(tabpane.name)
					end)
					--game.print("Tab instantiation: admin, group_mgmt")
				end,
				function(player, widget, container) -- tab render
					--game.print("order table is in ".. container.name)
					local ga_cont = container.add({name='group_apply', type='flow', direction='horizontal'})
					ga_cont.add({type='label', caption={'admin.groups.set_group_text'}})
					local grouplist_dd = ga_cont.add({name='groups', type='drop-down'})
					kw_applyStyle(grouplist_dd, global.kw_style.sort_dropdown)
					local selectGroupIdx = 1
					for idx, group in pairs(perms.knownGroups(player.name)) do
						grouplist_dd.add_item(group.i18n_name)
						if group.name == perms.defaultPromoteGroupName() then
							selectGroupIdx = idx
						end
					end
					grouplist_dd.selected_index = selectGroupIdx
					kw_newButton(ga_cont, 'admin.btn.groupmgmt_apply', {'admin.groups.apply_text'}, {'admin.groups.apply_tooltip'}, nil, 'auth_actions_button')
					kw_hline(container)
					-- player list
					local sortcont = container.add({name='order_table', type='flow', direction='horizontal'})
					local online_dd = sortcont.add({name='admin_group_filter', type='drop-down'})
					kw_applyStyle(online_dd, global.kw_style.sort_dropdown)
					for idx, localetext in pairs(kw_playerFilterList()) do
						online_dd.add_item(localetext)
					end
					online_dd.selected_index = global.admin_settings[player.index].playerStatusFilter
					
					admin_drawGroupMgmtTable(container, player)
				end
			)
		end,
		function(player, dialog, container) -- dialog render
			-- on display
			--player.print("Trying to render admin tools")
		end
	)
end

local function initGlobals()
	global.admin_settings = {}
end

local function initGlobalsForPlayer(player_idx)
	global.admin_settings[player_idx] = {
		playerStatusFilter = kw_playerFilterByname("online"),
	}
end

local function toggleTools(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('admin')
	dialog:toggleShow(player)
end

local function showAdminButton(player)
	if perms.userHasPermission(player.name, 'admin.tool') then
		kw_newToolbarButton(player, 'admin_toggle', {'admin.btn_name'}, {'admin.btn_tooltip'}, nil, toggleTools)
	else
		kw_delToolbarButton(player, 'admin_toggle')
		local dialog = kw_getWidget('admin')
		dialog:hide(player)
	end
end

Event.register(Event.def("softmod_init"), function(event)
	initDialog()
	initGlobals()
	perms.registerPermission('admin.tool')
	perms.registerPermission('admin.tool.set_jail')
	perms.registerPermission('admin.tool.set_rank')
	perms.registerPermission('admin.tool.kill')
	perms.registerPermission('admin.tool.open_inventory')
end)

Event.register(Event.def('perms.user_group_change'), function(event)
	local player = game.players[event.player_index]
	--game.print("Admin button check for " .. player.name)
	if player and player.connected then
		showAdminButton(player)
	end
end)

local function permchange_checkbuttons(event)
	if event.permName == 'admin.tool' then
		perms.executeOnGroupUsers(event.groupName, true, false, {}, function(playerName)
			local player = getPlayerNamed(playerName)
			--game.print("Admin button check for " .. playerName)
			if player and player.connected then
				showAdminButton(player)
			end
		end)
	end
end
Event.register(Event.def('perms.group_perm_add'), permchange_checkbuttons)
Event.register(Event.def('perms.group_perm_remove'), permchange_checkbuttons)


Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	initGlobalsForPlayer(event.player_index)
	showAdminButton(player)
end)
