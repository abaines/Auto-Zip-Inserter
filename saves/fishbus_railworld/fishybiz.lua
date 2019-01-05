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

	fishbiz.lua

	Spend fish to upgrade your player!

--]]

require 'lib/event_extend'

require 'lib/kwidgets'

fishbiz = {}

function fishbiz.bankadmin_change_proximity(event)
	local player = game.players[event.player_index]
	if fishbiz.can_admin(player.index) then
		--local container = kw_getWidget('fish_biz'):container(player)['tabPane']
		if event.element.selected_index == 1 then
			global.fishbiz.require_market_proximity = true
		else
			global.fishbiz.require_market_proximity = false
		end
		player.print({'fishbiz.bankadmin.updated_proximity', global.fishbiz.require_market_proximity})
	end
end

function fishbiz.bank_redraw_balance(plidx, container)
	if container.balflow then
		if container.balflow.balance then
			local pldata = fishbiz.player_data(plidx)
			container.balflow.balance.caption = pldata.balance
		end
	end
end

function fishbiz.bank_mgr_table_hclick(event, container, header_field)
	local element = event.element
	local dir = "desc"
	if kw_table_header_is_desc(element.caption) then
		dir = "asc"
	end
	for idx, entry in ipairs({'player', 'balance'}) do
		if kw_table_header_name_for(container, {name = entry}, {}) == element.name then
			-- selected header
			header = entry
		end
	end
	fishbiz.draw_bank_mgr_table(player, container, header, dir)
end

function fishbiz.can_admin(plidx)
	if game.players[plidx].admin then
		return true
	end
	if perms and perms.userHasPermission(game.players[plidx].name, 'bankadmin.manager') then
		return true
	end

	return false
end

function fishbiz.can_do_bank_transaction(plidx)
	-- check if the user is within X units of a fish market, so they can do
	-- bank transactions.  (Arbitrary restriction to add to 'realism' or
	-- annoyance of game.)
	if global.fishbiz.require_market_proximity then
		local player = game.players[plidx]
		local playerpos = player.position
		local dist = 10
		local range = {
			{playerpos.x - dist, playerpos.y - dist},
			{playerpos.x + dist, playerpos.y + dist}
		}
		if #player.surface.find_entities_filtered({area=range, type='market'}) > 0 then
			return true
		end
		return false
	end
	return true
end

function fishbiz.deposit(plidx, value)
	local player = game.players[plidx]
	if not fishbiz.can_do_bank_transaction(plidx) then
		player.print({'fishbiz.bank.deposit_not_available'})
		return
	end
	local pldata = fishbiz.player_data(plidx)
	-- check that we're not depositing more than the max bank value fish.
	if pldata.balance + value > global.fishbiz.max_bank_value then
		value = global.fishbiz.max_bank_value - pldata.balance
		player.print({'fishbiz.bank.deposit_limited', value, global.fishbiz.max_bank_value})
	end
	-- remove provided value (-1 if not enough)
	local removed = fishbiz.remove_fish(plidx, value, false)
	if removed < 0 then
		player.print({'fishbiz.bank.deposit_not_enough', fishcount, value})
		return
	end
	-- deposit to bank.
	pldata.balance = pldata.balance + removed
	player.print({'fishbiz.bank.deposited', removed})
	return pldata.balance
end

function fishbiz.deposit_all(plidx)
	local player = game.players[plidx]
	local inv1 = player.get_inventory(defines.inventory.player_main)
	local inv2 = player.get_inventory(defines.inventory.player_quickbar)
	local fishcount = inv1.get_item_count('raw-fish') + inv2.get_item_count('raw-fish')
	return fishbiz.deposit(plidx, fishcount)
end

function fishbiz.draw_bank_mgr_table(player, container, sortfield, sortdir)
	local headers = {
		{name='player',  text={'fishbiz.bankadmin.h_player'}, field='player'},
		{name='balance', text={'fishbiz.bankadmin.h_balance'},  field='balance'},
	}
	local data = {}
	for idx, player in pairs(game.players) do
		pldata = fishbiz.player_data(player.index)
		if pldata then
			table.insert(data, {
				player = {text=player.name, font='default-bold'},
				balance = {text=pldata.balance},
			})
		end
	end
	local settings = {
		widths = { player=150, balance=100 },
		name = "PlayerBalanceTable",
		scrollpane = { width=500, height=190 },
		sortable_columns = {'player', 'balance'},
		sort_field = sortfield,
		sort_dir = sortdir,
		on_header_click = fishbiz.bank_mgr_table_hclick,
	}
	kw_table_draw(container, headers, data, settings)
end


function fishbiz.event_deposit(event)
	local amount = tonumber(event.element.parent.dep_value.text)
	if amount then
		fishbiz.deposit(event.player_index, amount)
		fishbiz.bank_redraw_balance(event.player_index, event.element.parent.parent)
	else
		local player = game.players[event.player_index]
		player.print({'fishbiz.bank.invalid_amount'})
	end
