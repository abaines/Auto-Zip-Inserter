--Grief detection
--Written by Mylon, 2017-2018
--MIT License

require 'stdlib/event/event'
require 'lib/event_extend'

antigrief = {}
global.antigrief_cooldown = {}
global.antigrief = {warned = {}}

antigrief.TROLL_TIMER = 60 * 60 * 30 --30 minutes.  Players must be online this long to not throw some warnings.
antigrief.SPAM_TIMER = 60 * 60 * 2 --2 minutes.  Limit inventory related messages to once per 10m.

antigrief.alert_event = Event.def("antigrief_alert")
antigrief.ban_event = Event.def("ban_player")
antigrief.kick_event = Event.def("kick_player")

--ACTIVE functions
function antigrief.arty_remote_ban(event)
    local player = game.players[event.player_index]
    local area = {{event.position.x-20, event.position.y-20}, {event.position.x+20, event.position.y+20}}
    local count = player.surface.count_entities_filtered{force=player.force, area=area}
    local ghosts = player.surface.count_entities_filtered{name="entity-ghost", force=player.force, area=area}

    --Ghosts don't count!  They can't be damaged.
    count = count - ghosts

    if event.item.name == "artillery-targeting-remote" and count > 50 then
        --antigrief.banhammer(player)
        antigrief.alert(player.name .. " is using an artillery remote maliciously.", player.character)
    elseif string.find(event.item.name, "grenade") then
		local entcount = player.surface.count_entities_filtered{force=player.force, area=area, name="steam-engine"}
		entcount = entcount + player.surface.count_entities_filtered{force=player.force, area=area, name="steam-turbine"}
		if entcount > 20 then
			--antigrief.banhammer(player)
        	antigrief.alert(player.name .. " is using grenades near power.", player.character)
		end
    end
end

function antigrief.banhammer(player)
    --If player is > level 5, then warn first.
    --What permission group is the player in?
    if player.permission_group.name == "trusted" then --Kick first.
        if not global.antigrief.warned[player.name] then
            global.antigrief.warned[player.name] = true
            game.kick_player(player, "griefing (automoderator)")
			Event.dispatch({
				name = antigrief.kick_event,
				player_index = player.index,
				reason = "griefing (automoderator)",
			})
        end
    else
        game.ban_player(player, "griefing (automoderator)")
		Event.dispatch({
			name = antigrief.ban_event,
			player_index = player.index,
			player_name = game.players[player.index].name,
			reason = "griefing (automoderator)",
		})
    end
end


--PASSIVE functions
--Common tactic is to remove pump.  So if someone landfills a pump and removes it... That's a huge red flag.
function antigrief.pump(event)
    if not event.entity and not event.entity.valid then
        return
    end
    --Only check for entities in a specific list.
    if antigrief.is_well_pump(event.entity) then
        local player = game.players[event.player_index]
        antigrief.alert(player.name .. " has mined a well-water pump.", event.entity)
    end
end

--Look for players mining ghosts far away.
--Spooky action at a distance!
function antigrief.ghosting(event)
    local player = game.players[event.player_index]
    if not event.entity and not event.entity.valid and not player and not player.valid then
        return
    end
    if event.entity.type == "entity-ghost" then
        --Look for units mined 200 tiles away.
        if math.abs(event.entity.position.x - player.position.x) + math.abs(event.entity.position.y - player.position.y) > 200 then
            if antigrief.check_cooldown(event.player_index, "ghosting") then
                antigrief.alert(player.name .. " is removing blueprint ghosts.", event.entity)
            end
        end
    end
end

--When someone decons > 150 entities, fire an alert
function antigrief.decon(event)
    if event.alt then --This is a cancel order.
        return
    end
    if event.area.left_top.x == event.area.right_bottom.x or event.area.left_top.y == event.area.right_bottom.y then
        --log("Antigrief: Deconstruction area is of zero size.")
        return
    end
    local player = game.players[event.player_index]
    local count = player.surface.count_entities_filtered{area=event.area, force=player.force}
    if count >= 150 then
        --Need a proper check of entities.  Most might be filtered out and not actually deconned.
        local ents = player.surface.find_entities_filtered{area=event.area, force=player.force}
        count = 0
        for k, v in pairs(ents) do
            if v.to_be_deconstructed(player.force) then
                count = count + 1
            end
        end
        if count >= 150 then
            antigrief.alert(player.name .. " has deconstructed ".. count .. " entities.", player.character)
            return
        end
    end
    --Check to see if a off-shore pump was targetted.
    local ents = player.surface.find_entities_filtered{area=event.area, force=player.force, name="offshore-pump"}
    for k, v in pairs(ents) do
        if v.to_be_deconstructed(player.force) and antigrief.is_well_pump(v) then
            antigrief.alert(player.name .. " has marked a well-water pump for deconstruction", v)
            return
        end
    end
