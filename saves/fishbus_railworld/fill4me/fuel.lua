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

	fuel.lua

Functionality related to the handling of Fuels for Fill4Me.

--]]

Fuel = {}

-- 
-- Fuel functions (the ones you probably want to call)
-- 

function Fuel.categories()
	local cathash = {}
	local catlist = {}
	for name, proto in pairs(game.item_prototypes) do
		if proto.fuel_category then
			cathash[proto.fuel_category] = true
		end
	end
	for name, t in pairs(cathash) do
		table.insert(catlist, name)
	end
	return catlist
end

function Fuel.list()
	local fuellist = {}
	for name, proto in pairs(game.item_prototypes) do
		if proto.fuel_category then
			table.insert(fuellist, {
				name = proto.name,
				category = proto.fuel_category,
				i18n = proto.localised_name,
				max_size = math.ceil(proto.stack_size / 2),
				value = proto.fuel_value,
			})
		end
	end
	return fuellist
end

return Fuel
