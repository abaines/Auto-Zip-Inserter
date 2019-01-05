--[[
Copyright 2018 "Kovus" <kovus@soulless.wtf>

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

	commands.lua

Commands for Fill4Me.  (Precursor to a UI)

--]]

fill4me_cmd = {}

function fill4me_cmd.max_percent(event)
	local player = game.players[event.player_index]
	if event.parameter then
		local percent = tonumber(event.parameter)
		if percent and percent > 0 and percent <= 100 then
			local pldata = fill4me.player(event.player_index)
			pldata.max_load_percent = percent / 100
			player.print({'fill4me.prefix', {'fill4me.cmd.set_max_percent', percent}})
		else
			-- display error
			player.print({'fill4me.prefix', {'fill4me.cmd.error_max_percent'}})
			player.print({'fill4me.cmd.usage_max_percent'})
			player.print({'fill4me.cmd.example', {'fill4me.cmd.example_max_percent'}})
		end
	else
		-- display error, provide help text.
		player.print({'fill4me.prefix', {'fill4me.cmd.error_max_percent'}})
		player.print({'fill4me.cmd.usage_max_percent'})
		player.print({'fill4me.cmd.example', {'fill4me.cmd.example_max_percent'}})
	end
end

function fill4me_cmd.toggle(event)
	fill4me.toggle(event.player_index)
end

commands.add_command('f4m.toggle', {'fill4me.gui.enable_tooltip'}, fill4me_cmd.toggle)
commands.add_command('f4m.max_percent', {'fill4me.cmd.help_max_percent'}, fill4me_cmd.max_percent)
