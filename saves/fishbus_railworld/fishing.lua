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

	fishing.lua
	
	Controls how fish (currency) are gained.  Also maintains information on how
people pick them up.


--]]

require 'lib/event_extend'

local function mod_initialize(event)
	if not global.fishing then
		global.fishing = {
			total_caught = 0,
			players = {},
		}
	end
end

local function insert_fish(player_index, amount)
	local player = game.players[player_index]
	player.insert { name = "raw-fish", count = amount }
	
	if not global.fishing.players[player_index] then
		global.fishing.players[player_index] = {
			gathered = 0,
		}
	end
	fpl = global.fishing.players[player_index]
	fpl.gathered = fpl.gathered + amount
end

local function preplayer_mined_item(event)
	--game.print(event.entity.name)
	--game.print(event.entity.type)
	
	-- don't mix up if it's a typed or named entity!
	-- 'fish chance' is "1 in fishchance".  So, fishchance=2 is 50%
	-- fishchance=5 is 20%.
	local checks = {
		{type = 'resource', fishcount = 2, fishchance = 5},
		{name = 'rock-huge', fishcount = 15},
		{name = 'rock-big', fishcount = 12},
		{name = 'rock-medium', fishcount = 10},
		{name = 'rock-small', fishcount = 7},
		{name = 'rock-tiny', fishcount = 3},
		{name = 'sand-rock-big', fishcount = 13},
		{name = 'sand-rock-medium', fishcount = 10},
		{name = 'sand-rock-small', fishcount = 7},
		{type = 'tree', fishcount = 2, fishchance = 3},
	}
	for idx, check in pairs(checks) do
		local use_check = false
		if check.type and event.entity.type == check.type then
			use_check = true
		end
		if check.name and event.entity.name == check.name then
			use_check = true
		end
		if use_check then
			if check.fishchance then
				local rnd = math.random(1, check.fishchance)
				if rnd == 1 then
					insert_fish(event.player_index, check.fishcount)
				end
			else
				insert_fish(event.player_index, check.fishcount)
			end
			break
		end
	end
end

local function fish_drop_entity_died(event)
	if event.entity.force.name == "enemy" then
		if math.random(1,5) == 5 then
			local surface = event.entity.surface
    		local count = math.random(1,2)
    		surface.spill_item_stack(event.entity.position, { name = 'raw-fish', count = count }, 1)
		end
	end
end

local function player_picked_up_item(event)
	if event.item_stack.name == 'raw-fish' then
		local amount = event.item_stack.count or 1
		if not global.fishing.players[event.player_index] then
			global.fishing.players[event.player_index] = {
				gathered = 0,
			}
		end
		fpl = global.fishing.players[event.player_index]
		fpl.gathered = fpl.gathered + amount
	end
end

Event.register(defines.events.on_pre_player_mined_item, preplayer_mined_item)
Event.register(defines.events.on_entity_died, fish_drop_entity_died)
Event.register(defines.events.on_picked_up_item, player_picked_up_item)
Event.register(Event.def("softmod_init"), mod_initialize)
