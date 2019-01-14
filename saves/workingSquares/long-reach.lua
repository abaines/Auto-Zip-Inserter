--[[

https://github.com/Geend/long-reach

authors: James Aguilar, Torben Voltmer

The MIT License (MIT)

Copyright (c) 2015 James Aguilar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]--

-- from version: 0.0.12

script.on_init(function ()
	apply_long_reach_settings()
end)

script.on_event({
defines.events.on_player_joined_game,
defines.events.on_player_created,
},function ()
	apply_long_reach_settings()
end)


function apply_long_reach_settings()
	game.forces.player.character_build_distance_bonus = 125
	game.forces.player.character_reach_distance_bonus = 125
	game.forces.player.character_resource_reach_distance_bonus = 7
	game.forces.player.character_inventory_slots_bonus = 80
	game.forces.player.character_item_pickup_distance_bonus = 7
	
	-- /silent-command
	game.player.force.technologies['engine'].researched=true
	game.player.force.technologies['railway'].researched=true
	game.player.force.technologies['automated-rail-transportation'].researched=true
	--game.player.force.technologies['rail-signals'].researched=true
	
	for i, player in pairs(game.players) do
		player.game_view_settings.show_rail_block_visualisation = true
	end
	
	game.print("apply_long_reach_settings",{r=255,g=102})
	log("apply_long_reach_settings")
end

