--- Library of wrappers of default objects
--
-- Author: qria
--
--
-- I despise getters and setters so I made a wrapper to kill them,
-- along with some minor fixes that makes your life easier.
--
-- Warning: Be wary of the scope! Objects not using SetVar has a smaller variable scope.

-- Perks of using this library
-- Turn this script:

-- Player.SetVar('vx') = 3 -- X axis velocity
-- Player.SetVar('vy') = -3 -- Y axis velocity
-- function Update()
--     Player.MoveTo(Player.x + Player.GetVar('vx'), Player.y + Player.GetVar('vy'), false)

-- To this script:

-- player.vx = 3
-- player.vy = -3
-- function Update()
--     player.Move(player.vx, player.vy)

-- Details:
--
-- No GetVar, SetVar!
-- => getters and setters in a dynamic languages should be avoided like a plague IMHO.
-- => If you disagree, fite me at unitale discord server.
-- 
-- Clean namespace
-- => Just set variables related to players with player.variable_name 
-- => Avoids cluttering global namespace.
--
-- Consistent Code Style
-- => Player, Encounter, they are all instances. I think they should be lowercase
--
-- Consistent API
-- => Why the hell is `Player.x` readonly? Why is there `Bullet.Move` but no `Player.Move`?
-- => We fixed that!

-- Instructions:
--
-- Put this file in /Libraries folder
-- Put `require "better_var"` at the top of a script
-- You're good to go!


-- Generic wrapping function
-- You'll have to use this when you need to deal with original data types

-- Note this is slightly different from fallback table since it favors parent's key
-- Also note that child's key is favored over parent's key because __index does not get called
-- if child's key exists, but since all new properties have to go through __newindex, child's key
-- cannot exist if there is a parent's key.

function wrap(original_object)
    local new_object = {original_object=original_object}
    setmetatable(new_object, {
        __index = function(table, key)
                -- Access point can be either .GetVar(key) or [key]
                if pcall(function() return table.original_object[key] end) then
                    return table.original_object[key]
                else
                    return table.original_object.GetVar(key)
                end
            end,
        __newindex = function(table, key, value)
                -- Check if key exists in the original object
                if pcall(function() return table.original_object[key] end) or
                    pcall(function() return table.original_object.GetVar(key) end) then
                    table.original_object.SetVar(key, value)
                else
                    rawset(table, key, value)
                end
            end
        })
    return new_object
end

-- Player wrapper

player = {original_object=Player}

setmetatable(player, {
    __index = function(table, key)
            -- Access point can be either .GetVar(key) or [key]
            if pcall(function() return table.original_object[key] end) then
                return table.original_object[key]
            else
                return table.original_object.GetVar(key)
            end
        end,
    __newindex = function(table, key, value)
            -- Check if table.original_object[key] crashes the game or not
            if pcall(function() return table.original_object[key] end) then
                -- Fix since `Player.x, Player.y` is readonly for no reason.
                if key == 'x' then
                    Player.MoveTo(value, Player.y, false)
                elseif key == 'y' then
                    Player.MoveTo(Player.x, value, false)
                elseif key =='absx' then
                    Player.MoveToAbs(value, Player.absy, false)
                elseif key == 'absy' then
                    Player.MoveToAbs(Player.absx, value, false)
                else
                    table.original_object[key] = value
                end
            else
                rawset(table, key, value)
            end
        end
    })


player.Move = function(x, y, ignoreWalls)
    --- Move player x pixels to the right and y pixels up.
    -- I honestly don't get why this function is not implemented in the core engine
    -- Also implemented default value for ignoreWalls
    if ignoreWalls == nil then
        ignoreWalls = false
    end
    player.MoveTo(player.x + x, player.y + y, ignoreWalls)
end


-- Encounter wrapper

encounter = wrap(Encounter)

