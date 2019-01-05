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
require 'lib/kwidget_table_with_header'
require 'permissions'

function testField(table, rownumber, field, celldata, settings)
	if not global.testcount then
		global.testcount = 0
	end
	global.testcount = global.testcount + 1
	local cell = table.add({
		type = "label",
		name = celldata.name or (rownumber .. field),
		caption = "blah" .. global.testcount,
	})
	return cell
end

function testSprite(table, rownumber, field, celldata, settings)
	local cell = table.add({
		type = "sprite",
		name = celldata.name or (rownumber .. field),
		sprite = celldata.sprite,
	})
	return cell
end

function test_headerClick(event, container, header_field)
	local element = event.element
	local headers = {
		{name='sprite', text='', field='sprite'},
		{name='col1', text='fizz', field='col1'},
		{name='col2', text='foo', field='col2'},
		{name='col3', text='bar', field='col3'},
	}
	local settings = { -- settings
		widths = { col1=100, col2=50, col3=200 },
		name = "TestTable",
		foo = 'bar',
		scrollpane = { width=545, height=265 },
		sortable_columns = {'col1', 'col2', 'col3'},
		sort_field = sortfield,
		sort_dir = sortdir or "desc",
		on_header_click = test_headerClick,
	}
	

	local dir = "desc"
	if kw_table_header_is_desc(element.caption) then
		dir = "asc"
	end
	local header = headers[1].name
	for idx, entry in pairs(headers) do
		if kw_table_header_name_for(container, entry, settings) == element.name then
			-- selected header
			header = entry.name
		end
	end
	test_drawTable(container, header, dir)
end

function test_drawTable(container, sortfield, sortdir)
	kw_table_draw(container,
		{
			{name='sprite', text='', field='sprite'},
			{name='col1', text='fizz', field='col1'},
			{name='col2', text='foo', field='col2'},
			{name='col3', text='bar', field='col3'},
		},
		{ -- data
			{col1='a1',  col2='x2',  col3=3},
			{col1='a4',  col2='x5',  col3=6},
			{col1='a7',  col2='x8',  col3=7},
			{col1='a10', col2='x11', col3=12},
			{col1='a13', col2='x14', col3=15},
			{col1='a16', col2='x17', col3=18},
			{col1='a19', col2='x20', col3=21},
			{col1='a22', col2='x23', col3=24},
			{col1='f1',  col2='c2',  col3=3},
			{col1='f4',  col2='c5',  col3=6},
			{col1='f7',  col2='c8',  col3=7},
			{col1='f10', col2='c11', col3=12},
			{col1='f13', col2='c14', col3=15},
			{col1='f16', col2='c17', col3=18},
			{col1='f19', col2='c20', col3=21},
			{col1='f22', col2='c23', col3=24},
			{col1='g1',  col2='a2',  col3=3},
			{col1='g4',  col2='a5',  col3=6},
			{col1='g7',  col2='a8',  col3=7},
			{col1='g10', col2='a11', col3=12},
			{col1='g13', col2='a14', col3=15},
			{col1='g16', col2='a17', col3=18},
			{col1='g19', col2='a20', col3=21},
			{col1='g22', col2='a23', col3=24},
			{
				sprite={render=testSprite, sprite="item/iron-axe"},
				col1={render=testField, sortvalue='blah'}, 
				col2='fizz', 
				col3={text='buzz', sortvalue=8}
			},
		},
		{ -- settings
			widths = { col1=100, col2=50, col3=200 },
			name = "TestTable",
			foo = 'bar',
			scrollpane = { width=545, height=265 },
			sortable_columns = {'col1', 'col2', 'col3'},
			sort_field = sortfield,
			sort_dir = sortdir or "desc",
			on_header_click = test_headerClick,
		}
	)
end

Event.register(Event.def("softmod_init"), function(event)
	kw_newTabDialog('test', 
		{caption="Test"},
		{position='center', defaultTab='test'}, 
		function(dialog) -- instantiation.
			-- must do button connections *outside* of any render functions.
			dialog:addTab('test', {caption = "test1", }, 
				function(dialog, tab) -- tab instantiation.  
					-- Connect our buttons here.
				end,
				function(player, dialog, container) -- tab render
					test_drawTable(container, 'col1')
				end
			) -- end tab: rules
		end,
		function(player, dialog, container) -- dialog render
			-- on display
			--player.print("DEBUG: Trying to render server info")
		end
	)
end)

local function toggleTest(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('test')
	dialog:toggleShow(player)
end


Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('test')
	dialog:show(player)
	kw_newToolbarButton(player, 'test_toggle', "TestGUI", '', nil, toggleTest)
end)
