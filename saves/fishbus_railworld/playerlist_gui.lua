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

	playerlist_gui.lua - FishBus Player List (left-mounted)
	
	Note: this playerlist depends on kwidget_playertable, and uses the 
	playertable's colored names setting.  It's recommended to also use
	block_player_colors with this, as players can set an unusually low alpha
	value otherwise, which can make reading their name impossible.
--]]

require 'lib/event_extend'
require 'mod-gui'

require 'lib/kwidgets'
require 'lib/kwidget_playertable'
require 'permissions'


function pl_gui_drawPlayerTable(container, player)
	local walkdist = false
	local drivedist = false
	local traindist = false
	local totaldist = false
	if remote.interfaces['pdistance'] then
		walkdist = true
		drivedist = true
		traindist = false
		totaldist = false
	end
	kw_playerTable(container
		, 'playerTable' -- name
		, nil -- players
		, { -- settings
			pl_sourceName=player.name,
			status=false,
			distances={walked=walkdist, driven=drivedist, trained=traindist, total=totaldist},
			scrollpane = { width=470, height=300 },
			connected_players = true,
			use_player_colors = true,
		  }
		, nil -- filter function
		, nil -- actions function
	)
end

Event.register(Event.def("softmod_init"), function(event)
	kw_newDialog('pl_gui', 
		{
			caption={'playerlist.window_title'},
		},
		{position='left', width=480}, 
		function(dialog) -- instantiation.
			
		end,
		function(player, dialog, container) -- tab render
			local info = {
			}
			for i, line in pairs(info) do
				local output = container.add({type="label", caption=line})
				output.style.single_line = false
				output.style.maximal_width = container.style.maximal_width
			end
			pl_gui_drawPlayerTable(container, player)
		end
	)
end)

function pl_gui_updatePlayerTable(event)
	local dialog = kw_getWidget('pl_gui')
	local options = {
		update_icon = false,
	}
	if event.name == Event.def("ktags.selected") then
		options.update_icon = true
	end
	for _, player in pairs(game.connected_players) do
		local container = dialog:container(player)
		if container then
			kw_playerTable_update(container, event.player_index, options)
		end
	end
end

function pl_gui_updateHeight(player)
	local dialog = kw_getWidget('pl_gui')
	local container = dialog:container(player)
	if dialog and container then
		local pane_size = 90 + math.min(35 * #game.players, 35 * 10)
		container.style.minimal_height = pane_size
		container.style.maximal_height = pane_size
		container.table_scrollpane.style.minimal_height = pane_size-90
		container.table_scrollpane.style.maximal_height = pane_size-90
	
		pl_gui_drawPlayerTable(container, player)
	end
end

local function togglePlayerlist(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('pl_gui')
	dialog:toggleShow(player)
	pl_gui_updateHeight(player)
end


Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('pl_gui')
	kw_newToolbarButton(player, 'pl_gui_toggle', nil, {'playerlist.button_tooltip'}, "entity/player", togglePlayerlist)
	-- Update GUI entries for other players.
	for _, player in pairs(game.connected_players) do
		pl_gui_updateHeight(player)
	end
end)

Event.register(defines.events.on_player_left_game, function(event)
	local player = game.players[event.player_index]
	for _, player in pairs(game.connected_players) do
		pl_gui_updateHeight(player)
	end
end)

Event.register(Event.def("perms.user_group_change"), pl_gui_updatePlayerTable)
Event.register(Event.def("player_color_change"), pl_gui_updatePlayerTable)
Event.register(Event.def("player_distance_update"), pl_gui_updatePlayerTable)
Event.register(Event.def("player_time_1_min"), pl_gui_updatePlayerTable)
Event.register(Event.def("ktags.selected"), pl_gui_updatePlayerTable)