end

--If new players equip an atomic bomb... Throw a warning!
function antigrief.da_bomb(event)
    local player = game.players[event.player_index]
    if player.online_time > antigrief.TROLL_TIMER then
        return
    end
    if player.get_item_count("atomic-bomb") > 0 then
        if antigrief.check_cooldown(event.player_index, "atomic") then
            antigrief.alert(player.name .. " has equipped an Atomic Bomb.", player.character)
        end
    end
end

--If new players equip an artillery remote... Throw a warning!
function antigrief.remote(event)
    local player = game.players[event.player_index]
    if player.online_time > antigrief.TROLL_TIMER then
        return
    end
    if player.cursor_stack.valid_for_read and player.cursor_stack.name == "artillery-targeting-remote" then
        if antigrief.check_cooldown(event.player_index, "artillery") then
            antigrief.alert(player.name .. " has equipped an artillery remote.", player.character)
        end
    end
end

--Look for players hoarding high value items.
function antigrief.hoarder(event)
    local player = game.players[event.player_index]
    if player.online_time > antigrief.TROLL_TIMER then
        return
    end
    if ( player.get_item_count("speed-module-3") > 10 or
        player.get_item_count("productivity-module-3") > 10 or
        player.get_item_count("effectivity-module-3") > 10 ) and 
        antigrief.check_cooldown(event.player_index, "hoarding") then
            antigrief.alert(player.name .. " is hoarding T3 modules.", player.character)
    end
    if player.get_item_count("uranium-235") > 30 and antigrief.check_cooldown(event.player_index, "hoarding") then
        antigrief.alert(player.name .. " is hoarding ".. player.get_item_count("uranium-235") .. " U-235.", player.character)
    end
    if player.get_item_count("power-armor-mk2") >= 2 and antigrief.check_cooldown(event.player_index, "hoarding") then
        antigrief.alert(player.name.. " is hoarding power armor mk2s.", player.character)
    end
end

--Did someone craft/request Mk2 power armor and then log out?
function antigrief.armor_drop(event)
    local player = game.players[event.player_index]
    if player.online_time > antigrief.TROLL_TIMER then
        return
    end
    if player.get_item_count("power-armor-mk2") >= 1 then
        local armor = player.get_inventory(defines.inventory.player_armor).find_item_stack("power-armor-mk2") or
        player.get_inventory(defines.inventory.player_main).find_item_stack("power-armor-mk2") or
        player.get_inventory(defines.inventory.player_quickbar).find_item_stack("power-armor-mk2") or
        player.get_inventory(defines.inventory.player_trash).find_item_stack("power-armor-mk2")

        if armor then
            local item = player.surface.spill_item_stack(player.position, armor) --This could be used to duplicate equipment if we remove the wrong PA2.  But such a weird edge case...
            player.remove_item("power-armor-mk2")
            if item and item.valid then --It may have dropped on a belt
                item.order_deconstruction(player.force)
            end
        else --Something went wrong.  We should have found the armor.  God inventory?
            log("Antigrief: Power Armor mk2 detected but not found")
        end
    end           
end

--Look for players merging roboport networks
function antigrief.check_size_loginet_size(event)
    if not (event.entity and event.entity.valid and event.entity.type == "roboport") then
        return
    end
    if not (event.entity.last_user) then
        --How did we get here?
        return
    end
    local network = event.entity.logistic_network
    local cells = network.cells
    if not (cells[1] and cells[1].valid) then
        return
    end
    local minx, miny, maxx, maxy = cells[1].owner.position.x, cells[1].owner.position.y, cells[1].owner.position.x, cells[1].owner.position.y
    for k, v in pairs(cells) do
        if v.owner.position.x < minx then
            minx = v.owner.position.x
        elseif v.owner.position.x > maxx then
            maxx = v.owner.position.x
        end
        if v.owner.position.y < miny then
            miny = v.owner.position.y
        elseif v.owner.position.y > maxy then
            maxy = v.owner.position.y
        end
    end

    if math.abs(maxx-minx) > 2000 or math.abs(maxy-miny) then
        antigrief.alert(event.entity.last_user.name .. "has placed a roboport in a large network.", event.entity)
    end
