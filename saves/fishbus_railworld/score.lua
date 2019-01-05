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

	FishBus Gaming - Game score.
	
	Inspired from a mod called 'score'
	Implements:
	- a biter kill count
	- rocket launched score
	- items launched
	- items received from launches

--]]

require 'lib/event_extend'
require 'lib/kwidgets'

local function mod_initialize()
	if not global.score then
		global.score = {
			rockets_launched = 0,
			biters_killed = 0,
			items_launched = {},
			items_received = {},
		}
	end
	global.scorestyle = {
		rocket_text = {
			font = "default-bold",
			font_color = { r=0.98, g=0.11, b=0.11 },
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 4,
			right_padding = 4,
		},
		biter_text = {
			font = "default-bold",
			font_color = { r=0.98, g=0.66, b=0.22 },
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 4,
			right_padding = 4,
		},
		launched_text = {
			font = "default-bold",
			font_color = { r=1, g=1, b=1 },
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 4,
			right_padding = 4,
		},
		item_table = {
			left_padding = 15,
		},
	}
end
mod_initialize()
Event.register(Event.def("softmod_init"), function(event)
	mod_initialize()
end)

function score_refresh_counts(player)
	if not player then
		-- event happened, refresh for ALL players
		for idx, player in pairs(game.connected_players) do
			score_refresh_counts(player)
		end
		return
	end
	local score = kw_getWidget('score')
	local container = score:container(player)
	if container then
		if not container.scoretable then
			initDialog()
		end
		container.scoretable.rocket_count.caption = global.score.rockets_launched
		container.scoretable.biters_count.caption = global.score.biters_killed
		
		if table_size(global.score.items_launched) > 0 then
			container.sentlabel.style.visible = true
		else
			container.sentlabel.style.visible = false
		end
		for name, count in pairs(global.score.items_launched) do
			local s_table = container.senttable
			if not s_table["count_" .. name] then
				s_table.add { type = 'label', caption = game.item_prototypes[name].localised_name}
				s_table.add { type = 'label', name = "count_" .. name, caption = count}
			else
				s_table["count_" .. name].caption = count
			end
		end
		if table_size(global.score.items_received) > 0 then
			container.recvlabel.style.visible = true
		else
			container.recvlabel.style.visible = false
		end
		for name, count in pairs(global.score.items_received) do
			local r_table = container.recvtable
			if not r_table["count_" .. name] then
				r_table.add { type = 'label', caption = game.item_prototypes[name].localised_name}
				r_table.add { type = 'label', name = "count_" .. name, caption = count}
			else
				r_table["count_" .. name].caption = count
			end
		end
		
	end
end

local function initDialog()
	kw_newDialog('score', 
		{caption={'score.name'}, direction = "vertical"},
		{position = 'left'},
		function(dialog) -- dialog instantiation
			
		end,
		function(player, dialog, container) -- dialog render
			-- show score (biters + rockets)
			container.add({type='label', caption={'score.scoreheader'}, })
			local scoretable = container.add({name='scoretable', type='table', column_count=2})
			local item = nil
			item = scoretable.add({type='label', caption={'score.rocket_text'} })
			--kw_applyStyle(item, global.scorestyle.rocket_text)
			item = scoretable.add({type='label', name='rocket_count', caption=0})
			--kw_applyStyle(item, global.scorestyle.rocket_text)
			item = scoretable.add({type='label', caption={'score.biters_text'} })
			--kw_applyStyle(item, global.scorestyle.biter_text)
			item = scoretable.add({type='label', name='biters_count', caption=0})
			--kw_applyStyle(item, global.scorestyle.biter_text)
			
			-- show inventory (sent & received)
			local sentlabel = container.add({name='sentlabel', type='label', caption={'score.sentheader'}, })
			local senttable = container.add({name='senttable', type='table', column_count=2})
			local recvlabel = container.add({name='recvlabel', type='label', caption={'score.recvheader'}, })
			local recvtable = container.add({name='recvtable', type='table', column_count=2})
			
			score_refresh_counts(player)
		end
	)
end

local function toggleDisplay(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('score')
	dialog:toggleShow(player)
end

local function drawScoreButton(player)
	kw_newToolbarButton(player, 'btn_score', {'score.btn_name'}, {'score.btn_tooltip'}, 'item/rocket-silo', toggleDisplay)
end


local function rocket_launched(event)
	global.score.rockets_launched = global.score.rockets_launched + 1
	--game.print ("A rocket has been launched!")
	
	local launch_inventory = event.rocket.get_inventory(defines.inventory.chest)
	if launch_inventory and launch_inventory.get_item_count() > 0 then
		--game.print("Rocket inventory? " .. launch_inventory[1].name)
		local item = launch_inventory[1]
		local count = item.count
		if global.score.items_launched[item.name] then
			count = count + global.score.items_launched[item.name]
		end
		global.score.items_launched[item.name] = count
	end
	
	local received_inventory = event.rocket_silo.get_output_inventory()
	if received_inventory and received_inventory.get_item_count() > 0 then
		--game.print("Receive inventory? " .. received_inventory[1].name)
		local item = received_inventory[1]
		local count = item.count
		if global.score.items_received[item.name] then
			count = count + global.score.items_received[item.name]
		end
		global.score.items_received[item.name] = count
	end
	
	score_refresh_counts()
end

local function biter_kill_counter(event)	
	if event.entity.force.name == "enemy" then
		global.score.biters_killed = global.score.biters_killed + 1
		score_refresh_counts()
	end
end

Event.register(Event.def("softmod_init"), function(event)
	initDialog()
end)

Event.register(defines.events.on_entity_died, biter_kill_counter)
Event.register(defines.events.on_rocket_launched, rocket_launched)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	drawScoreButton(player)
	local dialog = kw_getWidget('score')
	--dialog:show(player)
end)

