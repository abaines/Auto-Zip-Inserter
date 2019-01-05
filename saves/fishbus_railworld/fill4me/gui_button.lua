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

	gui_button.lua

Adds a gui button to enable/disable Fill4Me.

--]]

-- Cannot require this twice, as it appears to break things.
--require '/lib/kwidgets'

fill4me_gui = {}

function fill4me_gui.addinCreateButton(event)
	-- This is primarily here to create the button if this mod is added to an
	-- existing game.
	if game and game.players then
		for idx, player in pairs(game.players) do
			fill4me_gui.drawButton(player)
		end
	end
end

-- Button for disabling/enabling autofill
function fill4me_gui.drawButton(player)
	kw_newToolbarButton(player, "btn_toolbar_fill4me", {'fill4me.gui.enable_btn'}, {'fill4me.gui.enable_tooltip'}, 'item/uranium-rounds-magazine', fill4me_gui.toggle)
end

function fill4me_gui.toggle(event)
	fill4me.toggle(event.player_index)
end	

function fill4me_gui.onJoinDoButton(event)
	global.count = 0
	local player = game.players[event.player_index]
	fill4me_gui.drawButton(player)
end

-- Event to create the button.
Event.register(Event.def("softmod_init"), fill4me_gui.addinCreateButton)
Event.register(defines.events.on_player_joined_game, fill4me_gui.onJoinDoButton)
