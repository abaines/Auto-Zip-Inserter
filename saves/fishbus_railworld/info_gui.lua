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

	info_gui.lua - FishBus Server information GUI
	
	Inspired by ExplosiveGaming's Info GUI

--]]

require 'lib/event_extend'
require 'mod-gui'

require 'lib/kwidgets'
require 'lib/kwidget_playertable'
require 'permissions'


function info_drawPlayerTable(container, player)
	local walkdist = false
	if remote.interfaces['pdistance'] then
		walkdist = true
	end
	kw_playerTable(container
		, 'playerTable' -- name
		, nil -- players
		, { -- settings
			pl_sourceName=player.name,
			status=true,
			distances={walked=walkdist},
			scrollpane = { width=545, height=205 },
		  }
		, info_filterPlayerStatus -- filter function
		, nil -- actions function
	)
end
function info_filterPlayerStatus(player, settings)
	if settings.pl_sourceName then
		local uiplayer = getPlayerNamed(settings.pl_sourceName)
		local container = kw_getWidget('info'):container(uiplayer)['tabPane']
		statusFilter = container.order_table.info_dd_filter.selected_index
		if statusFilter then
			if statusFilter == kw_playerFilterByname('both') then
				return true
			end
			if statusFilter == kw_playerFilterByname('online') then
				return player.connected
			end
			if statusFilter == kw_playerFilterByname('offline') then
				return not player.connected
			end
		end
	end
	return true
