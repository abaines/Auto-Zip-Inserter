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


	FishBus Gaming - Game time.
	
Show a small dialog displaying the current game day & time.
--]]

require 'lib/event_extend'
require 'lib/kwidgets'
require 'lib/fb_util'

gt = {}
function gt.init(event)
	global.gametime_dirty = true
	global.gametime_value = gt.datetime(0, game.surfaces[1])
	global.gametime_days = 0
	-- day starts at noon, so start half a day off.
	global.gametime_daytick = 0 - game.surfaces[1].ticks_per_day
end
Event.register(Event.def("softmod_init"), gt.init)

function gt.datetime(tick, surface)
	-- surface.daytime is a float (0->1) starting at noon.
	local daysec = 86400 * surface.daytime
	
	-- returns hour & min as table
	local tpd = surface.ticks_per_day -- ticks/day
	
	if global.gametime_daytick then
		if tick - global.gametime_daytick > tpd*0.9 and surface.daytime > 0.5 then
			global.gametime_daytick = tick
			global.gametime_days = global.gametime_days + 1
		end
	end
	
	local day = global.gametime_days or 0
	local hour = math.floor(daysec / 3600)
	local min = math.floor((daysec % 3600) / 60)
	local sec = math.floor((daysec % 60))
	local ampm = "am"
	if hour < 12 then
		ampm = "pm"
	end
	hour = hour % 12
	if hour == 0 then
		hour = 12
	end
	return {
		years = math.floor(day / 365),
		day_in_year = day % 365,
		days = day,
		hours = hour,
		minutes = min,
		seconds = sec,
		ampm = ampm,
	}
end

function gt.refresh(player)
	if not player then
		-- event happened, refresh for ALL players
		for idx, player in pairs(game.connected_players) do
			gt.refresh(player)
		end
		return
	end
	if global.gametime_dirty then
		global.gametime_value = gt.datetime(game.tick, player.surface)
		global.gametime_dirty = false
	end
	
	local widget = kw_getWidget('gametime')
	local container = widget:container(player)
	if container then
		if not container.timestring then
			initDialog()
		end
		local dt = global.gametime_value
		container.timestring.caption = {
			'gametime.datestring', 
			dt.day_in_year+1, dt.hours, string.format("%02d", dt.minutes), dt.ampm,
			string.format("%02d", dt.seconds), dt.years+1,
		}
	end
end

local function initDialog()
	kw_newDialog('gametime', 
		{caption=nil, direction = "vertical"},
		{position = 'left'},
		function(dialog) -- dialog instantiation
			
		end,
		function(player, dialog, container) -- dialog render
			-- show score (biters + rockets)
			container.add({
				name = 'timestring',
				type = 'label', 
				caption = {'gametime.datestring', 0, 0, 0, 0}, 
			})
			gt.refresh(player)
		end
	)
end

local function toggleDisplay(event)
	local player = game.players[event.player_index]
	local dialog = kw_getWidget('gametime')
	dialog:toggleShow(player)
end

local function drawGametimeButton(player)
	kw_newToolbarButton(player, 'btn_gametime', {'gametime.btn_name'}, {'gametime.btn_tooltip'}, 'utility/clock', toggleDisplay)
end


Event.register(Event.def("softmod_init"), function(event)
	initDialog()
end)

Event.register(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	drawGametimeButton(player)
	local dialog = kw_getWidget('gametime')
	dialog:show(player)
end)

Event.register(defines.events.on_tick, function(event)
	if event.tick % 60 == 1 then
		global.gametime_dirty = true
		gt.refresh()
	end
end)
