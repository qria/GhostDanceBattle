music='empty'

encountertext = "Napstablook" --Modify as necessary. It will only be read out in the action select screen.
wavetimer = 9999999999
arenasize = {155, 130}
nextwaves = {"dance_battle"}

enemies = {"napstablook"}

-- Global napstablook object.
-- Stores everything napstablook related
-- including enemies data, sprites
napstablook = {}

enemypositions = {{0, 0}} -- meaningless cuz it's overwritten elsewhere

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
        -- "Chara... ", -- TODO: Press z to skip
        -- "...",  
        -- "I've been so\nlonely since you\nkilled everyone...",
        -- -- Chara attacks Napstablook
        -- "...",
        -- "You know I'm\n a ghost right?",
        -- "...",
        -- "So...",
        -- "Dance with me...",
        -- "...",
        -- "If you dance\n correctly you\n won't get hurt.",
        -- "...",
        -- "So...", -- Music starts
        "...shall we dance?"
    }
end

function EnemyDialogueEnding()
    -- nextwaves = { possible_attacks[math.random(#possible_attacks)] }

    -- DefenseStarting()
    Audio.LoadFile('ghost_fight')
    start_time = Time.time
end

function DefenseEnding() --This built-in function fires after the defense round ends.
    encountertext = RandomEncounterText() --This built-in function gets a random encounter text from a random enemy.
end

function HandleSpare()
     State("ENEMYDIALOGUE")
end

function HandleItem(ItemID)
    BattleDialog({"Selected item " .. ItemID .. "."})
end