end
function fishbiz.event_deposit_all(event)
	fishbiz.deposit_all(event.player_index, amount)
	fishbiz.bank_redraw_balance(event.player_index, event.element.parent.parent)
end
function fishbiz.event_withdraw(event)
	local amount = tonumber(event.element.parent.wd_value.text)
	if amount then
		fishbiz.withdraw(event.player_index, amount)
		fishbiz.bank_redraw_balance(event.player_index, event.element.parent.parent)
	else
		local player = game.players[event.player_index]
		player.print({'fishbiz.bank.invalid_amount'})
	end
end
function fishbiz.event_withdraw_all(event)
	fishbiz.withdraw_all(event.player_index, amount)
	fishbiz.bank_redraw_balance(event.player_index, event.element.parent.parent)
end

function fishbiz.event_set_interest_rate(event)
	local player = game.players[event.player_index]
	if fishbiz.can_admin(player.index) then
		local set2 = event.element.parent
		local rate = tonumber(set2['fishbiz.bankadmin.intrate'].text)
		global.fishbiz.interest_rate = rate
		player.print({'fishbiz.bankadmin.updated_intrate', rate, (rate - 1) * 100})
	end
end

function fishbiz.interest_tick(event)
	local tpd = game.surfaces.nauvis.ticks_per_day
	if event.tick % tpd == tpd / 2 then
		local intrate = global.fishbiz.interest_rate
		for idx, player in pairs(game.players) do
			local pldata = fishbiz.player_data(player.index)
			pldata.balance = math.min(math.floor(pldata.balance * intrate + 0.5), global.fishbiz.max_bank_value)
		end
	end
end

function fishbiz.player_data(plidx)
	if not global.fishbiz.players[plidx] then
		global.fishbiz.players[plidx] = {
			balance = 0,
		}
	end
	return global.fishbiz.players[plidx]
end

function fishbiz.remove_fish(plidx, value, include_bank)
	local player = game.players[plidx]
	local pldata = fishbiz.player_data(plidx)
	local inv1 = player.get_inventory(defines.inventory.player_main)
	local inv2 = player.get_inventory(defines.inventory.player_quickbar)
	local available = 0
	if include_bank then
		available = available + pldata.balance
	end
	available = available + inv1.get_item_count('raw-fish')
	available = available + inv2.get_item_count('raw-fish')
	if available < value then
		return -1
	end
	local needed = value
	-- get through our sources, and remove fish:
	if needed > 0 and inv2.get_item_count('raw-fish') > 0 then
		local toremove = math.min(needed, inv2.get_item_count('raw-fish'))
		inv2.remove({name='raw-fish', count=toremove})
		needed = needed - toremove
	end
	if needed > 0 and inv1.get_item_count('raw-fish') > 0 then
		local toremove = math.min(needed, inv1.get_item_count('raw-fish'))
		inv1.remove({name='raw-fish', count=toremove})
		needed = needed - toremove
	end
	if needed > 0 and include_bank and pldata.balance > 0 then
		local toremove = math.min(needed, pldata.balance)
		pldata.balance = pldata.balance - toremove
		needed = needed - toremove
	end
	if not needed == 0 then
		game.print("DEBUG: Unexpected condition: fishbiz.remove_fish - remaining needed != 0")
	end
	return value
end

function fishbiz.withdraw(plidx, value)
	local player = game.players[plidx]
	if value <= 0 then
		player.print({'fishbiz.bank.withdraw_0'})
		return
	end
	if not fishbiz.can_do_bank_transaction(plidx) then
		player.print({'fishbiz.bank.withdraw_not_available'})
		return
	end
	local pldata = fishbiz.player_data(plidx)
	if pldata.balance < value then
		player.print({'fishbiz.bank.withdraw_not_enough_fish', pldata.balance, value})
		return
	end
	local inv1 = player.get_inventory(defines.inventory.player_main)
	if inv1.can_insert({name='raw-fish', count=value}) then
		local actual_insert = inv1.insert({name='raw-fish', count=value})
		pldata.balance = pldata.balance - actual_insert
		player.print({'fishbiz.bank.withdraw', actual_insert})
		return pldata.balance
	end
end

function fishbiz.withdraw_all(plidx)
	local pldata = fishbiz.player_data(plidx)
	return fishbiz.withdraw(plidx, pldata.balance)
end


