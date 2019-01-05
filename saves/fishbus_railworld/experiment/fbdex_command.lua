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


	fbdex_commands.lua
	
	Use FishBus DataEXchange to utilize certain additional commands.

--]]

require 'lib/event_extend'

require 'lib/fb_util' -- parseParms(...)

FBDX_Command = {}

function FBDX_Command.ban(username, message)
	if mod == nil or field == nil or callback == nil then
		error("Keystore.get(module, field, callback) - parameters must not be nil", 2)
	end
	FBDX_Command.write_op('ban', {
		user = user,
		message = message
	})
end

function FBDX_Command.version(mod, field)
	FBDX_Command.write_op('command_Version', {})
end

function FBDX_Command.write_op(op, parms)
	local content = "{\"op\": \"".. op .. "\""
	for field,value in pairs(parms) do
		content = content .. ", \""..field.."\": \"" ..value.. "\""
	end
	content = content .. "}"
	
	remote.call('mqueue', 'push', 'command', content)
end

commands.add_command('command.version', 'Returns the version of fbdex_command loaded', function(data)
	-- Command executed by external script when responding to a keystore.get
	-- request.  This will get the data, then call the provided 'get' callback.
	if data.parameter then
		local params = parseParams(data.parameter)
		log("params: " .. serpent.block(params))
	else
		log("WARN: command.version called with no parameters")
	end
end)

commands.add_command('command.ban', 'Notifies caller on result of a ban operation', function(data)
	-- Command executed by external script when responding to a keystore.set
	-- request.  Get the 'set' status, then call callback, if it exists.
	if data.parameter then
		local params = parseParams(data.parameter)
		log("params: " .. serpent.block(params))
	else
		log("WARN: command.ban called with no parameters")
	end
end)

local function initMod()
end

Event.register(Event.def("softmod_init"), function(event)
	initMod()
end)
