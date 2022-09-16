-- Kizrak
-- kizrak-ant-trails-pavement.lua
--[[
	To activate this soft mod, place this file at the root of a save file,
	and add the following line to the end of the control.lua file:
	
	handler.add_lib(require("kizrak-ant-trails-pavement"))
]] --
log("kizrak-ant-trails-pavement.lua")

local sb = serpent.block -- luacheck: ignore 211

--- TODO: time for a library soon...
local function sbs(obj) -- luacheck: ignore 211
    return sb(obj):gsub("%s+", " ")
end

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

local surface_set_tile = function(surface, position, tile_name)

    local tiles = {{
        position = position,
        name = tile_name
    }}

    local correct_tiles = false
    local remove_colliding_entities = "abort_on_collision"
    local remove_colliding_decoratives = true
    local raise_event = true

    -- https://lua-api.factorio.com/latest/LuaSurface.html#LuaSurface.set_tiles
    local result = surface.set_tiles(tiles, correct_tiles, remove_colliding_entities, remove_colliding_decoratives,
        raise_event)

    local next_tile = surface.get_tile(position)

    return next_tile.name == tile_name
end

local happy_vehicles = {}
happy_vehicles['car'] = true
happy_vehicles['tank'] = true

local function is_happy_vehicle(player)
    local vehicle = player.vehicle

    if vehicle then
        local name = vehicle.name
        local happy = happy_vehicles[name]

        if happy then
            return true
        else
            return false
        end
    else
        return true
    end
end

local place_stone_from_player = function(player)
    local position = player.position
    local surface = player.surface

    local inventory = player.get_main_inventory()
    local count_stone_brick = inventory.get_item_count("stone-brick")

    if count_stone_brick > 100 and is_happy_vehicle(player) then

        local result = surface_set_tile(surface, position, "stone-path")

        if result then
            local player_text = "player = " .. player.name
            local count_stone_brick_text = " count_stone_brick = " .. count_stone_brick
            local position_text = " position = " .. sbs(position)
            log(player_text .. count_stone_brick_text .. position_text)

            inventory.remove({
                name = "stone-brick",
                count = 1
            })
        end
    end
end

local on_player_changed_position = function(event)
    local player = game.players[event.player_index]
    local position = player.position

    local surface = player.surface
    local tile = surface.get_tile(position)
    local tile_name = tile.name

    if land_tiles[tile_name] then
        place_stone_from_player(player)
    end

end

ant_trails_pavement.events = {
    [defines.events.on_player_changed_position] = on_player_changed_position
}

return ant_trails_pavement