function fishbiz.init(event)
	global.fishbiz = {
		interest_rate = 1.02,
		max_bank_value = 1000000,
		require_market_proximity = true,
		players = {},
	}

	kw_newTabDialog('fish_biz',
		{caption={'fishbiz.window_title'}},
		{position='center', defaultTab='bank'},
		function(dialog)
			dialog:addTab('bank',
				{caption = {'fishbiz.bank.title'}, tooltip = {'fishbiz.bank.tooltip'}, },
				function(dialog, tab) -- instantiation.
					-- button connections, etc
					kw_connectButton('fishbiz.bank.deposit', fishbiz.event_deposit)
					kw_connectButton('fishbiz.bank.deposit_all', fishbiz.event_deposit_all)
					kw_connectButton('fishbiz.bank.withdraw', fishbiz.event_withdraw)
					kw_connectButton('fishbiz.bank.withdraw_all', fishbiz.event_withdraw_all)
				end,
				function(player, dialog, container) -- dialog render
					-- on display
					container.add({name='aboutmsg', type='label', caption={'fishbiz.bank.about'}})
					container.aboutmsg.style.single_line = false
					container.aboutmsg.style.maximal_width = container.style.maximal_width

					-- balance
					local balflow = container.add({name='balflow', type='flow', direction='horizontal'})
					balflow.add({name='baltext', type='label', caption={'fishbiz.bank.balance_text'}})
					balflow.baltext.style.font = 'default-large'
					balflow.add({type='sprite', sprite='item/raw-fish'})
					local pldata = fishbiz.player_data(player.index)
					local balance = pldata.balance
					balflow.add({name='balance', type='label', caption={'fishbiz.bank.balance', balance} })
					balflow.balance.style.font = 'default-large'
					balflow.balance.style.font_color = { r=1, g=1, b=0, a=1 }
					kw_hline(container)
					-- deposit
					local depflow = container.add({type='flow', direction='horizontal'})
					depflow.add({name='dep_value', type='textfield', text='0'})
					kw_newButton(depflow, 'fishbiz.bank.deposit', {'fishbiz.bank.deposit_btn_text'}, {'fishbiz.bank.deposit_btn_tooltip'}, nil, button_style)
					kw_newButton(depflow, 'fishbiz.bank.deposit_all', {'fishbiz.bank.deposit_all_btn_text'}, {'fishbiz.bank.deposit_all_btn_tooltip'}, nil, button_style)

					kw_hline(container)
					-- withdraw
					local wdflow = container.add({type='flow', direction='horizontal'})
					wdflow.add({name='wd_value', type='textfield', text='0'})
					kw_newButton(wdflow, 'fishbiz.bank.withdraw', {'fishbiz.bank.withdraw_btn_text'}, {'fishbiz.bank.withdraw_btn_tooltip'}, nil, button_style)
					kw_newButton(wdflow, 'fishbiz.bank.withdraw_all', {'fishbiz.bank.withdraw_all_btn_text'}, {'fishbiz.bank.withdraw_all_btn_tooltip'}, nil, button_style)
				end
			) -- end upgrades
			dialog:addTab('bankadmin',
				{
					caption = {'fishbiz.bankadmin.title'}, tooltip = {'fishbiz.bankadmin.tooltip'}, 
					showif_func = fishbiz.can_admin,
				},
				function(dialog, tab) -- instantiation.
					-- button connections, etc
					kw_connectDropdown('bankadmin_proximity', fishbiz.bankadmin_change_proximity)
					kw_connectButton('bankadmin.set_intrate', fishbiz.event_set_interest_rate)
				end,
				function(player, dialog, container) -- dialog render
					-- on display
					local settings1 = container.add({name='settings1', type='table', column_count=2})
					settings1.add({type='label', caption={'fishbiz.bankadmin.proximity_title'}})
					settings1.add({name='bankadmin_proximity', type='drop-down'})
					settings1.bankadmin_proximity.add_item({'fishbiz.bankadmin.prox_required'})
					settings1.bankadmin_proximity.add_item({'fishbiz.bankadmin.prox_not_required'})
					local sel_idx = 1
					if global.fishbiz.require_market_proximity == false then
						sel_idx = 2
					end
					settings1.bankadmin_proximity.selected_index = sel_idx

					local set2 = container.add({name='set2', type='table', column_count=3})
					set2.add({type='label', caption={'fishbiz.bankadmin.intrate_title'}})
					set2.add({type='textfield', name='fishbiz.bankadmin.intrate', text=global.fishbiz.interest_rate})
					kw_newButton(set2, 'bankadmin.set_intrate', {'fishbiz.bankadmin.set_intrate_title'}, {'fishbiz.bankadmin.set_intrate_tooltip'}, nil, nil)


					fishbiz.draw_bank_mgr_table(player, container, 'player', 'desc')
				end
			) -- end upgrades
		end
	)
end

local function fishbiz_toggle(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('fish_biz')
	dialog:toggleShow(player)
end

Event.register(Event.def("softmod_init"), fishbiz.init)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('fish_biz')
	kw_newToolbarButton(player, 'fish_biz_toggle', {'fishbiz.button_title'}, {'fishbiz.button_tooltip'}, 'item/raw-fish', fishbiz_toggle)
end)

Event.register(defines.events.on_tick, fishbiz.interest_tick)
