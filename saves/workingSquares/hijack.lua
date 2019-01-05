-- Kizrak

local json = require 'utils.json'

local old_script_on_event = script.on_event

local table_event = {}

if not on_event_history then
	on_event_history = {}
end

local function doAllEvents(event)
	name = event.name

	for index,value in ipairs(table_event[name]) do
		value(event)
	end

end

script.on_event = function(event_id, _function)

	table.insert(on_event_history,event_id)

	if not table_event[event_id] then
		table_event[event_id] = {}
	end
	
	table.insert(table_event[event_id],_function)

	old_script_on_event(event_id,doAllEvents);

end

local function print_on_event_history()
	game.print("on_event_history")
	game.print(#on_event_history)
	game.print(json.stringify(on_event_history))
	
	game.print("table_event")
	game.print(#table_event)
	local printHelper = {}
	local count = 0
	for key,value in pairs(table_event) do
		printHelper[key] = #value
		count = #value + count
	end
	game.print(json.stringify(printHelper))
	game.print('count'..count)
end


commands.add_command("history", "history",print_on_event_history)
