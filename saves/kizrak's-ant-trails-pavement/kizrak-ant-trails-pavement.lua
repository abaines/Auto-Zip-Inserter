-- Kizrak

local sb = serpent.block -- luacheck: ignore 211

log("kizrak-ant-trails-pavement.lua")



local land_tiles = {}

land_tiles['grass-1'] = true
land_tiles['grass-2'] = true
land_tiles['grass-3'] = true
land_tiles['grass-4'] = true

land_tiles['nuclear-ground'] = true
land_tiles['dry-dirt'] = true

land_tiles['dirt-1'] = true
land_tiles['dirt-2'] = true
land_tiles['dirt-3'] = true
land_tiles['dirt-4'] = true
land_tiles['dirt-5'] = true
land_tiles['dirt-6'] = true
land_tiles['dirt-7'] = true

land_tiles['sand-1'] = true
land_tiles['sand-2'] = true
land_tiles['sand-3'] = true

land_tiles['red-desert-0'] = true
land_tiles['red-desert-1'] = true
land_tiles['red-desert-2'] = true
land_tiles['red-desert-3'] = true



local ant_trails_pavement = {}

local on_player_changed_position = function(event)
	log('on_player_changed_position')
	local player = game.players[event.player_index]
	local position =player.position
	log(position)
	

	inventory = player.get_main_inventory()
	count_stone_brick = inventory.get_item_count("stone-brick")
	log(count_stone_brick)

	surface = player.surface
	tile = surface.get_tile(position)
	tile_name = tile.name

	if land_tiles[tile_name] then
		log("land! " .. tile_name)
		if count_stone_brick > 100 then

			inventory.remove({
				name="stone-brick",
				count=1,
			})
		end
	else
		log("invalid tile " ..tile_name)
	end

	local result = surface.set_tiles(
		{{
			position = position,
			name="stone-path",
		}},
		true, true, true, false
	)
	log(result)

end



ant_trails_pavement.events =
{
	[defines.events.on_player_changed_position] = on_player_changed_position
}

ant_trails_pavement.on_configuration_changed = function()
	log("on_configuration_changed")
end

ant_trails_pavement.on_init = function()
	log("on_init")
end


return ant_trails_pavement

