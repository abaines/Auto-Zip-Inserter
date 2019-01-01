--Factorio Cave Miner -- mewmew made this --
--You can use /c map_pregen() command to pre-generate the world before playing to avoid any possible microstutter while playing.--
--Use /c spaghetti() to play without bots.

local simplex_noise = require 'utils.simplex_noise'
local Event = require 'utils.event' 
local market_items = require "maps.cave_miner_market_items"

local function create_cave_miner_button(player)		
	if player.gui.top["caver_miner_stats_toggle_button"] then player.gui.top["caver_miner_stats_toggle_button"].destroy() end	
	local b = player.gui.top.add({ type = "sprite-button", name = "caver_miner_stats_toggle_button", sprite = "item/iron-axe" })
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function create_cave_miner_info(player)	
	local frame = player.gui.left.add {type = "frame", name = "cave_miner_info", direction = "vertical"}
	local t = frame.add {type = "table", column_count = 1}	
	
	local tt = t.add {type = "table", column_count = 3}
	local l = tt.add {type = "label", caption = " --Cave Miner-- "}
	l.style.font = "default-frame"
	l.style.font_color = {r=0.6, g=0.3, b=0.99}
	l.style.top_padding = 6	
	l.style.bottom_padding = 6
	
	local l = tt.add {type = "label", caption = " *diggy diggy hole* "}
	l.style.font = "default"
	l.style.font_color = {r=0.99, g=0.99, b=0.2}
	l.style.minimal_width = 280	
	
	local b = tt.add {type = "button", caption = "X", name = "close_cave_miner_info", align = "right"}	
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	local tt = t.add {type = "table", column_count = 1}
	local frame = t.add {type = "frame"}
	local l = frame.add {type = "label", caption = global.cave_miner_map_info}
	l.style.single_line = false	
	l.style.font_color = {r=0.95, g=0.95, b=0.95}	
end

