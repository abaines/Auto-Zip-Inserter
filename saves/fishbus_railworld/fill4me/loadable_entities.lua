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

	loadable_entities.lua

Functionality related to entities which can load fuel or ammo.

--]]

LoadEnts = {}

-- 
-- General-purpose LoadEnds functions (the ones you probably want to call)
-- 

function LoadEnts.list_of_fireables()
	local entities = {}
	for name, proto in pairs(game.entity_prototypes) do
		local loadable = false
		local edata = {
			name = name,
		}
		if proto.attack_parameters and proto.attack_parameters.ammo_category then
			loadable = true
			edata.direct = true
			edata.ammo_category = proto.attack_parameters.ammo_category
		end
		if proto.guns then
			for type, gunproto in pairs(proto.guns) do
				if gunproto.attack_parameters.ammo_category then
					local gundata = {
						name = gunproto.name,
						ammo_category = gunproto.attack_parameters.ammo_category,
					}
					if not edata.guns then
						loadable = true
						edata.guns = {}
					end
					table.insert(edata.guns, gundata)
				end
			end
		end
		if loadable then
			table.insert(entities, edata)
		end
	end
	return entities
end

function LoadEnts.list_of_fuelables()
	local entities = {}
	for name, proto in pairs(game.entity_prototypes) do
		local loadable = false
		local edata = {
			name = name,
		}
		if proto.burner_prototype then
			loadable = true
			edata.fuel_categories = proto.burner_prototype.fuel_categories
		end
		
		if loadable then
			table.insert(entities, edata)
		end
	end
	return entities
end

--


return LoadEnts
