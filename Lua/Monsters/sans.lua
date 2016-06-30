-- A basic monster script skeleton you can copy and modify for your own creations.
comments = {"Smells like 'dog.", "Looking good.", "Is that ketchup?"}
commands = {"Act 1", "Act 2", "Act 3"}
randomdialogue = {"[font:sans]..."}

sprite = "empty" --Always PNG. Extension is added automatically.
name = "Skeleton"
hp = 100
atk = 1
def = 1
check = "Check message goes here."
dialogbubble = "right" -- See documentation for what bubbles you have available.
cancheck = true
canspare = false

-- Happens after the slash animation but before 
function HandleAttack(attackstatus)
    if attackstatus == -1 then
        -- player pressed fight but didn't press Z afterwards
    else
        -- player did actually attack
    end
end
 
-- This handles the commands; all-caps versions of the commands list you have above.
function HandleCustomCommand(command)
    if command == "ACT 1" then
        currentdialogue = {"Selected\nAct 1."}
    elseif command == "ACT 2" then
        currentdialogue = {"Selected\nAct 2."}
    elseif command == "ACT 3" then
        currentdialogue = {"Selected\nAct 3."}
    end
    currentdialogue = {"[font:sans]" .. currentdialogue[1]}
    BattleDialog({"You selected " .. command .. "."})
    
end