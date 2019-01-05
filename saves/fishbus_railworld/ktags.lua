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

	ktags.lua - Kovus' Tags UI.
	
	Inspired by 3ra's Band UI.

Creates a way to use the player tag field to identify something useful
about that player, such as their current operation.

--]]

require 'lib/event_extend'
require 'lib/kwidgets'
require 'lib/color_conversions'

local tagdata = require 'ktags_roles'

KTags = {}
KTags.event_selected = Event.def("ktags.selected")

function KTags.init(event)
	if game then
		game.print("DEBUG: Initializing ktags")
	end
	if not global.ktags then
		global.ktags = {
			notify_all = true,
			roles = tagdata.roles,
			selection_ticks = {},
			tick_throttle = 360,
		}
	end
	kw_newDialog('ktags', 
		{caption={'ktags.name'}, direction = "vertical"},
		{position = 'left'},
		function(dialog) -- dialog instantiation
			kw_connectButtonMatch('ktags.select.(.-)', KTags.selectTag)
			kw_connectButton('ktags.close', KTags.toggle)
		end,
		function(player, dialog, container) -- dialog render
			container.add({type='label', caption={'ktags.header'}, })
			local tagtable = container.add({name='tagstable', type='table', column_count=4})
			for tag, tinfo in pairs(global.ktags.roles) do
				local icon = KTags.getTagIcon(tag)
				local ttip = {'ktags.tooltip.'..tag}
				if type(tinfo.i18n_name) == 'string' then
					-- Assume the tooltip isn't defined if the localization
					-- isn't defined.
					ttip = ''
				end
				local iconbutton = kw_newButton(tagtable, 'ktags.select.'..tag, '', ttip, icon, nil)
				local count = tagtable.add({
					type = 'label',
					name = 'membercount.'..tag,
					caption = 0,
				})
				local tagname = tagtable.add({type='label', caption=tinfo.i18n_name})
				tagname.style.font = "default-bold"
				tagname.style.right_padding = 4
				local memberlist = KTags.drawMemberList(tagtable, tag)
			end
			local otherbuttons = container.add({
				type='flow', 
				direction='horizontal',
			})
			local cleartag = kw_newButton(otherbuttons, 'ktags.select.', {'ktags.roles.clear'}, {'ktags.tooltip.clear'}, nil, nil)
			local closebutton = kw_newButton(otherbuttons, 'ktags.close', {'ktags.btn_close'}, {'ktags.btn_close_ttip'}, nil, nil)
			closebutton.style.font_color = { r = 1, g = 0.647, b = 0, a = 1 }
		end
	)
end

function KTags.drawMemberList(container, tag)
	if not tag or tag == '' then
		return nil
	end
	local playertable = container['tagplayers.'..tag]
	if playertable then
		playertable.clear()
	else
		playertable = container.add({
			name='tagplayers.'..tag, 
			type='table', 
			column_count=3
		})
	end
	local counter = 0
	for idx, player in pairs(game.connected_players) do
		if player.tag == "["..tag.."]" then
			local name = playertable.add({
				type = 'label',
				caption = player.name,
			})
			name.style.font_color = RGB01.brighten(player.color, 1.17, 50)
			name.style.top_padding = 0
			name.style.bottom_padding = 0
			name.style.left_padding = 0
			name.style.right_padding = 4
			counter = counter + 1
		end
	end
	container['membercount.'..tag].caption = counter
	return playertable
end

function KTags.getTagIcon(tagname)
	if tagname then
		local tinfo = global.ktags.roles[tagname]
		if tinfo and type(tinfo) == 'table' then
			return tinfo.icons[math.random(1, #tinfo.icons)]
		end
	end
	return "entity/player"
end

function KTags.notifyAll(event)
	if global.ktags.notify_all and event.tag and event.tag ~= "" then
		local player = game.players[event.player_index]
		local tinfo = global.ktags.roles[event.tag]
		if tinfo and tinfo.i18n_name then
			game.print({'ktags.notification', player.name, tinfo.i18n_name})
		end
	end
end

local function toggleInfo(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('ktags')
	dialog:toggleShow(player)
end
function KTags.toggle(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('ktags')
	dialog:toggleShow(player)
end

function KTags.onJoin(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('ktags')
	kw_newToolbarButton(player, 'ktags_toggle', {'ktags.button_title'}, {'ktags.button_tooltip'}, "", toggleInfo)
	-- Pretend this player has joined a group again.
	Event.dispatch({
		name = KTags.event_selected,
		tick = game.tick,
		player_index = event.player_index,
		tag = player.tag:sub(2,-2),
	})
end

function KTags.onLeave(event)
	-- Pretend this player has left a group, but don't notify everyone.
	local player = game.players[event.player_index]
	KTags.updateTable({
		name = KTags.event_selected,
		tick = game.tick,
		player_index = event.player_index,
		old_tag = player.tag:sub(2,-2),
	})
end

function KTags.selectTag(event)
	local player = game.players[event.player_index]
	-- check that the player hasn't done this too recently (throttling).
	local prev_tick = global.ktags.selection_ticks[event.player_index]
	if prev_tick then
		if prev_tick > event.tick - global.ktags.tick_throttle then
			player.print({'ktags.throttled'})
			return
		end
	end
	global.ktags.selection_ticks[event.player_index] = event.tick
	-- determine and set tag.
	local tag = event.element.name:match("ktags.select.(.*)")
	local previous_tag = player.tag:match("%[(.*)%]")
	if tag ~= "" then
		player.tag = "["..tag.."]"
	else
		player.tag = ''
	end
	Event.dispatch({
		name = KTags.event_selected,
		tick = game.tick,
		player_index = event.player_index,
		old_tag = previous_tag,
		tag = tag,
	})
end

function KTags.updateTable(event)
	local dialog = kw_getWidget('ktags')
	for idx, player in pairs(game.connected_players) do
		if dialog:is_open(player) then
			local widget = dialog:container(player)
			local tagtable = widget.tagstable
			if event.old_tag then
				KTags.drawMemberList(tagtable, event.old_tag)
			end
			if event.tag then
				KTags.drawMemberList(tagtable, event.tag)
			end
		end
	end
end

remote.add_interface("ktags", {
    getTagIcon = KTags.getTagIcon,
})

Event.register(Event.core_events.init, KTags.init)
Event.register(Event.def("softmod_init"), KTags.init)
Event.register(defines.events.on_player_joined_game, KTags.onJoin)
Event.register(defines.events.on_player_left_game, KTags.onLeave)
Event.register(KTags.event_selected, KTags.notifyAll)
Event.register(KTags.event_selected, KTags.updateTable)
