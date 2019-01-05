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

	fish_perks_gui.lua - FishBus Perks info GUI
	
UI elements to display the perks you have and how close you are to the next
level.

May eventually be extended to "purchasable" perks.  The sort of things you
can't really be explained as something you did over and over in the game,
such as bonus inventory/logistic slots.

NOTE: this code is VERY TIGHTLY COUPLED with fish_perks.lua, and directly
references globals and such.  It's seperated out for clarity.

--]]

require 'lib/event_extend'
require 'mod-gui'

require 'lib/kwidgets'
require 'lib/kwidget_playertable'

require 'fish_perks'

FishPerksGUI = {
	dialog_style = {
		minimal_height = 320,
		maximal_height = 320,
		minimal_width = 550,
		maximal_width = 550,
	},
}

function FishPerksGUI.init(event)
	if not global.fish_perks_gui then
		global.fish_perks_gui = {
			players = {},
		}
	end
	kw_newTabDialog('perks', 
		{caption={'fish_perks.gui.exp.title'}},
		{position='center', defaultTab='exp', dialog_style_data = FishPerksGUI.dialog_style}, 
		function(dialog) -- instantiation.
			-- must do button connections *outside* of any render functions.
			dialog:addTab('exp',
				{caption = {'fish_perks.gui.exp.title'}, tooltip = {'fish_perks.gui.exp.tooltip'}},
				function(dialog, tab) -- tab instantiation
					
				end,
				function(player, dialog, container) -- tab render
					container.add({name='perkmsg', type='label', caption={'fish_perks.gui.aboutmsg'}})
					container.perkmsg.style.single_line = false
					container.perkmsg.style.maximal_width = container.style.maximal_width

					FishPerksGUI.drawXPTable(player, container, 'perk', 'desc')
				end
			)
			dialog:addTab('selectable',
				{caption = {'fish_perks.gui.select.title'}, tooltip = {'fish_perks.gui.select.tooltip'}},
				function(dialog, tab) -- instantiation
					for name, perk in pairs(global.fbperks.defs.selectable.selectable_perks) do
						kw_connectButton('perks_select.btn.'..perk.name, FishPerksGUI.eventSelectButton)
					end
				end,
				function(player, dialog, container) -- render
					container.add({name='msg', type='label', caption={'fish_perks.gui.select.about'}})
					container.msg.style.single_line = false
					container.msg.style.maximal_width = container.style.maximal_width
					container.add({
						name = 'available_levels', 
						type = 'label',
						caption = {'fish_perks.gui.select.available', 0},
					})
					FishPerksGUI.updateSelectAvailability(player, container)
					FishPerksGUI.drawSelectTable(player, container, 'perk', 'desc')
				end
			)
		end,
		function(player, dialog, container) -- dialog render
			-- on display
			--player.print("DEBUG: Trying to render server info")
		end
	)
	kw_newDialog('smallxp', 
		{caption=nil, direction = "vertical"},
		{position = 'left'},
		function(dialog) -- dialog instantiation
			-- connect buttons for tracking...
			for name, perk in pairs(global.fbperks.defs) do
				kw_connectButton('perks_track.btn.'..perk.name, function(event)
					local perkname = string.sub(event.element.name, 17)
					local player = game.players[event.player_index]
					local pldata = FishPerksGUI.playerData(event.player_index)
					local perkplayer = FishPerks.getPlayerByID(event.player_index)
					local widget = kw_getWidget('smallxp')
					if pldata.active_sxp == perkname then
						pldata.active_sxp = nil
						if widget:is_open(player) then
							widget:toggleShow(player)
						end
					else
						pldata.active_sxp = perkname
						if not widget:is_open(player) then
							widget:toggleShow(player)
						end
						FishPerksGUI.drawSmallXP(player.index, widget:container(player))
					end
					perkplayer:set_track(pldata.active_sxp)
				end)
			end
		end,
		function(player, dialog, container) -- dialog render
			FishPerksGUI.drawSmallXP(player.index, container)
		end
	)
end

