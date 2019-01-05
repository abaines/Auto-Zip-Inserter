--- The game module.
-- @module Game
-- @usage local Game = require('stdlib/game')

-- This version has been modified from the original version on
-- https://github.com/Afforess/Factorio-Stdlib .  It has been truncated
-- to only require 'stdlib/utils/table' and contain fail_if_missing.

require 'stdlib/utils/table'

Game = { --luacheck: allow defined top
    VALID_FILTER = function(v)
        return v and v.valid
    end,
    _protect = function(module_name)
        return {
            __newindex = function() error("Attempt to mutatate read-only "..module_name.." Module") end,
            __metatable = true
        }
    end,
    _concat = function(lhs, rhs)
        --Sanatize to remove address
        return tostring(lhs):gsub("(%w+)%: %x+", "%1: (ADDR)") .. tostring(rhs):gsub("(%w+)%: %x+", "%1: (ADDR)")
    end,
    _rawstring = function (t)
        local m = getmetatable(t)
        local f = m.__tostring
        m.__tostring = nil
        local s = tostring(t)
        m.__tostring = f
        return s
    end
}

--- Print msg if specified var evaluates to false.
-- @tparam Mixed var variable to evaluate
-- @tparam[opt="missing value"] string msg message
function Game.fail_if_missing(var, msg)
    if not var then
        error(msg or "Missing value", 3)
    end
    return false
end

return Game
