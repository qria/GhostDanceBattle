player = Encounter.GetVar('player')
DEBUG(type(player.x))

function Update()
    -- You spin me round round
    player.x = 10 * math.cos(Time.time)
    player.y = 10 * math.sin(Time.time)
end

-- -- Uncomment lines below to see the desired behavior

-- player = {original_object=Player}

-- setmetatable(player, {
--     __index = function(table, key)
--             return table.original_object[key]
--         end,
--     __newindex = function(table, key, value)
--             -- Check if table.original_object[key] crashes the game or not
--             if pcall(function() return table.original_object[key] end) then
--                 -- Fix since `Player.x, Player.y` is readonly for no reason.
--                 if key == 'x' then
--                     Player.MoveTo(value, Player.y, false)
--                 elseif key == 'y' then
--                     Player.MoveTo(Player.x, value, false)
--                 elseif key =='absx' then
--                     Player.MoveToAbs(value, Player.absy, false)
--                 elseif key == 'absy' then
--                     Player.MoveToAbs(Player.absx, value, false)
--                 else
--                     table.original_object[key] = value
--                 end
--             else
--                 rawset(table, key, value)
--             end
--         end
--     })