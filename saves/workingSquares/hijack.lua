-- Kizrak

-- special thanks to Kovus, Thuro, & Diablo-D3 for making this happen

local json = require 'utils.json'

local old_script_on_event = script.on_event

local table_event = {}

local on_event_history = {}

local function doAllEvents(event)
	name = event.name

	for index,value in ipairs(table_event[name]) do
		value(event)
	end
end

script.on_event = function(event_id, _function)
	if not table_event[event_id] then
		table_event[event_id] = {}
	end
	
	table.insert(on_event_history,event_id)
	table.insert(table_event[event_id],_function)

	old_script_on_event(event_id,doAllEvents);
end

local function print_on_event_history(event)
	local player = game.players[event.player_index]
	
	player.print("on_event_history #"..#on_event_history)
	player.print(json.stringify(on_event_history))
	
	local printHelper = {}
	local count = 0
	for key,value in pairs(table_event) do
		printHelper[key] = #value
		count = #value + count
	end
	
	player.print("table_event #"..#table_event..'  '..count)
	player.print(json.stringify(printHelper))
end

commands.add_command("history", "history", print_on_event_history)
