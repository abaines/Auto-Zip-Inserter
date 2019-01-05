--[[
	fish_perks_definition.lua
--]]

return {
	sample = {
		-- This is just a sample for documentation purposes.
		name = 'sample', -- must be the same as the name
		enabled = false,
		perk = 'character_running_speed_modifier', -- the modifier for 
		base_units_per_level = 10, -- units required per level.
		--units_scaling_per_level = 0.1, -- not implemented.
		max_level = 20,
		increase = 0.1,
		-- increase_scaling_per_level = -0.1 -- not implemented
	},
	driven = {
		name = 'driven',
		enabled = false,
		perk = 'friction_modifier', -- or effectivity_modifier?
		base_units_per_level = 10, -- 10000,
		--scaling_per_level = 0.1,
		max_level = 20,
		increase = -0.01,
	},
	handcrafted = {
		name = 'handcrafted',
		enabled = true,
		perk = 'character_crafting_speed_modifier',
		base_units_per_level = 25000, -- this number seems to have no effect above a certain value
		--scaling_per_level = 0.1,
		max_level = 50,
		increase = 0.05,
	},
	healed = {
		name = 'healed',
		enabled = true,
		perk = 'character_health_bonus',
		base_units_per_level = 4000, -- 250, -- must take enough damage to die?
		--scaling_per_level = 0.1,
		max_level = 25,
		increase = 10, -- 15 * 10 + 250 base = 400 health!
	},
	mined = {
		name = 'mined',
		enabled = true,
		perk = 'character_mining_speed_modifier',
		base_units_per_level = 1250, -- 10000,
		--scaling_per_level = 0.1,
		max_level = 20,
		increase = 0.15,
	},
	placed = {
		name = 'placed',
		enabled = true,
		perk = 'character_build_distance_bonus',
		base_units_per_level = 1500,
		--scaling_per_level = 0.1,
		max_level = 20,
		increase = 1,
	},
	selectable = {
		-- this is a special perk.  Its value is derived from other perks.
		name = 'selectable',
		enabled = true,
		perk = {},	
		base_units_per_level = 325,
		max_level = 30,
		increase = 1,
		-- these fields are unique to selectable perks:
		rate = 0.5,
		selectable_perks = {
			qbslots = {
				name = 'qbslots',
				perk = 'quickbar_count_bonus',
				per_level = 1, -- each level is 10 new slots.
				max_level = 2, -- more than 2 causes clipping of text chat in combo with research.
			},
			invslots = {
				name = 'invslots',
				perk = 'character_inventory_slots_bonus',
				per_level = 5, -- 10 slots per line
				max_level = 20,
			},
			logslots = {
				name = 'logslots',
				perk = 'character_logistic_slot_count_bonus',
				per_level = 3, -- 6 slots per line...
				max_level = 2,
			},
			trashslots = {
				name = 'trashslots',
				perk = 'character_trash_slot_count_bonus',
				per_level = 3, -- 6 slots per line...
				max_level = 2,
			},
			followbot = {
				name = 'followbot',
				perk = 'character_maximum_following_robot_count_bonus',
				per_level = 10,
				max_level = 5,
			},
		},
	},
	walked = {
		name = 'walked', -- must be the same as the name
		enabled = true,
		perk = 'character_running_speed_modifier',
		base_units_per_level = 7000, -- 10000
		--scaling_per_level = 0.1,
		max_level = 30,
		increase = 0.06,
	},
}
