-- dependency for other mods:
require 'lib/event_extend'

require 'util' -- Factorio-provided
require "builtin-silo"
require "builtin-playerspawn"

require 'permissions'

require 'playerlist_gui'
require "autodeconstruct"
require 'fill4me/init'
require 'vehicle_snap'
require 'block_player_colors'
require 'death_marker'
require 'fishing'
require "fish_market"
require 'fishybiz'
require 'fish_perks'
require 'fish_perks_gui'
require 'fish_perks_persist'
require "flashlight_off"
require 'game_time'
require 'ktags'
require 'score'
require 'info_gui'
require 'admin_gui'
require 'adv_admin'
require 'antigrief'
require 'automessage'
require 'lib/player_distance'
require 'lib/player_time'
require 'lib/event_health_regen'

require 'lib/message_queue'
require 'lib/keystore'
require 'lib/rdchat'
--require 'show-health' -- Do not load, for now - Kov.

--require 'fb_antigriefing'
--require 'fb_automessage'

local version = 1

Event.register(Event.core_events.init, function()
	global.version = version
end)

Event.register(Event.core_events.configuration_changed, function(event)
	if global.version ~= version then
		global.version = version
	end
end)

-- a clear-all-gui buttons we create function.  Limit this to the admins we know about.
accepted_admins = {
	'Splicer9',
	'kovus',
	'Merc_Plays'
}
local function clear_gui_elements(player)
	-- modify as needed for removing specific buttons.
	kw_delToolbarButton(player, 'admin_toggle') -- admin_gui
	kw_delToolbarButton(player, 'advadmin_toggle') -- adv_admin
	kw_delToolbarButton(player, 'btn_toolbar_fill4me') -- fill4me
	kw_delToolbarButton(player, 'band_toggle_btn') -- band
	kw_delToolbarButton(player, 'info_toggle') -- info
	kw_delToolbarButton(player, 'btn_score') -- score

	-- This *shouldn't* break other mods, but depending how they manage their windows, it could.
	local container = mod_gui.get_frame_flow(player)
	container.clear()
	local container = player.gui.center
	container.clear()
end
commands.add_command('clear.gui', 'Clear out all of the GUI elements created by the fishbus mod pack', function(data)
	-- This function is limited to the users listed in accepted_admins.
	game.print(serpent.block(data))
	game.print(game.player.name)
	for idx, adminname in pairs(accepted_admins) do
		if adminname == game.player.name then
			-- actually clear all the functions
			for idx, player in pairs(game.players) do
				clear_gui_elements(player)
			end
		end
	end
end)