end
local function filterPlayersChanged(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('info'):container(player)['tabPane']
	info_drawPlayerTable(container, player)
end
local function sortPlayersChanged(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('info'):container(player)['tabPane']
	info_drawPlayerTable(container, player)
end
local function sortPlayersClicked(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('info'):container(player)['tabPane']
	info_drawPlayerTable(container, player)
end

function info_drawAdminTable(container, player)
	kw_playerTable(container
		, 'playerTable' -- name
		, perms.playersWithGroup('moderator') -- players
		, {
			sort=4, status=true,
			scrollpane = { width=540, height=170 },
		} -- settings
		, nil -- filter function
		, nil -- actions function
	)
end
local function info_sortAdminTableClicked(event)
	local player = game.players[event.player_index]
	local container = kw_getWidget('info'):container(player)['tabPane']
	info_drawAdminTable(container, player)
end


Event.register(Event.def("softmod_init"), function(event)
	kw_newTabDialog('info', 
		{caption={'info.splash.title'}},
		{position='center', defaultTab='splash'}, 
		function(dialog) -- instantiation.
			-- must do button connections *outside* of any render functions.
				dialog:addTab('splash',
				{caption = {'info.splash.title'}, tooltip = {'info.splash.tooltip'}},
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					local info = {
						{'info.splash.welcome0'},
						{'info.splash.welcome1'},
						{'info.splash.welcome2'},
						{'info.splash.welcome3'},
						{'info.splash.welcome4'},
					}
					for i, line in pairs(info) do
						local output = container.add({type="label", caption=line})
						output.style.single_line = false
						output.style.maximal_width = container.style.maximal_width - 20
					end
				end
			)
			dialog:addTab('rules', 
				{caption = {'info.rules.title'}, tooltip = {'info.rules.tooltip'}, }, 
				function(dialog, tab) -- tab instantiation.  
					-- Connect our buttons here.
				end,
				function(player, dialog, container) -- tab render
					local rules = {
						{'info.rules.disrespect'},
						{'info.rules.spam'},
						{'info.rules.concrete_by_bot'},
						{'info.rules.active_prov_chest'},
						{'info.rules.global_speakers'},
						{'info.rules.major_removal'},
						{'info.rules.excessive_map_reveal'},
						{'info.rules.remove_dislike'},
						{'info.rules.roundabouts'},
						--{'info.rules.train_direction'},
						{'info.rules.complain_lag'},
						{'info.rules.req_admin'},
						{'info.rules.admin_trump'},
					}
					for idx, rule in pairs(rules) do
						local output = container.add({type='label', caption={'info.rules.by_number', idx, rule}})
						output.style.single_line = false
						output.style.maximal_width = container.style.maximal_width - 20
					end
				end
			) -- end tab: rules
			dialog:addTab('comm',
				{caption = {'info.comm.title'}, tooltip = {'info.rules.tooltip'}, },
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					fields = {
						discord='fish-bus.net/discord',
						website='fish-bus.net',
						--[[ steam='http://steamcommunity.com/groups/....',]]
					}
					for section, value in pairs(fields) do
						container.add{type="label", caption={'info.comm.'..section..'_text'}}
						valuefield = container.add{type='text-box', text=value}
						valuefield.style.minimal_width = 400
						valuefield.selectable = true
					end
				end
			)
			dialog:addTab('chat',
				{caption = {'info.chat.title'}, tooltip = {'info.chat.tooltip'}},
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					local chatlabel = container.add({type="label", caption={'info.chat.message'}})
					chatlabel.style.single_line = false
					chatlabel.style.maximal_width = container.style.maximal_width - 20
				end
			)
			dialog:addTab('modinfo',
				{caption = {'info.modinfo.title'}, tooltip = {'info.modinfo.tooltip'}},
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					local info = {
						{line = {'info.modinfo.softmod_title'}},
						{line = {'info.modinfo.sm_market'}, icon = 'entity/market'},
						{line = {'info.modinfo.sm_fishbiz'}, icon = 'item/raw-fish'},
						{line = {'info.modinfo.sm_autodecon'}, icon = 'item/deconstruction-planner'},
						{line = {'info.modinfo.sm_fill4me'}, icon = 'item/uranium-rounds-magazine'},
						{line = {'info.modinfo.sm_deathmark'}, icon = 'entity/character-corpse'},
						{line = {'info.modinfo.sm_vehsnap'}, icon = 'entity/tank'},
						{line = {'info.modinfo.sm_flashlight'}, icon = 'item/battery'},
						{line = {'info.modinfo.sm_score'}, icon = 'entity/rocket-silo'},
						{line = {'info.modinfo.sm_time'}, icon = 'utility/clock'},
						{line = {'info.modinfo.sm_tag'}},
						{line = {'info.modinfo.sm_playlist'}, icon = 'entity/player'},
					}
					for i, entry in pairs(info) do
						local flow = container.add({type='flow', direction='horizontal'})
						if entry.icon then
							flow.add({type='sprite', sprite=entry.icon})
						end
						local output = flow.add({type="label", caption=entry.line})
						output.style.single_line = false
						output.style.maximal_width = container.style.maximal_width - 60
					end
				end
			)
			dialog:addTab('admins',
				{caption = {'info.admins.title'}, tooltip = {'info.admins.tooltip'}},
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					local info = {
						{'info.admins.info1'},
						{'info.admins.info2'},
						{'info.admins.info3'},
					}
					for i, line in pairs(info) do
						local output = container.add({type="label", caption=line})
						output.style.single_line = false
						output.style.maximal_width = container.style.maximal_width
					end
					kw_hline(container)
					
					info_drawAdminTable(container, player)
				end
			)
			dialog:addTab('players',
				{caption = {'info.players.title'}, tooltip = {'info.players.tooltip'}},
				function(dialog, tab) -- tab instantiation
					kw_connectDropdown('info_dd_filter', filterPlayersChanged)
				end,
				function(player, dialog, container) -- tab render
					local info = {
						{'info.players.info1'},
					}
					for i, line in pairs(info) do
						local output = container.add({type="label", caption=line})
						output.style.single_line = false
						output.style.maximal_width = container.style.maximal_width
					end
					local sortcont = container.add({name='order_table', type='table', column_count=4})
					local filter_dd = sortcont.add({name='info_dd_filter', type='drop-down'})
					kw_applyStyle(filter_dd, global.kw_style.sort_dropdown)
					for idx, localetext in pairs(kw_playerFilterList()) do
						filter_dd.add_item(localetext)
					end
					filter_dd.selected_index = kw_playerFilterByname('online')
					
					info_drawPlayerTable(container, player)
				end
			)
		end,
		function(player, dialog, container) -- dialog render
			-- on display
			--player.print("DEBUG: Trying to render server info")
		end
	)
end)

local function toggleInfo(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('info')
	dialog:toggleShow(player)
end


Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('info')
	if player.online_time < (game.speed * 60) then
		-- only show if online for less than 1 second (eg, new player)
		dialog:show(player)
	end
	kw_newToolbarButton(player, 'info_toggle', {'info.button_title'}, {'info.button_tooltip'}, nil, toggleInfo)
end)
