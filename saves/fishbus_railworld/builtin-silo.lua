-- This encapsulates the basic silo functionality down into an
-- Event-registration-based series of functions.

require "silo-script" -- This comes from Factorio.
require 'lib/event_extend'

-- gui click
Event.register(defines.events.on_gui_click, function(event)
  silo_script.on_gui_click(event)
end)

	
-- on init
Event.register(Event.core_events.init, function()
  global.version = version
  silo_script.on_init()
end)

-- rocket launch
Event.register(defines.events.on_rocket_launched, function(event)
  silo_script.on_rocket_launched(event)
end)

-- configuration changed
Event.register(Event.core_events.configuration_changed, function(event)
  silo_script.on_configuration_changed(event)
end)

silo_script.add_remote_interface()
silo_script.add_commands()
