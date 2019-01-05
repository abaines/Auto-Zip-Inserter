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

	block_player_colors.lua - restrictions on player colors
	
	Once we put player colors into the player list, it become fairly obvious
	that we needed to restrict players from using colors that were impossible
	to read in the player list (and it turns out, on the map).
	Specifically, any colors with too low of an alpha value (0) to be readable.

--]]

require 'lib/event_extend'
require 'lib/color_conversions'

local badgray = RGB.toLAB({r=0.27, g=0.27, b=0.27})

--[[
Notes about colors in Lab:
Luminosity is great for determining whether or not something is too dark, when
it is actually a color.  But the a & b values are interesting too.  As colors
go to grey, a & b become go towards 0.  (Some colors have negative a/b values.)

Taking an abs(a)+abs(b) and checking that for close to 0 might help identify
bad values for luminosity too.  The closer they are to 0, the higher of a
luminosity is required in order for it to be legible on both text & GUI elements.
(GUI Elements are largely grey, so a bright grey is required for legibility.)
--]]

function checkPlayerColor(event)
	if event.command == "color" then
		local player = game.players[event.player_index]
		local color = player.color
		if color.a < 0.5 then
			player.print({'bpc.alpha_low', 0.5})
			color.a = 0.5
			player.color = color
			player.chat_color = color
		end
		-- convert to LAB to get lightness value.
		-- player color values are in the 0..1 range.
		local labc = RGB01.toLAB(color)
		--player.print("DEBUG: " .. serpent.block(player.color))
		--player.print("DEBUG: " .. serpent.block(labc))
		if labc.L < 50 then -- red is 43.5327...
			-- purple is 33.8, but it's not *that* bad to most people.
			if labc.A + labc.B < 5 or labc.L < 30 then
				local newcolor = RGB01.brighten(color, 1.17, 50)
				player.print({'bpc.lightened_self'}, newcolor)
				resetPlayerColor(player, newcolor)
			end
		end
		Event.dispatch({
			name = Event.def('player_color_change'),
			tick = game.tick,
			player_index = event.player_index,
			color = player.color,
			chat_color = player.chat_color,
		})
	end
end

function resetPlayerColor(player, color)
	if not color then
		color = {r = 1, g = 1, b = 1, a = 1}
	end
	if not color.a then
		color.a = 1
	end
	player.color = color
	player.chat_color = color
end

Event.register(defines.events.on_console_command, checkPlayerColor)
Event.register(defines.events.on_player_joined_game, checkPlayerColor)
