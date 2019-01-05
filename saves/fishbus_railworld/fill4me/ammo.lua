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

	Ammo.lua

Functionality related to the handling of Ammo for Fill4Me.

--]]

Ammo = {}

-- 
-- General-purpose Ammo functions (the ones you probably want to call)
-- 

function Ammo.categories()
	local catlist = {}
	for name, proto in pairs(game.ammo_category_prototypes) do
		table.insert(catlist, name)
	end
	return catlist
end

-- Get a list of ammunition in the game, along with some properties of interest.
function Ammo.list()
	local ammolist = {}
	local item_craft_values = Ammo.price_list()
	for _, proto in pairs(game.item_prototypes) do
		-- evaluate ammunition items
		local ammotype = proto.get_ammo_type()
		if ammotype and ammotype.action then
			local damage = Ammo.damage_from_actions(ammotype.action)
			local radius = Ammo.radius_from_actions(ammotype.action)
			local data = {
				name = proto.name,
				category = ammotype.category,
				craft_value = item_craft_values[proto.name] or 0,
				damage = damage,
				i18n = proto.localised_name,
				max_size = math.ceil(proto.stack_size / 2),
				radius = radius,
			}
			table.insert(ammolist, data)
		elseif ammotype then
			log("Warning: Ammotype without action: " .. serpent.block(ammotype))
		end
	end
	return ammolist
end

function Ammo.price_list()
	-- get or build & get price list from factorio's pvp code.
	if not global.fill4me_internal then
		global.fill4me_internal = {}
	end
	if not global.fill4me_internal.price_list then
		global.fill4me_internal.price_list = production_score.generate_price_list()
	end
	return global.fill4me_internal.price_list
end

--
-- Damage
--
function Ammo.damage_from_action(action)
	local damage = 0
	if action.action_delivery then
		for _, ad in pairs(action.action_delivery) do
			local multiplier = 1
			if action.radius then
				multiplier = action.radius * action.radius * math.pi
			end
			damage = damage + Ammo.delivery_damage(ad) * multiplier
		end
	end
	return damage
end

function Ammo.damage_from_actions(actionset)
	local damage = 0
	for _, act in pairs(actionset) do
		damage = damage + Ammo.damage_from_action(act) * act.repeat_count
	end
	return damage
end

function Ammo.entity_attack_damage(entity_name)
	local ent = game.entity_prototypes[entity_name]
	local damage = 0
	if ent then
		if ent.attack_result then
			damage = damage + Ammo.damage_from_actions(ent.attack_result)
		end
		if ent.final_attack_result then
			damage = damage + Ammo.damage_from_actions(ent.final_attack_result)
		end
	end
	return damage
end

function Ammo.delivery_damage(ad)
	damage = 0
	if ad.type == 'instant' then
		if ad.target_effects then
			for _, te in pairs(ad.target_effects) do
				if te.action then
					damage = damage + Ammo.damage_from_actions(te.action)
				end
				if te.type == 'damage' then
					damage = damage + te.damage.amount
				end
				if te.type == 'create-entity' and te.entity_name then
					damage = damage + Ammo.entity_attack_damage(te.entity_name)
				end
			end
		end
	elseif ad.projectile then
		damage = damage + Ammo.entity_attack_damage(ad.projectile)
	elseif ad.stream then
		damage = damage + Ammo.entity_attack_damage(ad.stream)
	end
	return damage
end

--
-- Radius
--
function Ammo.radius_from_action(action)
	local radius = 0
	if action.action_delivery then
		for _, actdelivery in pairs(action.action_delivery) do
			if action.radius then
				radius = action.radius
			end
			radius = radius + Ammo.radius_of_delivery(actdelivery)
		end
	end
	return radius
end

function Ammo.radius_from_actions(actionset)
	local radius = 0
	for _, act in pairs(actionset) do
		radius = radius + Ammo.radius_from_action(act)
	end
	return radius
end

function Ammo.radius_from_entity(entity_name)
	local ent = game.entity_prototypes[entity_name]
	local radius = 0
	if ent then
		if ent.attack_result then
			radius = radius + Ammo.radius_from_actions(ent.attack_result)
		end
		if ent.final_attack_result then
			radius = radius + Ammo.radius_from_actions(ent.final_attack_result)
		end
	end
	return radius
end

function Ammo.radius_of_delivery(adelivery)
	radius = 0
	if adelivery.type == 'instant' then
		if adelivery.target_effects then
			for _, te in pairs(adelivery.target_effects) do
				if te.action then
					if te.action.radius then
						radius = radius + te.action.radius
					end
					radius = radius + Ammo.radius_from_actions(te.action)
				end
			end
		end
	elseif adelivery.projectile then
		radius = radius + Ammo.radius_from_entity(adelivery.projectile)
	elseif adelivery.stream then
		radius = radius + Ammo.radius_from_entity(adelivery.stream)
	end
	return radius
end

return Ammo
