music='empty'

encountertext = "Napstablook" --Modify as necessary. It will only be read out in the action select screen.
wavetimer = 9999999999
arenasize = {155, 130}
nextwaves = {"error"}

enemies = {"napstablook"}

-- Global napstablook object.
-- Stores everything napstablook related
-- including enemies data, sprites
napstablook = {}

enemypositions = {{0, 0}} 


-- Player wrapper

player = {original_object=Player}

setmetatable(player, {
    __index = function(table, key)
            return table.original_object[key]
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

function EncounterStarting()
    Player.name = 'Chara'

    -- Initialize napstablook object
    -- if key lookup fails, consult fallback 
    -- Since napstablook is mostly empty, you almost always fallback
    napstablook.fallback = enemies[1]
    setmetatable(napstablook, {
        __index = function(table, key)
            return table.fallback.GetVar(key)
            end
        ,
        __newindex =
         function(table, key, value)
            table.fallback.SetVar(key, value)
            end
        })
    require "Animations/napstablook_animation" 

    -- Proc dialogue right away
    State('ENEMYDIALOGUE')

end

function Update()
    AnimateNapstablook()
end

function EnemyDialogueStarting()
    napstablook.dialogbubble = 'rightwide'
    napstablook.currentdialogue = {
        "...shall we dance?"
    }
end

function EnemyDialogueEnding()
    Audio.LoadFile('ghost_fight')
    start_time = Time.time
end

function DefenseEnding() --This built-in function fires after the defense round ends.
    -- encountertext = RandomEncounterText() --This built-in function gets a random encounter text from a random enemy.
end

function HandleSpare()
     State("ENEMYDIALOGUE")
end

function HandleItem(ItemID)
    BattleDialog({"Selected item " .. ItemID .. "."})
end
