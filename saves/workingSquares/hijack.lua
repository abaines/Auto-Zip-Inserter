-- Kizrak

local json = require 'utils.json'

local old_script_on_event = script.on_event

local table_event = {}

if not global.on_event_history then
	global.on_event_history = {}
end

local function doAllEvents(event)

	name = event.name
	
	--game.print(name)

	for index,value in ipairs(table_event[name]) do
	
		value(event)
	
	end
	

end


script.on_event = function(event_id, _function)

	table.insert(global.on_event_history,event_id)

	if not table_event[event_id] then
		table_event[event_id] = {}
	end
	
	table.insert(table_event[event_id],_function)

	old_script_on_event(event_id,doAllEvents);

end

local function print_on_event_history()
	game.print(global.on_event_history)
end


commands.add_command("history", "history",print_on_event_history)
