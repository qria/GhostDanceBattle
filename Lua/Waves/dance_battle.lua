require "better_variables"
require "better_debugging"
require "dance_library"


-- Song related
bpm = 225
song_end_beat = 208
time_offset = 0.15

function distance(p1, p2)
    --- Calculate distance of two points p1, p2
    -- assummes p1.x, p1.y, p2.x, p2.y exists.
    return math.sqrt((p1.x-p2.x) * (p1.x-p2.x) + (p1.y-p2.y) * (p1.y-p2.y))
end


-- initialize notes
function generate_first_part(beat)
    -- linear bullet note randomly generated
    local r = 300
    local theta = math.random() * math.pi
    table.insert(notes, generate_linear_bullet_note(beat, r * math.cos(theta), r * math.sin(theta)))
    table.insert(notes, generate_linear_bullet_note(beat, r * math.cos(math.pi + theta), r * math.sin(math.pi + theta)))
end

for i, n in ipairs({32, 34, 36, 38, 40, 42, 44, 46, 
                    48, 50, 52, 54, 56, 58, 60, 62}) do
    generate_first_part(n)
end

function generate_second_part(beat)
    -- rhythmic linear bullet note randomly generated
    local r = 300
    local theta = math.random() * math.pi
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(theta), r * math.sin(theta)))
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(math.pi + theta), r * math.sin(math.pi + theta)))

end

for i, n in ipairs({ 64,                 72,       76,   
                     80,  82,  84,  86,  88,  90,  92,  94,    
                     96,  98, 100, 102, 104, 106, 108, 110, 
                    112, 114, 116, 118, 120, 122, 124, 126, }) do
    generate_second_part(n)
end

function generate_third_part(beat)
    -- rhythmic linear bullet note 4 way
    local r = 300
    local theta = math.random() * math.pi
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(theta), r * math.sin(theta)))
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(math.pi + theta), r * math.sin(math.pi + theta)))
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(math.pi / 2 +theta), r * math.sin(math.pi / 2 + theta)))
    table.insert(notes, generate_rhythmic_linear_bullet_note(beat, r * math.cos(math.pi * 3 / 2 + theta), r * math.sin(math.pi * 3 / 2 + theta)))

end

for i, n in ipairs({128, 129.5, 132, 133.5, 136, 138, 140, 142,
                    144, 145.5, 148, 149.5, 152, 153, 154, 154 + 2/3, 154 + 4/3, 156,  
                    160, 161.5, 164, 165.5, 168, 170, 172, 174, 
                    176, 177.5, 180, 181.5, 184, 185, 186, 186 + 2/3, 186 + 4/3, 188,  
                    }) do
    generate_third_part(n)
end

-- Set base positions
-- Note since players aren't allowed to move around, 
-- we track them via (x_base, y_base) not (x, y)
player.x_base = 0
player.y_base = 0
-- Amusingly, `player.x_base, player.y_base = 0, 0` crashes the game


-- Main update loop
update_counter = 0  -- current update number
function Update()


    update_counter = update_counter + 1
    -- players can't move
    player.MoveTo(player.x_base, player.y_base, false)
    handle_keyboard_inputs()
    create_bullets()
    update_bullets()
    update_effects()

    -- Update once per beat

    beat_counter = beat_counter or 0
    if current_beat() > beat_counter then
        update_per_beat(beat_counter)
        beat_counter = beat_counter + 1
    end
end
protect_update() -- Enter Debug mode when error


function update_per_beat(beat)
    -- print current beat
    log('Beat=', beat)

    -- Add heartbeat animation
    if beat % 2 == 0 then
        local heartbeat_effect = create_effect('heartbeat', player.x, player.y)
        heartbeat_effect.lifespan = 3
        heartbeat_effect.name = 'heartbeat'
        heartbeat_effect.update = function(self)
            -- Always move to on top of player
            heartbeat_effect.sprite.x = player.absx
            heartbeat_effect.sprite.y = player.absy
        end
        table.insert(effects, heartbeat_effect)
    end

    -- Check song end
    if current_beat() > song_end_beat then
        Audio.Stop()
        EndWave()
    end
end

function handle_keyboard_inputs()

    if(Input.Left == 1) then
        player.Move(-4, 0)  -- Lean slightly left
    elseif(Input.Left == 2) then
        player.Move(-8, 0)  -- Lean left
    end

    if(Input.Right == 1) then
        player.Move(4, 0)  -- Lean slightly right
    elseif(Input.Right == 2) then
        player.Move(8, 0)  -- Lean right
    end

    if(Input.Down == 1) then
        player.Move(0, -4)  -- Lean slightly downward
    elseif(Input.Down == 2) then
        player.Move(0, -8)  -- Lean downward
    end

    if(Input.Up == 1) then
        player.Move(0, 4)  -- Lean slightly upward
    elseif(Input.Up == 2) then
        player.Move(0, 8)  -- Lean upward
    end

    -- Handle stomp last since it uses player.x, player.y
    if(Input.Confirm == 1 or Input.Cancel == 1) then
        stomp()
    end 
end

function stomp()
    log('stomped:', current_beat())
    -- Play stomping sound
    Audio.PlaySound('stomp2')

    -- Add stomping animation
    local stomp_effect = create_effect('stomp_effect', player.x, player.y)
    stomp_effect.lifespan = 20  -- lifespan frame
    stomp_effect.name = 'stomp' -- for debugging
    table.insert(effects, stomp_effect)

    local bullet_stomped = false
    -- Delete bullets in radius
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if distance(player, bullet) < 50 then
            bullet.Remove()
            table.remove(bullets, i)
            bullet_stomped = true
        end
    end

    -- Play stomped sound
    if bullet_stomped then
        Audio.PlaySound('stomp1')
    end
end

function create_bullets()
    --- Create Bullets along the beat
    for i, note in ipairs(notes) do
        if (current_beat() >= note.start_beat) then
            if not note.created then
                note:create_bullets()
                note.created = true
            end
        end
    end
end

function update_bullets()
    -- iterate reverse since table is modified when removing
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update()
        if bullet.lifespan ~= nil then
            -- If lifespan is given, handle it
            if (bullet.lifespan < 0) then
                bullet.Remove()
                table.remove(bullets, i)
            else
                bullet.lifespan = bullet.lifespan - 1
            end
        end
    end
end

function update_effects()
    local i = #effects 
    while i >= 1 do  -- For some reason for loop here makes it so that it runs only the first iteration. It took me 8 hours to find this.
        local effect = effects[i]

        -- If update is given, handle it
        if effect.update then
            effect:update()
        end

        -- If lifespan is given, handle it
        if effect.lifespan ~= nil then
            if(effect.lifespan <= 0) then
                effect.Remove()
                table.remove(effects, i)
            else
                effect.lifespan = effect.lifespan - 1
            end
        end
        i = i - 1
    end
end

function OnHit(projectile)
    bullet = wrap(projectile)
    if bullet.type == 'effect' then
        -- Ignore all effect type projectiles
        return
    end
    player.Hurt(2)
end
