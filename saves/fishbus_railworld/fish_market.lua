--[[
Hello there script explorer! 

With this you can add a "Fish Market" to your World
You can earn fish by killing alot of biters or by mining wood, ores, rocks.
To spawn the market, do "/c market()" in your chat ingame as the games host.
It will spawn a few tiles north of the current position where your character is.

---MewMew---
--]]
--[[

Updates (Kovus):
- Dependency created upon fb_score.lua through the use of the global.score when
killing biters.
- Added interface for the market, so that it can be spawned through other
means, and avoid killing your achievements.
- Adjusted the market() function to become spawnMarketOn(player) so that the
market can be spawned on the player calling for it.

--]]

require 'lib/event_extend'

function spawnMarketOn(player)
  local radius = 10
  local surface = game.surfaces[1]
  -- clear trees and landfill in start area
  local start_area = {left_top = {-20, -20}, right_bottom = {20, 20}}
  for _, e in pairs(surface.find_entities_filtered{area=start_area, type="tree"}) do
    --e.destroy()
  end
  for i = -radius, radius, 1 do
    for j = -radius, radius, 1 do
      if (surface.get_tile(i,j).collides_with("water-tile")) then
        --surface.set_tiles{{name = "grass", position = {i,j}}}
      end
    end
  end
  
  local market_location = {x = player.position.x, y = player.position.y}
  market_location.y = market_location.y - 4
  
  -- create water around market
  local waterTiles = {}
  for i = -4, 4 do
    for j = -4, 4 do
        --table.insert(waterTiles, {name = "water-green", position={market_location.x + i, market_location.y + j}})
    end
  end
  surface.set_tiles(waterTiles)
  local market = surface.create_entity{name="market", position=market_location, force=force}
  market.destructible = false
  local tag = player.force.add_chart_tag(surface, {
    position = market_location,
    text = 'Fish Market',
    icon = {type = "item", name = "raw-fish"}
  })

  market.add_market_item{price={{"raw-fish", 5}}, offer={type="give-item", item="burner-mining-drill"}}
  market.add_market_item{price={{"raw-fish", 5}}, offer={type="give-item", item="stone-furnace"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="assembling-machine-1"}}
  market.add_market_item{price={{"raw-fish", 50}}, offer={type="give-item", item="loader"}}
  market.add_market_item{price={{"raw-fish", 100}}, offer={type="give-item", item="fast-loader"}}
  market.add_market_item{price={{"raw-fish", 150}}, offer={type="give-item", item="express-loader"}} 
  market.add_market_item{price={{"raw-fish", 40}}, offer={type="give-item", item="pumpjack"}}
  market.add_market_item{price={{"raw-fish", 25}}, offer={type="give-item", item="crude-oil-barrel"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="solid-fuel"}}
  market.add_market_item{price={{"raw-fish", 250}}, offer={type="give-item", item="uranium-fuel-cell", count=5}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="electric-engine-unit", count=2}}
  market.add_market_item{price={{"raw-fish", 40}}, offer={type="give-item", item="construction-robot"}}
  market.add_market_item{price={{"raw-fish", 35}}, offer={type="give-item", item="logistic-robot"}}
  market.add_market_item{price={{"raw-fish", 80}}, offer={type="give-item", item="beacon"}}
  market.add_market_item{price={{"raw-fish", 5}}, offer={type="give-item", item="rail", count=2}}
  market.add_market_item{price={{"raw-fish", 8}}, offer={type="give-item", item="rail-signal"}}
  market.add_market_item{price={{"raw-fish", 8}}, offer={type="give-item", item="rail-chain-signal"}}
  market.add_market_item{price={{"raw-fish", 35}}, offer={type="give-item", item="train-stop"}}
  market.add_market_item{price={{"raw-fish", 150}}, offer={type="give-item", item="locomotive"}}
  market.add_market_item{price={{"raw-fish", 90}}, offer={type="give-item", item="cargo-wagon"}}
  market.add_market_item{price={{"raw-fish", 150}}, offer={type="give-item", item="car"}}
  market.add_market_item{price={{"raw-fish", 400}}, offer={type="give-item", item="tank"}}
  market.add_market_item{price={{"raw-fish", 40}}, offer={type="give-item", item="explosive-cannon-shell"}}
  market.add_market_item{price={{"raw-fish", 75}}, offer={type="give-item", item="explosive-uranium-cannon-shell"}}
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="red-wire", count=2}}
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="green-wire", count=2}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="decider-combinator"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="arithmetic-combinator"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="constant-combinator"}}
  market.add_market_item{price={{"raw-fish", 8}}, offer={type="give-item", item="programmable-speaker"}}   
  market.add_market_item{price={{"raw-fish", 60}}, offer={type="give-item", item="solar-panel"}}
  market.add_market_item{price={{"raw-fish", 65}}, offer={type="give-item", item="accumulator"}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="big-electric-pole"}}
  market.add_market_item{price={{"raw-fish", 200}}, offer={type="give-item", item="combat-shotgun"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="piercing-shotgun-shell"}}
  market.add_market_item{price={{"raw-fish", 8}}, offer={type="give-item", item="piercing-rounds-magazine", count=2}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="grenade"}}
  market.add_market_item{price={{"raw-fish", 250}}, offer={type="give-item", item="laser-turret"}}
  market.add_market_item{price={{"raw-fish", 20}}, offer={type="give-item", item="land-mine"}}
  market.add_market_item{price={{"raw-fish", 75}}, offer={type="give-item", item="railgun"}}
  market.add_market_item{price={{"raw-fish", 5}}, offer={type="give-item", item="railgun-dart", count=10}}
  market.add_market_item{price={{"raw-fish", 225}}, offer={type="give-item", item="rocket-launcher"}}
  market.add_market_item{price={{"raw-fish", 20}}, offer={type="give-item", item="rocket"}}  
  market.add_market_item{price={{"raw-fish", 35}}, offer={type="give-item", item="explosive-rocket"}}
  market.add_market_item{price={{"raw-fish", 2500}}, offer={type="give-item", item="atomic-bomb"}}
  market.add_market_item{price={{"raw-fish", 30}}, offer={type="give-item", item="artillery-shell"}}
  market.add_market_item{price={{"raw-fish", 20}}, offer={type="give-item", item="cliff-explosives"}}
  market.add_market_item{price={{"raw-fish", 300}}, offer={type="give-item", item="fusion-reactor-equipment"}}
  market.add_market_item{price={{"raw-fish", 300}}, offer={type="give-item", item="exoskeleton-equipment"}}
  --market.add_market_item{price={{"raw-fish", 250}}, offer={type="give-item", item="belt-immunity-equipment"}} 
end

function removeMarketsNear(player, range)
	local surface = game.surfaces[1]
	local start_area = {
		left_top = {player.position.x - range, player.position.y - range},
		right_bottom = {player.position.x + range, player.position.y + range}
	}
	local count = 0
	for _, e in pairs(surface.find_entities_filtered{area=start_area, type="market"}) do
		e.destroy()
		count = count + 1
	end
	return count
end

function market()
	spawnMarketOn(game.players[1])
end
	
local function create_market_init_button(event)
	local player = game.players[1]
	
	if player.gui.top.poll == nil then
		local button = player.gui.top.add { name = "poll", type = "sprite-button", sprite = "item/programmable-speaker" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

remote.add_interface("fish_market", {
	spawnMarketOn = spawnMarketOn,
	removeMarketsNear = removeMarketsNear,
})
