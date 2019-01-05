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

	automessage.lua
	
	Inspired by ExplosiveGamer's automessage concept.
	
	Displays a periodic informational message to certain groups.
	
--]]

require 'permissions'
require 'lib/fb_util' -- player lookup by name

function autoMessage()
	if not game.connected_players then
		return
	end
	
	perms.executeOnGroupUsers('moderator', true, false, {}, function(playerName)
		local player = getPlayerNamed(playerName)
		if #game.connected_players ~= 1 then
			player.print({'automessage.players_online', #game.connected_players})
		else
			player.print({'automessage.players_online_single', #game.connected_players})
		end
		player.print({'automessage.runtime', ticktohour(game.tick), ticktominutes(game.tick % ticksPerHour())})
	end)
	perms.executeOnGroupUsers('regular', true, false, {}, function(playerName)
		local player = getPlayerNamed(playerName)
		player.print({'automessage.join_us'})
		player.print({'automessage.discord', "fish-bus.net/discord"})
		--player.print({'automessage.website', "fish-bus.net"})
		player.print({'automessage.see_links'})
		--player.print({'automessage.trains'})
	end)
end

remote.add_interface("automessage", {
	send = autoMessage,
})

-- Periodic automessage.  Uncomment to use.
--[[
Event.register(defines.events.on_tick, function(event)
	if (game.tick/(3600*game.speed)) % 15 == 1 then
		autoMessage()
	end
end)
--]]