function FishPerksGUI.drawSmallXP(player_index, container)
	-- show small xp bar.
	local pldata = FishPerksGUI.playerData(player_index)
	local perkplayer = FishPerks.getPlayerByID(player_index)
	if pldata.active_sxp then
		local selperk = global.fbperks.defs[pldata.active_sxp]
		if not selperk then
			return
		end
		if not container.perkWithPercent then
			container.add({
				type = 'label',
				name = 'perkWithPercent',
			})
		end
		if not container.perkProgress then
			container.add({
				type = 'progressbar', 
				name = 'perkProgress',
				value = 0,
			})
		end
		container.perkWithPercent.caption = {
			'fish_perks.gui.exp.namewithpercent', 
			{'fish_perks.gui.exp.'..selperk.name},
			math.floor(perkplayer:percent(selperk.name)*100),
			perkplayer:level(selperk.name).value,
		}
		container.perkProgress.value = perkplayer:percent(selperk.name)
	else
		if not container.perkWithPercent then
			container.add({
				type = 'label',
				name = 'perkWithPercent',
			})
		end
		container.perkWithPercent.caption = {'fish_perks.gui.exp.no_perk_watch'}
		if container.perkProgress then
			container.perkProgress.destroy()
		end
	end
end

local function toggleInfo(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('perks')
	dialog:toggleShow(player)
end

local function toggleSmallXP(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('smallxp')
	dialog:toggleShow(player)
end

function FishPerksGUI.xpbar(table, rownumber, field, celldata, settings)
	local bar = table[rownumber..field]
	if bar then
		bar.value = celldata.percent
	else
		bar = table.add({
			type="progressbar",
			value=celldata.percent,
		})
	end
	return bar
end

function FishPerksGUI.renderTrackButton(table, rownumber, field, celldata, settings)
	local perkname = celldata.perkname
	local tooltip = {'fish_perks.gui.exp.track_tooltip', {"fish_perks.gui.exp."..perkname}}
	button = kw_newButton(table, 'perks_track.btn.'..perkname, {'fish_perks.gui.exp.track_button'}, {'fish_perks.gui.exp.track_tooltip'}, nil, nil)
	return button
end

function FishPerksGUI.renderSelectButton(table, rownumber, field, celldata, settings)
	local perkname = celldata.perkname
	local tooltip = {'fish_perks.gui.select.improve_tooltip', {"fish_perks.gui.select."..perkname}}
	button = kw_newButton(table, 'perks_select.btn.'..perkname, {'fish_perks.gui.select.improve_button'}, tooltip, nil, nil)
	return button
end

function FishPerksGUI.eventSelectButton(event)
	local perkname = string.sub(event.element.name, 18)
	FishPerks.select_bonus(event.player_index, perkname)
	local container = event.element.parent.parent.parent
	local player = game.players[event.player_index]
	FishPerksGUI.updateSelectAvailability(player, container)
	FishPerksGUI.drawSelectTable(player, container, 'perk', 'desc')
end

function FishPerksGUI.drawXPTable(player, container, sortfield, sortdir)
	local headers = {
		{name='perk',  field='perk',  text={'fish_perks.gui.exp.h_perk'}},
		{name='level', field='level', text={'fish_perks.gui.exp.h_level'}},
		{name='xp',    field='xp',    text={'fish_perks.gui.exp.h_xp'}},
		{name='track', field='track', text={'fish_perks.gui.exp.h_track'}},
	}
	local data = {}
	local pldata = FishPerksGUI.playerData(player.index)
	local perkplayer = FishPerks.getPlayerByID(player.index)
	for name, perk in pairs(global.fbperks.defs) do
		if perk.enabled then
			table.insert(data, {
				perk = {
					text={"fish_perks.gui.exp."..perk.name}, 
					sortvalue=perk.name,
					font='default-bold',
				},
				level = {
					text={"fish_perks.gui.current_level", perkplayer:level(perk.name).value, perk.max_level},
					sortvalue = perkplayer:level(perk.name).value
				},
				xp = {
					render=FishPerksGUI.xpbar,
					percent=perkplayer:percent(perk.name),
					sortvalue=perkplayer:xp(perk.name).value,
				},
				track = {
					render = FishPerksGUI.renderTrackButton,
					perkname = perk.name,
				},
			})
		end
	end
	if not sortfield then
		sortfield = pldata.last_sort_field
	end
	if not sortdir then
		sortdir = pldata.last_sort_dir
	end
	local settings = {
		widths = { perk=150, level=50, xp=200 },
		name = "XP Table",
		scrollpane = { width=500, height=250 },
		sortable_columns = {'perk', 'level', 'xp'},
		on_header_click = FishPerksGUI.xpTableHeaderClick,
		sort_field = sortfield,
		sort_dir = sortdir,
	}
	pldata.last_sort_field = sortfield
	pldata.last_sort_dir = sortdir
	kw_table_draw(container, headers, data, settings)
end

function FishPerksGUI.updateSelectAvailability(player, container)
	local perkplayer = FishPerks.getPlayerByID(player.index)
	local sperkplayer = perkplayer:level('selectable')
	if not sperkplayer.bonuses then 
		sperkplayer.bonuses = {}
	end
	local levels = 0
	for name, sperk in pairs(global.fbperks.defs.selectable.selectable_perks) do
		if sperkplayer.bonuses[sperk.name] then
			levels = levels + sperkplayer.bonuses[sperk.name].level
		end
	end
	container.available_levels.caption = {'fish_perks.gui.select.available', sperkplayer.value - levels}
end

function FishPerksGUI.drawSelectTable(player, container, sortfield, sortdir)
	local headers = {
		{name='perk',  field='perk',  text={'fish_perks.gui.select.h_perk'}},
		{name='level', field='level', text={'fish_perks.gui.select.h_level'}},
		{name='pick',  field='pick',  text={'fish_perks.gui.select.h_pick'}},
	}
	local data = {}
	local pldata = FishPerksGUI.playerData(player.index)
	local perkplayer = FishPerks.getPlayerByID(player.index)
	local sperkplayer = perkplayer:level('selectable')
	if not sperkplayer.bonuses then 
		sperkplayer.bonuses = {}
	end
	for name, sperk in pairs(global.fbperks.defs.selectable.selectable_perks) do
		local level = 0
		if sperkplayer.bonuses[sperk.name] then
			level = sperkplayer.bonuses[sperk.name].level
		end
		table.insert(data, {
			perk = {
				text={"fish_perks.gui.select."..sperk.name}, 
				sortvalue=sperk.name,
				font='default-bold',
			},
			level = {
				text={"fish_perks.gui.current_level", level, sperk.max_level},
				sortvalue = level,
			},
			pick = {
				render = FishPerksGUI.renderSelectButton,
				perkname = sperk.name,
			},
		})
	end
	if not sortfield then
		sortfield = pldata.select_sort_field
	end
	if not sortdir then
		sortdir = pldata.select_sort_dir
	end
	local settings = {
		widths = { perk=150, level=50, pick=100 },
		name = "XP Table",
		scrollpane = { width=500, height=200 },
		sortable_columns = {'perk', 'level'},
		on_header_click = nil, -- FishPerksGUI.xpTableHeaderClick,
		sort_field = sortfield,
		sort_dir = sortdir,
	}
	pldata.select_sort_field = sortfield
	pldata.select_sort_dir = sortdir
	kw_table_draw(container, headers, data, settings)
end

function FishPerksGUI.on_join(event)
	local player = game.players[event.player_index]
	kw_newToolbarButton(player, 'perks_toggle', {'fish_perks.gui.button_title'}, {'fish_perks.gui.button_tooltip'}, nil, toggleInfo)
end

function FishPerksGUI.playerData(player_index)
	local pld = global.fish_perks_gui.players[player_index]
	if not pld then
		global.fish_perks_gui.players[player_index] = {
			last_sort_field = 'perk',
			last_sort_dir = 'desc',
			active_sxp = nil,
		}
		pld = global.fish_perks_gui.players[player_index]
	end
	return pld
end

function FishPerksGUI.update_values(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('perks') 
	if dialog:is_open(player) then
		local instance = dialog:container(player)
		-- gotta make sure we're on the right tab...
		if instance and instance.tabPane and instance.tabPane.perkmsg then
			FishPerksGUI.drawXPTable(player, instance.tabPane, nil, nil)
		end
		-- check for being on the other perks tab.
		if instance and instance.tabPane and instance.tabPane.available_levels then
			FishPerksGUI.updateSelectAvailability(player, instance.tabPane)
		end
	end
	local smdialog = kw_getWidget('smallxp')
	if smdialog:is_open(player) then
		local instance = smdialog:container(player)
		-- gotta make sure we're on the right tab...
		if instance then
			FishPerksGUI.drawSmallXP(player.index, instance)
		end
	end
end

function FishPerksGUI.xpTableHeaderClick(event, container, header_field)
	local element = event.element
	local dir = "desc"
	if kw_table_header_is_desc(element.caption) then
		dir = "asc"
	end
	for idx, entry in ipairs({'perk', 'level', 'xp'}) do
		if kw_table_header_name_for(container, {name = entry}, {}) == element.name then
			-- selected header
			header = entry
		end
	end
	FishPerksGUI.drawXPTable(player, container, header, dir)
end

Event.register(Event.def("softmod_init"), FishPerksGUI.init)
Event.register(defines.events.on_player_joined_game, FishPerksGUI.on_join)
Event.register(Event.def("perk_update"), FishPerksGUI.update_values)