local function create_cave_miner_stats_gui(player)	
	if player.gui.top["hunger_frame"] then player.gui.top["hunger_frame"].destroy() end
	if player.gui.top["caver_miner_stats_frame"] then player.gui.top["caver_miner_stats_frame"].destroy() end
	
	local captions = {}
	local caption_style = {{"font", "default-bold"}, {"font_color",{ r=0.63, g=0.63, b=0.63}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local stat_numbers = {}
	local stat_number_style = {{"font", "default-bold"}, {"font_color",{ r=0.77, g=0.77, b=0.77}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local separators = {}
	local separator_style = {{"font", "default-bold"}, {"font_color",{ r=0.15, g=0.15, b=0.89}}, {"top_padding",2}, {"left_padding",2},{"right_padding",2},{"minimal_width",0}}
	
	local frame = player.gui.top.add { type = "frame", name = "hunger_frame"}
	
	local str = tostring(global.player_hunger[player.name])
	str = str .. "% "
	str = str .. global.player_hunger_stages[global.player_hunger[player.name]]
	local caption_hunger = frame.add { type = "label", caption = str  }
	caption_hunger.style.font = "default-bold"
	caption_hunger.style.font_color = global.player_hunger_color_list[global.player_hunger[player.name]]
	caption_hunger.style.top_padding = 2		
	
	local frame = player.gui.top.add { type = "frame", name = "caver_miner_stats_frame" }
	
	local t = frame.add { type = "table", column_count = 11 }						
	
	captions[1] = t.add { type = "label", caption = "Ores mined:" }
	
	global.total_ores_mined = global.stats_ores_found + game.forces.player.item_production_statistics.get_input_count("coal") + game.forces.player.item_production_statistics.get_input_count("iron-ore") + game.forces.player.item_production_statistics.get_input_count("copper-ore") + game.forces.player.item_production_statistics.get_input_count("uranium-ore")	
	
	stat_numbers[1] = t.add { type = "label", caption = global.total_ores_mined }
			
	separators[1] = t.add { type = "label", caption = "|"}
	
	captions[2] = t.add { type = "label", caption = "Rocks broken:" }
	stat_numbers[2] = t.add { type = "label", caption = global.stats_rocks_brocken }
							
	separators[2] = t.add { type = "label", caption = "|"}
	
	captions[3] = t.add { type = "label", caption = "Efficiency" }
	local x = math.ceil(game.forces.player.manual_mining_speed_modifier * 100 + global.player_hunger_buff[global.player_hunger[player.name]] * 100, 0)
	local str = ""
	if x > 0 then str = str .. "+" end
	str = str .. tostring(x)
	str = str .. "%"		
	stat_numbers[3] = t.add { type = "label", caption = str }
		
	if game.forces.player.manual_mining_speed_modifier > 0 or game.forces.player.mining_drill_productivity_bonus > 0 then	
		separators[3] = t.add { type = "label", caption = "|"}
		
		captions[5] = t.add { type = "label", caption = "Fortune" }	
		local str = "+"
		str = str .. tostring(game.forces.player.mining_drill_productivity_bonus * 100)
		str = str .. "%"	
		stat_numbers[4] = t.add { type = "label", caption = str }
		
	end	
	
	for _, s in pairs (caption_style) do
		for _, l in pairs (captions) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (stat_number_style) do
		for _, l in pairs (stat_numbers) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (separator_style) do
		for _, l in pairs (separators) do
			l.style[s[1]] = s[2]
		end
	end
	stat_numbers[1].style.minimal_width = 9 * string.len(tostring(global.stats_ores_found))
	stat_numbers[2].style.minimal_width = 9 * string.len(tostring(global.stats_rocks_brocken))
end

local function refresh_gui()
	for _, player in pairs(game.connected_players) do
		local frame = player.gui.top["caver_miner_stats_frame"]
		if (frame) then			
			create_cave_miner_button(player)
			create_cave_miner_stats_gui(player)					
		end
	end
end

local function treasure_chest(position)
	local p = game.surfaces[1].find_non_colliding_position("wooden-chest",position, 2,0.5)
	if not p then return end
	
	treasure_chest_raffle_table = {}
	treasure_chest_loot_weights = {}
	table.insert(treasure_chest_loot_weights, {{name = 'iron-gear-wheel', count = math.random(16,48)},10})	
	table.insert(treasure_chest_loot_weights, {{name = 'coal', count = math.random(16,48)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'copper-cable', count = math.random(64,128)},10})
	table.insert(treasure_chest_loot_weights, {{name = 'inserter', count = math.random(8,16)},4})		
	table.insert(treasure_chest_loot_weights, {{name = 'fast-inserter', count = math.random(4,8)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-filter-inserter', count = math.random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-inserter', count = math.random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-inserter', count = math.random(16,32)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'electric-engine-unit', count = math.random(1,16)},3})		
	table.insert(treasure_chest_loot_weights, {{name = 'rocket-fuel', count = math.random(1,5)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'empty-barrel', count = math.random(1,10)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'lubricant-barrel', count = math.random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'crude-oil-barrel', count = math.random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-stick', count = math.random(1,100)},8})
	table.insert(treasure_chest_loot_weights, {{name = "small-electric-pole", count = math.random(8,32)},9})
	table.insert(treasure_chest_loot_weights, {{name = "firearm-magazine", count = math.random(16,48)},8})
	table.insert(treasure_chest_loot_weights, {{name = 'grenade', count = math.random(16,32)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'land-mine', count = math.random(24,48)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'light-armor', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'heavy-armor', count = 1},2})		
	table.insert(treasure_chest_loot_weights, {{name = 'pipe', count = math.random(10,100)},6})		
	table.insert(treasure_chest_loot_weights, {{name = 'wooden-chest', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-mining-drill', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-axe', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'steel-axe', count = 1},3})
	table.insert(treasure_chest_loot_weights, {{name = 'raw-wood', count = math.random(5,50)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'sulfur', count = math.random(20,50)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'explosives', count = math.random(20,50)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'shotgun', count = 1},2})
	table.insert(treasure_chest_loot_weights, {{name = 'stone-brick', count = math.random(80,100)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'small-lamp', count = math.random(3,10)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'rail', count = math.random(32,100)},4})	
	table.insert(treasure_chest_loot_weights, {{name = 'coin', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-1', count = math.random(1,4)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-2', count = math.random(1,3)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-3', count = math.random(1,2)},1})		
	for _, t in pairs (treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(treasure_chest_raffle_table, t[1])
		end			
	end
	
	
	local e = game.surfaces[1].create_entity {name="wooden-chest",position=p, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(3,7), 1 do
		local loot = treasure_chest_raffle_table[math.random(1,#treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

function rare_treasure_chest(position)
	local p = game.surfaces[1].find_non_colliding_position("steel-chest",position, 2,0.5)
	if not p then return end
	
	local rare_treasure_chest_raffle_table = {}
	local rare_treasure_chest_loot_weights = {}
	table.insert(rare_treasure_chest_loot_weights, {{name = 'combat-shotgun', count = 1},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-shotgun-shell', count = math.random(16,48)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'flamethrower', count = 1},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket-launcher', count = 1},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'flamethrower-ammo', count = math.random(16,48)},5})		
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket', count = math.random(16,48)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'explosive-rocket', count = math.random(16,48)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'modular-armor', count = 1},3})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'power-armor', count = 1},1})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'uranium-rounds-magazine', count = math.random(16,48)},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-rounds-magazine', count = math.random(64,128)},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun', count = 1},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun-dart', count = math.random(16,48)},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'exoskeleton-equipment', count = 1},2})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'defender-capsule', count = math.random(8,16)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'distractor-capsule', count = math.random(4,8)},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'destroyer-capsule', count = math.random(4,8)},3})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'atomic-bomb', count = 1},1})		
	for _, t in pairs (rare_treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(rare_treasure_chest_raffle_table, t[1])
		end			
	end
	
	local e = game.surfaces[1].create_entity {name="steel-chest",position=p, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(2,3), 1 do
		local loot = rare_treasure_chest_raffle_table[math.random(1,#rare_treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

local function secret_shop(pos)
	local secret_market_items = {		
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'combat-shotgun'}},
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'flamethrower'}},
    {price = {{"raw-fish", math.random(75,125)}}, offer = {type = 'give-item', item = 'rocket-launcher'}},
    {price = {{"raw-fish", math.random(2,4)}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    {price = {{"raw-fish", math.random(8,16)}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine'}},  
    {price = {{"raw-fish", math.random(8,16)}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell'}},
    {price = {{"raw-fish", math.random(6,12)}}, offer = {type = 'give-item', item = 'flamethrower-ammo'}},
    {price = {{"raw-fish", math.random(8,16)}}, offer = {type = 'give-item', item = 'rocket'}},
    {price = {{"raw-fish", math.random(10,20)}}, offer = {type = 'give-item', item = 'explosive-rocket'}},        
    {price = {{"raw-fish", math.random(15,30)}}, offer = {type = 'give-item', item = 'explosive-cannon-shell'}},
    {price = {{"raw-fish", math.random(25,35)}}, offer = {type = 'give-item', item = 'explosive-uranium-cannon-shell'}},   
    {price = {{"raw-fish", math.random(20,40)}}, offer = {type = 'give-item', item = 'cluster-grenade'}}, 
	{price = {{"raw-fish", math.random(1,3)}}, offer = {type = 'give-item', item = 'land-mine'}},	
    {price = {{"raw-fish", math.random(250,500)}}, offer = {type = 'give-item', item = 'modular-armor'}},
    {price = {{"raw-fish", math.random(1500,3000)}}, offer = {type = 'give-item', item = 'power-armor'}},
	{price = {{"raw-fish", math.random(15000,20000)}}, offer = {type = 'give-item', item = 'power-armor-mk2'}},
    {price = {{"raw-fish", math.random(4000,7000)}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment'}},
    {price = {{"raw-fish", math.random(50,100)}}, offer = {type = 'give-item', item = 'battery-equipment'}},
    {price = {{"raw-fish", math.random(700,1100)}}, offer = {type = 'give-item', item = 'battery-mk2-equipment'}},
    {price = {{"raw-fish", math.random(400,700)}}, offer = {type = 'give-item', item = 'belt-immunity-equipment'}},
    {price = {{"raw-fish", math.random(12000,16000)}}, offer = {type = 'give-item', item = 'night-vision-equipment'}},
    {price = {{"raw-fish", math.random(300,500)}}, offer = {type = 'give-item', item = 'exoskeleton-equipment'}},
    {price = {{"raw-fish", math.random(350,500)}}, offer = {type = 'give-item', item = 'personal-roboport-equipment'}},
    {price = {{"raw-fish", math.random(25,50)}}, offer = {type = 'give-item', item = 'construction-robot'}},
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'energy-shield-equipment'}},
    {price = {{"raw-fish", math.random(350,550)}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment'}},    
    {price = {{"raw-fish", math.random(125,250)}}, offer = {type = 'give-item', item = 'railgun'}},
    {price = {{"raw-fish", math.random(2,4)}}, offer = {type = 'give-item', item = 'railgun-dart'}},
	{price = {{"raw-fish", math.random(100,175)}}, offer = {type = 'give-item', item = 'loader'}},
	{price = {{"raw-fish", math.random(200,350)}}, offer = {type = 'give-item', item = 'fast-loader'}},
	{price = {{"raw-fish", math.random(400,600)}}, offer = {type = 'give-item', item = 'express-loader'}}
	}
	local surface = game.surfaces[1]										
	local market = surface.create_entity {name = "market", position = pos}
	market.destructible = false	
	local market_items_to_add = math.random(8,12)
	while market_items_to_add >= 0 do		
		local i = math.random(1,#secret_market_items)
		if secret_market_items[i] then
			market.add_market_item(secret_market_items[i])
			market_items_to_add = market_items_to_add - 1
			secret_market_items[i] = nil
		end
	end
end

local function on_chunk_generated(event)
	if not global.noise_seed then global.noise_seed = math.random(1,5000000) end	
	local surface = game.surfaces[1]	
	local noise = {}
	local tiles = {}	
	local enemy_building_positions = {}
	local enemy_worm_positions = {}
	local enemy_can_place_worm_positions = {}
	local rock_positions = {}
	local fish_positions = {}
	local rare_treasure_chest_positions = {}
	local treasure_chest_positions = {}
	local secret_shop_locations = {}
	local extra_tree_positions = {}
	local spawn_tree_positions = {}
	local tile_to_insert = false
	local entity_has_been_placed = false
	local pos_x = 0
	local pos_y = 0
	local tile_distance_to_center = 0			
	local entities = surface.find_entities(event.area)
	for _, e in pairs(entities) do
		if e.type == "resource" or e.type == "tree" or e.force.name == "enemy" then
			e.destroy()				
		end
	end	
	local noise_seed_add = 25000
	local current_noise_seed_add = noise_seed_add	
	local m1 = 0.13
	local m2 = 0.13    --10
	local m3 = 0.10    --07
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do			
			pos_x = event.area.left_top.x + x
			pos_y = event.area.left_top.y + y
			tile_distance_to_center = pos_x^2 + pos_y^2
									
			noise[1] = simplex_noise.d2(pos_x/350, pos_y/350,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/200, pos_y/200,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/50, pos_y/50,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add			
			local cave_noise = noise[1] + noise[2]*0.35 + noise[3]*0.05 + noise[4]*0.015
			
			noise[1] = simplex_noise.d2(pos_x/120, pos_y/120,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/60, pos_y/60,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/40, pos_y/40,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add			
			local cave_noise_2 = noise[1] + noise[2]*0.30 + noise[3]*0.20 + noise[4]*0.09
			
			noise[1] = simplex_noise.d2(pos_x/50, pos_y/50,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/30, pos_y/30,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/10, pos_y/10,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add			
			local cave_noise_3 = noise[1] + noise[2]*0.5 + noise[3]*0.25 + noise[4]*0.1
			
			current_noise_seed_add = noise_seed_add	
			
			tile_to_insert = false	
			if tile_distance_to_center > global.spawn_dome_size then												
			
				if tile_distance_to_center > (global.spawn_dome_size + 5000) * (cave_noise_3 * 0.05 + 1.1) then
					if cave_noise > 1 then
						tile_to_insert = "deepwater"
						table.insert(fish_positions, {pos_x,pos_y})
					else
						if cave_noise > 0.98 then 
							tile_to_insert = "water"
						else
							if cave_noise > 0.82 then
								tile_to_insert = "grass-1"
								table.insert(enemy_building_positions, {pos_x,pos_y})
								table.insert(enemy_can_place_worm_positions, {pos_x,pos_y})
								--tile_to_insert = "grass-4"
								--if cave_noise > 0.88 then tile_to_insert = "grass-2" end
								if cave_noise > 0.94 then
									table.insert(extra_tree_positions, {pos_x,pos_y})
									table.insert(secret_shop_locations, {pos_x,pos_y})									
								end								
							else
								if cave_noise > 0.72 then
									tile_to_insert = "dirt-6"
									if cave_noise < 0.79 then table.insert(rock_positions, {pos_x,pos_y}) end
								end
							end
						end	
						if cave_noise < -0.80 then
							tile_to_insert = "dirt-6"
							if noise[3] > 0.18 or noise[3] < -0.18 then
								table.insert(rock_positions, {pos_x,pos_y})
								table.insert(enemy_worm_positions, {pos_x,pos_y})
								table.insert(enemy_worm_positions, {pos_x,pos_y})
								table.insert(enemy_worm_positions, {pos_x,pos_y})								
							else
								tile_to_insert = "sand-3"
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(rare_treasure_chest_positions, {pos_x,pos_y})								
							end
						else
							if cave_noise < -0.75 then
								tile_to_insert = "dirt-6"
								if cave_noise > -0.78 then table.insert(rock_positions, {pos_x,pos_y}) end
							end
						end						
					end
				end
				
				if tile_to_insert == false then
					if cave_noise < m1 and cave_noise > m1*-1 then
						tile_to_insert = "dirt-7"
						if cave_noise < 0.06 and cave_noise > -0.06 and noise[1] > 0.4 and tile_distance_to_center > global.spawn_dome_size + 5000 then
							table.insert(enemy_can_place_worm_positions, {pos_x,pos_y})
							table.insert(enemy_can_place_worm_positions, {pos_x,pos_y})
							table.insert(enemy_can_place_worm_positions, {pos_x,pos_y})
							table.insert(enemy_can_place_worm_positions, {pos_x,pos_y})
							table.insert(enemy_building_positions, {pos_x,pos_y})
							table.insert(enemy_building_positions, {pos_x,pos_y})
							table.insert(enemy_building_positions, {pos_x,pos_y})
							table.insert(enemy_building_positions, {pos_x,pos_y})
							table.insert(enemy_building_positions, {pos_x,pos_y})
						else
							table.insert(rock_positions, {pos_x,pos_y})
							if math.random(1,3) == 1 then table.insert(enemy_worm_positions, {pos_x,pos_y}) end
						end
						if cave_noise_2 > 0.85 and tile_distance_to_center > global.spawn_dome_size + 25000 then
							if math.random(1,48) == 1 then
								local p = surface.find_non_colliding_position("crude-oil",{pos_x,pos_y}, 5,1)
								local e = surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=math.floor(math.random(25000+tile_distance_to_center*0.5,50000+tile_distance_to_center),0)}
							end
						end
					else
						if cave_noise_2 < m2 and cave_noise_2 > m2*-1 then
							tile_to_insert = "dirt-4"
							table.insert(rock_positions, {pos_x,pos_y})
							table.insert(treasure_chest_positions, {pos_x,pos_y})								
						else
							if cave_noise_3 < m3 and cave_noise_3 > m3*-1 and cave_noise_2 < m2+0.3 and cave_noise_2 > (m2*-1)-0.3 then
								tile_to_insert = "dirt-2"
								table.insert(rock_positions, {pos_x,pos_y})	
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
								table.insert(treasure_chest_positions, {pos_x,pos_y})
							end
						end
					end
				end
				
				if tile_distance_to_center < global.spawn_dome_size * (cave_noise_3 * 0.05 + 1.1)  then	
					if tile_to_insert == false then table.insert(rock_positions, {pos_x,pos_y}) end
					tile_to_insert = "dirt-7"					
				end
			else
				if tile_distance_to_center < 750 * (1 + cave_noise_3 * 0.8) then
					tile_to_insert = "water"
					table.insert(fish_positions, {pos_x,pos_y})
				else
					tile_to_insert = "grass-1"
					if cave_noise_3 > 0 and tile_distance_to_center + 3000 < global.spawn_dome_size then
						table.insert(spawn_tree_positions, {pos_x,pos_y})
					end
				end				
			end
			
			if tile_distance_to_center < global.spawn_dome_size and tile_distance_to_center > global.spawn_dome_size - 500 and tile_to_insert == "grass-1" then
				table.insert(rock_positions, {pos_x,pos_y})	
			end						
			
			if tile_to_insert == false then
				table.insert(tiles, {name = "out-of-map", position = {pos_x,pos_y}}) 
			else
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) 
			end					
		end							
	end
	surface.set_tiles(tiles,true)
		
	for _, p in pairs(treasure_chest_positions) do	
		if math.random(1,200)==1 then 
			treasure_chest(p)
		end
	end
	for _, p in pairs(rare_treasure_chest_positions) do	
		if math.random(1,100)==1 then 
			rare_treasure_chest(p)
		end
	end
	
	for _, p in pairs(rock_positions) do
		local x = math.random(1,100)
		if x < global.rock_density then	
			surface.create_entity {name=global.rock_raffle[math.random(1,#global.rock_raffle)], position=p}						
		end
		--[[
		local z = 1
		if p[2] % 2 == 1 then z = 0 end
		if p[1] % 2 == z then
			surface.create_entity {name=global.rock_raffle[math.random(1,#global.rock_raffle)], position=p}			
		end
		]]--
	end
	
	for _, p in pairs(enemy_building_positions) do	
		if math.random(1,50)==1 then
			local pos = surface.find_non_colliding_position("biter-spawner", p, 8, 1)
			if pos then
				if math.random(1,3) == 1 then
					surface.create_entity {name="spitter-spawner",position=pos}
				else
					surface.create_entity {name="biter-spawner",position=pos}
				end
			end			
		end
	end	
	
	for _, p in pairs(enemy_worm_positions) do		
		if math.random(1,300)==1 then
			local tile_distance_to_center = math.sqrt(p[1]^2 + p[2]^2)
			if tile_distance_to_center > global.worm_free_zone_radius then						
				local raffle_index = math.ceil((tile_distance_to_center-global.worm_free_zone_radius)*0.01, 0)
				if raffle_index < 1 then raffle_index = 1 end
				if raffle_index > 10 then raffle_index = 10 end					
				local entity_name = global.worm_raffle_table[raffle_index][math.random(1,#global.worm_raffle_table[raffle_index])]												
				surface.create_entity {name=entity_name, position=p}
			end
		end
	end	
	
	for _, p in pairs(enemy_can_place_worm_positions) do		
		if math.random(1,30)==1 then
			local tile_distance_to_center = math.sqrt(p[1]^2 + p[2]^2)
			if tile_distance_to_center > global.worm_free_zone_radius then						
				local raffle_index = math.ceil((tile_distance_to_center-global.worm_free_zone_radius)*0.01, 0)
				if raffle_index < 1 then raffle_index = 1 end
				if raffle_index > 10 then raffle_index = 10 end					
				local entity_name = global.worm_raffle_table[raffle_index][math.random(1,#global.worm_raffle_table[raffle_index])]												
				if surface.can_place_entity({name=entity_name, position=p}) then surface.create_entity {name=entity_name, position=p} end
			end
		end
	end
		
	for _, p in pairs(fish_positions) do	
		if math.random(1,16)==1 then
			if surface.can_place_entity({name="fish",position=p}) then
				surface.create_entity {name="fish",position=p}
			end
		end
	end
		
	for _, p in pairs(secret_shop_locations) do	
		if math.random(1,10)==1 then
			if surface.count_entities_filtered{area={{p[1]-125,p[2]-125},{p[1]+125,p[2]+125}}, name="market", limit=1} == 0 then
				secret_shop(p)
			end
		end
	end		
	
	for _, p in pairs(spawn_tree_positions) do	
		if math.random(1,6)==1 then 
			surface.create_entity {name="tree-04",position=p}
		end
	end	
	
	for _, p in pairs(extra_tree_positions) do	
		if math.random(1,20)==1 then 
			surface.create_entity {name="tree-02",position=p}
		end
	end				
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end	 
	surface.regenerate_decorative(decorative_names, {{x=math.floor(event.area.left_top.x/32),y=math.floor(event.area.left_top.y/32)}})		
end

local function hunger_update(player, food_value)
	
	local past_hunger = global.player_hunger[player.name]	
	global.player_hunger[player.name] = global.player_hunger[player.name] + food_value
	if global.player_hunger[player.name] > 200 then global.player_hunger[player.name] = 200 end
			
	if past_hunger == 200 and global.player_hunger[player.name] + food_value > 200 then
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		player.character.die("player")
		local t = {" ate too much and exploded.", " should have gone on a diet.", " needs to work on their bad eating habbits.", " should have skipped dinner today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})				
	end	
	
	if global.player_hunger[player.name] < 1 then
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		player.character.die("player")
		local t = {" ran out of foodstamps.", " starved.", " should not have skipped breakfast today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})	
	end
	
	if player.character then
		if global.player_hunger_stages[global.player_hunger[player.name]] ~= global.player_hunger_stages[past_hunger] then
			local print_message = "You feel " .. global.player_hunger_stages[global.player_hunger[player.name]] .. "."
			if global.player_hunger_stages[global.player_hunger[player.name]] == "Obese" then
				print_message = "You have become " .. global.player_hunger_stages[global.player_hunger[player.name]]  .. "."					
			end
			if global.player_hunger_stages[global.player_hunger[player.name]] == "Starving" then
				print_message = "You are starving!"
			end
			player.print(print_message, global.player_hunger_color_list[global.player_hunger[player.name]])
		end
	end
	
	player.character.character_running_speed_modifier = global.player_hunger_buff[global.player_hunger[player.name]] * 0.75
	player.character.character_mining_speed_modifier  = global.player_hunger_buff[global.player_hunger[player.name]]
end

local function on_player_joined_game(event)
	local surface = game.surfaces[1]	
	local player = game.players[event.player_index]
	if not global.cave_miner_init_done then		 
		local p = surface.find_non_colliding_position("player", {0,-40}, 10, 1)
		game.forces["player"].set_spawn_position(p,surface)
		player.teleport(p)
		surface.daytime = 0.5
		surface.freeze_daytime = 1
		game.forces["player"].technologies["landfill"].enabled = false
		game.forces["player"].technologies["night-vision-equipment"].enabled = false
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false			
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false	
		game.forces["player"].technologies["atomic-bomb"].enabled = false	
		
		game.map_settings.enemy_evolution.destroy_factor = 0.004
		
		global.spawn_dome_size = 20000
		
		global.cave_miner_map_info = [[
Delve deep for greater treasures, but also face increased dangers.
Mining productivity research, will overhaul your mining equipment,
reinforcing your pickaxe as well as increasing the size of your backpack.

Breaking rocks is exhausting and might make you hungry.
So don´t forget to eat some fish once in a while to stay well fed.
But be careful, eating too much might have it´s consequences too.

Darkness is a hazard in the mines, stay near your lamps..
]]
		
		global.player_hunger_fish_food_value = 10
		global.player_hunger_spawn_value = 80
		global.player_hunger = {}		
		global.player_hunger_stages = {}
		for x = 1, 200, 1 do
			if x <= 200 then global.player_hunger_stages[x] = "Obese" end						
			if x <= 179 then global.player_hunger_stages[x] = "Stuffed" end
			if x <= 150 then global.player_hunger_stages[x] = "Bloated" end
			if x <= 130 then global.player_hunger_stages[x] = "Sated" end
			if x <= 110 then global.player_hunger_stages[x] = "Well Fed" end
			if x <= 89 then global.player_hunger_stages[x] = "Nourished" end			
			if x <= 70 then global.player_hunger_stages[x] = "Hungry" end
			if x <= 35 then global.player_hunger_stages[x] = "Starving" end			
		end	
		
		global.player_hunger_color_list = {}
		for x = 1, 50, 1 do
			global.player_hunger_color_list[x] = 		{r = 0.5 + x*0.01, g = x*0.01, b = x*0.005}
			global.player_hunger_color_list[50+x] = {r = 1 - x*0.02, g = 0.5 + x*0.01, b = 0.25}
			global.player_hunger_color_list[100+x] = {r = 0 + x*0.02, g = 1 - x*0.01, b = 0.25}
			global.player_hunger_color_list[150+x] = {r = 1 - x*0.01, g = 0.5 - x*0.01, b = 0.25 - x*0.005}
		end
		
		global.player_hunger_buff = {}
		local buff_top_value = 0.35		
		for x = 1, 200, 1 do
			global.player_hunger_buff[x] = buff_top_value
		end
		local y = 1
		for x = 89, 1, -1 do			
			global.player_hunger_buff[x] = buff_top_value - y * 0.01
			y = y + 1
		end
		local y = 1		
		for x = 111, 200, 1 do			
			global.player_hunger_buff[x] = buff_top_value - y * 0.01
			y = y + 1
		end
		
		global.rock_inhabitants = {}
		global.rock_inhabitants[1] = {"small-biter"}
		global.rock_inhabitants[2] = {"small-biter","small-biter","small-biter","small-biter","small-biter","medium-biter"}
		global.rock_inhabitants[3] = {"small-biter","small-biter","small-biter","small-biter","medium-biter","medium-biter"}
		global.rock_inhabitants[4] = {"small-biter","small-biter","small-biter","medium-biter","medium-biter","small-spitter"}
		global.rock_inhabitants[5] = {"small-biter","small-biter","medium-biter","medium-biter","medium-biter","small-spitter"}
		global.rock_inhabitants[6] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","small-spitter"}
		global.rock_inhabitants[7] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[8] = {"small-biter","medium-biter","medium-biter","medium-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[9] = {"small-biter","medium-biter","medium-biter","big-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[10] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[11] = {"medium-biter","medium-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[12] = {"medium-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[13] = {"big-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[14] = {"big-biter","big-biter","big-biter","big-biter","behemoth-biter","big-spitter"}
		global.rock_inhabitants[15] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","big-spitter"}
		global.rock_inhabitants[16] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[17] = {"big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[18] = {"big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[19] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[20] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter","behemoth-spitter"}	
		
		global.biter_spawn_amount_weights = {}				
		global.biter_spawn_amount_weights[1] = {64, 1}
		global.biter_spawn_amount_weights[2] = {32, 4}
		global.biter_spawn_amount_weights[3] = {16, 8}
		global.biter_spawn_amount_weights[4] = {8, 16}
		global.biter_spawn_amount_weights[5] = {4, 32}
		global.biter_spawn_amount_weights[6] = {2, 64}
		global.biter_spawn_amount_raffle = {}
		for _, t in pairs (global.biter_spawn_amount_weights) do
			for x = 1, t[2], 1 do
				table.insert(global.biter_spawn_amount_raffle, t[1])
			end			
		end
		
		global.rock_density = 62  ---- insert value up to 100
		global.rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
		
		global.worm_raffle_table = {}
		global.worm_raffle_table[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"}
		global.worm_raffle_table[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[10] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}						
		global.worm_free_zone_radius = math.sqrt(global.spawn_dome_size) + 40
		
		global.biter_spawn_schedule = {}										
		
		global.ore_spill_cap = 35
		global.stats_rocks_brocken = 0
		global.stats_ores_found = 0
		global.total_ores_mined = 0
		
		global.rock_mining_chance_weights = {}
		global.rock_mining_chance_weights[1] = {"iron-ore",25}
		global.rock_mining_chance_weights[2] = {"copper-ore",18}
		global.rock_mining_chance_weights[3] = {"coal",14}
		global.rock_mining_chance_weights[4] = {"uranium-ore",3}
		global.rock_mining_raffle_table = {}				
		for _, t in pairs (global.rock_mining_chance_weights) do
			for x = 1, t[2], 1 do
				table.insert(global.rock_mining_raffle_table, t[1])
			end			
		end

		global.darkness_threat_level = {}
		global.darkness_messages = {
		"Something is lurking in the dark...",
		"A shadow moves. I doubt it is friendly...",
		"The silence grows louder...",
		"Trust not your eyes. They are useless in the dark.",
		"The darkness hides only death. Turn back now.",
		"You hear noises...",
		"They chitter as if laughing, hungry for their next foolish meal...",
		"Despite what the radars tell you, it is not safe here...",
		"The shadows are moving...",
		"You feel like, something is watching you...",		
		}					
		
		global.cave_miner_init_done = true						
	end
	if player.online_time < 10 then
		create_cave_miner_info(player)
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		hunger_update(player, 0)
		global.darkness_threat_level[player.name] = 0
		player.insert {name = 'pistol', count = 1}
		--player.insert {name = 'raw-fish', count = 1}		
		player.insert {name = 'firearm-magazine', count = 16}			
		player.insert {name = 'iron-axe', count = 1}		
	end
	create_cave_miner_button(player)
	create_cave_miner_stats_gui(player)
end

local function spawn_cave_inhabitant(pos, target_position)
	if not pos.x then return nil end
	if not pos.y then return nil end
	local surface = game.surfaces[1]
	local tile_distance_to_center = math.sqrt(pos.x^2 + pos.y^2)			
	local rock_inhabitants_index = math.ceil((tile_distance_to_center-math.sqrt(global.spawn_dome_size))*0.015, 0)
	if rock_inhabitants_index < 1 then rock_inhabitants_index = 1 end
	if rock_inhabitants_index > 20 then rock_inhabitants_index = 20 end					
	local entity_name = global.rock_inhabitants[rock_inhabitants_index][math.random(1,#global.rock_inhabitants[rock_inhabitants_index])]
	local p = surface.find_non_colliding_position(entity_name , pos, 6, 0.5)
	local biter = 1
	if p then biter = surface.create_entity {name=entity_name, position=p} end
	if target_position then biter.set_command({type=defines.command.attack_area, destination=target_position, radius=5, distraction=defines.distraction.by_anything}) end
	if not target_position then biter.set_command({type=defines.command.attack_area, destination=game.forces["player"].get_spawn_position(surface), radius=5, distraction=defines.distraction.by_anything}) end
end

local function find_first_entity_spiral_scan(pos, entities, range)
	if not pos then return end
	if not entities then return end
	if not range then return end
	local surface = game.surfaces[1]
	local out_of_map_count = 0
	local out_of_map_cap = 1
	for z = 2,range,2 do
		pos.y = pos.y - 1
		pos.x = pos.x - 1
		for modifier = 1, -1, -2 do
			for x = 1, z, 1 do
				pos.x = pos.x + modifier	
				local t = surface.get_tile(pos)
				if t.name == "out-of-map" then out_of_map_count = out_of_map_count + 1 end				
				if out_of_map_count > out_of_map_cap then return end
				local e = surface.find_entities_filtered {position = pos, name = entities}						
				if e[1] then return e[1].position end
			end
			for y = 1, z, 1 do
				pos.y = pos.y + modifier	
				local t = surface.get_tile(pos)
				if t.name == "out-of-map" then out_of_map_count = out_of_map_count + 1 end
				if out_of_map_count > out_of_map_cap then return end
				local e = surface.find_entities_filtered {position = pos, name = entities}					
				if e[1] then return e[1].position end
			end
			if out_of_map_count > out_of_map_cap then return end
		end	
		if out_of_map_count > out_of_map_cap then return end				
	end		
end

local function biter_attack_event()
	local surface = game.surfaces[1]
	local valid_positions = {}
	for _, player in pairs(game.connected_players) do
		if player.character.driving == false then
			local position = {x = player.position.x, y = player.position.y}
			local p = find_first_entity_spiral_scan(position, {"rock-huge", "rock-big", "sand-rock-big"}, 32)		
			if p then
				if p.x^2 + p.y^2 > global.spawn_dome_size then table.insert(valid_positions, p) end
			end
		end
	end
	if valid_positions[1] then
		if #valid_positions == 1 then
			for x = 1, global.biter_spawn_amount_raffle[math.random(1,#global.biter_spawn_amount_raffle)],1 do
				table.insert(global.biter_spawn_schedule, {game.tick + 20*x, valid_positions[1]})
			end
		end
		if #valid_positions > 1 then
			for y = math.random(1,2), #valid_positions, 2 do
				if y > #valid_positions then break end
				for x = 1, global.biter_spawn_amount_raffle[math.random(1,#global.biter_spawn_amount_raffle)],1 do
					table.insert(global.biter_spawn_schedule, {game.tick + 20*x, valid_positions[y]})
				end
			end
		end
	end
end	

local function darkness_events()
	for _, p in pairs (game.connected_players) do		
		if global.darkness_threat_level[p.name] > 4 then						
			for x = 1, 2 + global.darkness_threat_level[p.name], 1 do
				spawn_cave_inhabitant(p.position)	
			end				
			local biters_found = game.surfaces[1].find_enemy_units(p.position, 12, "player")
			for _, biter in pairs(biters_found) do				
				biter.set_command({type=defines.command.attack, target=p.character, distraction=defines.distraction.none})					
			end
			p.character.damage(math.random(global.darkness_threat_level[p.name]*2,global.darkness_threat_level[p.name]*3),"enemy")
		end		
		if global.darkness_threat_level[p.name] == 2 then
			p.print(global.darkness_messages[math.random(1,#global.darkness_messages)],{ r=0.65, g=0.0, b=0.0})				
		end
		global.darkness_threat_level[p.name] = global.darkness_threat_level[p.name] + 1
	end
end

local function darkness_checks()
	for _, p in pairs (game.connected_players) do
		if p.character then p.character.disable_flashlight() end		
		local tile_distance_to_center = math.sqrt(p.position.x^2 + p.position.y^2)
		if tile_distance_to_center < math.sqrt(global.spawn_dome_size) then
			global.darkness_threat_level[p.name] = 0
		else
			if p.character.driving == true then
				global.darkness_threat_level[p.name] = 0
			else
				local light_source_entities = game.surfaces[1].find_entities_filtered{area={{p.position.x-12,p.position.y-12},{p.position.x+12,p.position.y+12}}, name="small-lamp"}		
				for _, lamp in pairs (light_source_entities) do
					local circuit = lamp.get_or_create_control_behavior()
					if circuit then
						if lamp.energy > 50 and circuit.disabled == false then					
							global.darkness_threat_level[p.name] = 0
							break
						end
					else
						if lamp.energy > 50 then					
							global.darkness_threat_level[p.name] = 0
							break
						end
					end
				end
			end
		end
	end
end

local function on_tick(event)
		
		if game.tick % 30 == 0 then
			if global.biter_spawn_schedule then										
				for x = 1, #global.biter_spawn_schedule, 1 do
					if global.biter_spawn_schedule[x] then					
						if game.tick >= global.biter_spawn_schedule[x][1] then
							spawn_cave_inhabitant(global.biter_spawn_schedule[x][2])
							global.biter_spawn_schedule[x] = nil
						end						
					end
				end								
			end
		end		
		
		if game.tick % 240 == 0 then
			darkness_checks()	
			darkness_events()	
		end		
		
		if game.tick % 5400 == 2700 then
			for _, player in pairs(game.connected_players) do
				if player.afk_time < 18000 then	hunger_update(player, -1) end		
			end
			refresh_gui()
			
			if math.random(1,2) == 1 then biter_attack_event() end
		end
		
		if game.tick == 30 then
			local surface = game.surfaces[1]									
			local p = game.surfaces[1].find_non_colliding_position("market",{0,-15},60,0.5)
			local market = surface.create_entity {name = "market", position = p}
			market.destructible = false
			
			for _, item in pairs(market_items.spawn) do
				market.add_market_item(item)
			end			
			surface.regenerate_entity({"rock-big","rock-huge"})			
		end
		
		if global.map_pregeneration_is_active then
			if game.tick % 600 == 0 then
				local r = 1
				for x = 1,32,1 do
					if game.forces.map_pregen.is_chunk_charted(game.surfaces[1], {x,x}) then r = x end
				end
				game.print("Map chunks are generating... current radius " .. r, { r=0.22, g=0.99, b=0.99})				
				if game.forces.map_pregen.is_chunk_charted(game.surfaces[1], {32,32}) then
					game.print("Map generation done!", {r=0.22, g=0.99, b=0.99})
					
					game.players[1].force = game.forces["player"]
					global.map_pregeneration_is_active = nil
				end
			end
		end		
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function pre_player_mined_item(event)
	local surface = game.surfaces[1]
	local player = game.players[event.player_index]
	
	if math.random(1,12) == 1 then
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then		
			for x = 1, math.random(6,8), 1 do
				table.insert(global.biter_spawn_schedule, {game.tick + 15*x, event.entity.position})		
			end			
		end
	end
	
	if event.entity.type == "tree" then surface.spill_item_stack(player.position,{name = "raw-fish", count = math.random(1,2)},true) end
	
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then		
		local rock_position = {x = event.entity.position.x, y = event.entity.position.y}
		event.entity.destroy()
		local tile_distance_to_center = math.sqrt(rock_position.x^2 + rock_position.y^2)
				
		if math.random(1,3) == 1 then hunger_update(player, -1) end
		
		surface.spill_item_stack(player.position,{name = "raw-fish", count = math.random(3,4)},true)
		local bonus_amount = math.ceil((tile_distance_to_center - math.sqrt(global.spawn_dome_size)) * 0.4, 0) 
		if bonus_amount < 1 then bonus_amount = 0 end		
		local amount = (math.random(55,65) + bonus_amount)*(1+game.forces.player.mining_drill_productivity_bonus)
		
		amount = math.round(amount, 0)
		amount_of_stone = math.round(amount * 0.15,0)		
		
		global.stats_ores_found = global.stats_ores_found + amount + amount_of_stone
		
		local mined_loot = global.rock_mining_raffle_table[math.random(1,#global.rock_mining_raffle_table)]
		if amount > global.ore_spill_cap then
			surface.spill_item_stack(rock_position,{name = mined_loot, count = global.ore_spill_cap},true)
			amount = amount - global.ore_spill_cap
			local i = player.insert {name = mined_loot, count = amount}
			amount = amount - i
			if amount > 0 then
				surface.spill_item_stack(rock_position,{name = mined_loot, count = amount},true)
			end
		else
			surface.spill_item_stack(rock_position,{name = mined_loot, count = amount},true)
		end
		
		if amount_of_stone > global.ore_spill_cap then
			surface.spill_item_stack(rock_position,{name = "stone", count = global.ore_spill_cap},true)
			amount_of_stone = amount_of_stone - global.ore_spill_cap
			local i = player.insert {name = "stone", count = amount_of_stone}
			amount_of_stone = amount_of_stone - i
			if amount_of_stone > 0 then
				surface.spill_item_stack(rock_position,{name = "stone", count = amount_of_stone},true)
			end
		else
			surface.spill_item_stack(rock_position,{name = "stone", count = amount_of_stone},true)
		end
		
		global.stats_rocks_brocken = global.stats_rocks_brocken + 1		
		refresh_gui()
		
		if math.random(1,32) == 1 then				
			local p = {x = rock_position.x, y = rock_position.y}
			local tile_distance_to_center = p.x^2 + p.y^2
			if	tile_distance_to_center > global.spawn_dome_size + 100 then
				local radius = 32
				if surface.count_entities_filtered{area={{p.x - radius,p.y - radius},{p.x + radius,p.y + radius}}, type="resource", limit=1} == 0 then
					local size_raffle = {{"huge", 33, 42},{"big", 17, 32},{"", 8, 16},{"tiny", 3, 7}}
					local size = size_raffle[math.random(1,#size_raffle)]
					local ore_prints = {coal = {"dark", "Coal"}, ["iron-ore"] = {"shiny", "Iron"}, ["copper-ore"] = {"glimmering", "Copper"}, ["uranium-ore"] = {"glowing", "Uranium"}}
					player.print("You notice something " .. ore_prints[mined_loot][1] .. " underneath the rubble covered floor. It´s a " .. size[1] .. " vein of " ..  ore_prints[mined_loot][2] .. "!!", { r=0.98, g=0.66, b=0.22})
					tile_distance_to_center = math.sqrt(tile_distance_to_center)
					local ore_entities_placed = 0
					local modifier_raffle = {{0,-1},{-1,0},{1,0},{0,1}}
					while ore_entities_placed < math.random(size[2],size[3]) do						
						local a = math.ceil((math.random(tile_distance_to_center*4, tile_distance_to_center*5)) / 1 + ore_entities_placed * 0.5, 0)						
						for x = 1, 150, 1 do
							local m = modifier_raffle[math.random(1,#modifier_raffle)]
							local pos = {x = p.x + m[1], y = p.y + m[2]}
							if surface.can_place_entity({name=mined_loot, position=pos, amount=a}) then
								surface.create_entity {name=mined_loot, position=pos, amount=a}
								p = pos
								break
							end
						end
						ore_entities_placed = ore_entities_placed + 1
					end
				end
			end
		end		
	end
end

local function on_player_mined_entity(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		event.buffer.clear()
	end
	if event.entity.name == "fish" then
		if math.random(1,2) == 1 then
			local player = game.players[event.player_index]	
			local health = player.character.health
			player.character.damage(math.random(50,150),"enemy")			
			if not player.character then
				game.print(player.name .. " should have kept their hands out of the foggy lake waters.",{ r=0.75, g=0.0, b=0.0} )
			else
				if health > 200 then
					player.print("You got bitten by an angry cave piranha.",{ r=0.75, g=0.0, b=0.0})
				else
					local messages = {"Ouch.. That hurt! Better be careful now.", "Just a fleshwound.", "Better keep those hands to yourself or you might loose them."}
					player.print(messages[math.random(1,#messages)],{ r=0.75, g=0.0, b=0.0})
				end
			end
		end
	end	
end

local function on_entity_damaged(event)	
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		local rock_is_alive = true
		if event.force.name == "enemy" then 
			event.entity.health = event.entity.health + (event.final_damage_amount - 0.2)
			if event.entity.health <= event.final_damage_amount then				
				rock_is_alive = false
			end			
		end
		if event.force.name == "player" and event.entity.name == "rock-huge" then 
			event.entity.health = event.entity.health - event.final_damage_amount
			if event.entity.health <= event.final_damage_amount then				
				rock_is_alive = false
			end			
		end
		if event.entity.health <= 0 then rock_is_alive = false end		
		if rock_is_alive == false then			
			if event.force.name == "player" then	
				if math.random(1,12) == 1 then								
					for x = 1, math.random(6,10), 1 do
						table.insert(global.biter_spawn_schedule, {game.tick + 10*x, event.entity.position})		
					end						
				end
			end
			local p = event.entity.position				
			local drop_amount = math.random(4,8)
			event.entity.destroy()
			game.surfaces[1].spill_item_stack(p,{name = "stone", count = drop_amount},true)
			global.stats_rocks_brocken = global.stats_rocks_brocken + 1
			global.stats_ores_found = global.stats_ores_found + drop_amount
			refresh_gui()						
		end
	end	
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	player.character.disable_flashlight()
	global.player_hunger[player.name] = global.player_hunger_spawn_value
	hunger_update(player, 0)
	refresh_gui()
end

local function on_research_finished(event)
	game.forces.player.manual_mining_speed_modifier = game.forces.player.mining_drill_productivity_bonus * 4
	game.forces.player.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 500
	refresh_gui()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	

	local player = game.players[event.element.player_index]
	local name = event.element.name
	local frame = player.gui.top["caver_miner_stats_frame"]	
	
	if name == "caver_miner_stats_toggle_button" and frame == nil then create_cave_miner_stats_gui(player) end	
	if name == "caver_miner_stats_toggle_button" and frame then
		if player.gui.left["cave_miner_info"] then
			frame.destroy()
			player.gui.top["hunger_frame"].destroy()
			player.gui.left["cave_miner_info"].destroy()
		else	
			create_cave_miner_info(player)
		end					
	end
	if name == "close_cave_miner_info" then player.gui.left["cave_miner_info"].destroy() end	
end

local function on_player_used_capsule(event)
	if event.item.name == "raw-fish" then
		local player = game.players[event.player_index]				
		hunger_update(player, global.player_hunger_fish_food_value)		
		player.play_sound{path="utility/armor_insert", volume_modifier=1}		
		refresh_gui()
	end
end

function map_pregen()
	local radius = 1024
	if not game.forces.map_pregen then game.create_force("map_pregen") end
	game.players[1].force = game.forces["map_pregen"]
	game.forces.map_pregen.chart(game.surfaces[1],{{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
	global.map_pregeneration_is_active = true
end
	
function cheat_mode()
	local cheat_mode_enabed = false
	if cheat_mode_enabed == true then
		local surface = game.surfaces[1]
		game.player.cheat_mode=true
		game.players[1].insert({name="power-armor-mk2"})
		game.players[1].insert({name="fusion-reactor-equipment", count=4})
		game.players[1].insert({name="personal-laser-defense-equipment", count=8})
		game.players[1].insert({name="rocket-launcher"})		
		game.players[1].insert({name="explosive-rocket", count=200})		
		game.speed = 2
		surface.daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 200
		local surface = game.surfaces[1]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_tick, on_tick)	
Event.add(defines.events.on_player_joined_game, on_player_joined_game)