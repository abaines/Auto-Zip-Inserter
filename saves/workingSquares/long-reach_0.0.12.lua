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

script.on_init(function ()
	apply_long_reach_settings()	
end)

script.on_configuration_changed(function (data)
	apply_long_reach_settings()		
end)

script.on_event(defines.events.on_runtime_mod_setting_changed,function ()
	apply_long_reach_settings()
end)


function apply_long_reach_settings()
	local settings = settings.global
	local default_action_distance = 6
	
	
	game.forces["player"].character_build_distance_bonus = 125 - default_action_distance
	game.forces["player"].character_reach_distance_bonus = 125 - default_action_distance
	
end