end

--Print text to online admins and write to the log.
function antigrief.alert(text, cause)
    for n, p in pairs(game.connected_players) do
        if p.admin then
            p.print(text)
            if cause then
                p.add_custom_alert(cause, {type="virtual", name="signal-A"}, text, true)
            end
        end
    end
	if remote.interfaces['perms'] then
		remote.call('perms', 'executeOnGroupUsers', 'moderator', true, false, {}, function(playerName)
			local player = getPlayerNamed(playerName)
			if not player.admin then
	            player.print(text)
				if cause then
					player.add_custom_alert(cause, {type="virtual", name="signal-A"}, text, true)
				end
			end
		end)
	end
    log("Antigrief: " .. text)
	Event.dispatch({
		name = antigrief.alert_event,
		message = text,
	})
end

--Check if a message has been generated about this player recently.  If true, set cooldown.
function antigrief.check_cooldown(player_index, type)
    if not global.antigrief_cooldown[player_index] then
        global.antigrief_cooldown[player_index] = {}
    end
    local cooldowns = global.antigrief_cooldown[player_index]
    --Type matches?  Check CD
    if not cooldowns[type] then cooldowns[type] = -antigrief.SPAM_TIMER end
    local tick = cooldowns[type]
    if tick < game.tick then
        cooldowns[type] = game.tick + antigrief.SPAM_TIMER
        global.antigrief_cooldown[player_index] = cooldowns
        return true
    end
    return false
end

--Is this a water-well pump?
function antigrief.is_well_pump(entity)
    if entity.name ~= "offshore-pump" then
        return false
    end
    if not (entity.surface.get_tile(entity.position.x+1, entity.position.y).collides_with("water-tile") or
        entity.surface.get_tile(entity.position.x, entity.position.y+1).collides_with("water-tile") or
        entity.surface.get_tile(entity.position.x-1, entity.position.y).collides_with("water-tile") or
        entity.surface.get_tile(entity.position.x, entity.position.y-1).collides_with("water-tile")) then

        return true
    end
end

function antigrief.wanton_destruction(event)
    if not (event.entity and event.entity.valid) then
        return
    end
    if not (event.cause and event.cause.type == "player") then
        return
    end
    if event.cause.force == event.entity.force then
        --Friendly fire detected!
        if antigrief.is_well_pump(event.entity) then
            antigrief.alert(event.cause.player.name .. " destroyed a well-water pump", event.entity)
            return
        end
        if event.entity.type == "player" and event.entity.player then
            antigrief.alert(event.cause.player.name .. " killed " .. event.entity.player.name, event.entity)
            return
        end
        if event.cause.player then
            if antigrief.check_cooldown(event.cause.player.index, "destruction") then
                antigrief.alert(event.cause.player.name .. " is destroying friendly entities.", event.entity)
            end
        end
    end
end

Event.register(defines.events.on_player_used_capsule, antigrief.arty_remote_ban)
Event.register(defines.events.on_player_ammo_inventory_changed, antigrief.da_bomb)
Event.register(defines.events.on_player_cursor_stack_changed, antigrief.remote)
Event.register(defines.events.on_player_main_inventory_changed, antigrief.hoarder)
Event.register(defines.events.on_player_left_game, antigrief.armor_drop)
Event.register(defines.events.on_player_mined_entity, antigrief.pump)
Event.register(defines.events.on_player_mined_entity, antigrief.ghosting)
Event.register(defines.events.on_entity_died, antigrief.wanton_destruction)
Event.register(defines.events.on_built_entity, antigrief.check_size_loginet_size)
Event.register(defines.events.on_robot_built_entity, antigrief.check_size_loginet_size)
Event.register(defines.events.on_player_deconstructed_area, antigrief.decon)
