require "better_variables"

effects = {}
bullets = {}

-- Song related
bpm = 225
fps = 30
song_end_beat = 208

-- Set base positions
-- Note since players aren't allowed to move around, 
-- we track them via (x_base, y_base) not (x, y)
player.x_base = 0
player.y_base = 0
-- Amusingly, `player.x_base, player.y_base = 0, 0` crashes the game

-- beat 

function current_beat()
    --- Get current beat in float
    -- not int because there can be beats that are not integer (e.g. 1/3 beats)
    return bpm / 60 * (Time.time - encounter.start_time)
    -- note that start_time should be defined when audio starts
end


-- Bullet wrapper

function create_projectile(sprite, x, y)
    local projectile = wrap(CreateProjectile(sprite, x, y))
    return projectile
end

function create_bullet(sprite, x, y)
    local bullet = create_projectile(sprite, x, y)
    bullet.type = 'bullet'
    return bullet
end

function create_effect(sprite, x, y)
    local effect = create_projectile(sprite, x, y)
    effect.type = 'effect'
    return effect
end

-- Main update loop

function Update()
    -- players can't move
    player.MoveTo(player.x_base, player.y_base, false)
    handle_keyboard_inputs()

    create_bullets()
    update_bullets()
    update_effects()

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
    elseif(Input.right == 2) then
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
    if(Input.Confirm == 1) then
        stomp()
    end
end

function stomp()

    -- Play sound
    Audio.PlaySound('stomp1')

    -- Add stomping animation
    -- Note it is registered as a projectile cuz sprites don't work
    local stomp_effect = create_effect('stomp_effect', player.x, player.y)
    stomp_effect.lifespan = 30  -- lifespan frame
    table.insert(effects, stomp_effect)
    -- Delete bullets in radius
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if math.abs(bullet.x - player.x) < 100 then
            bullet.Remove()
            table.remove(bullets, i)
        end
    end
end


next_bullet_summon_time = 28
function create_bullets()
    --- Create Bullets along the beat
    if(current_beat() > next_bullet_summon_time) then
        r = 300
        bullet = create_bullet('bullet_circle', player.x + r, player.y)
        bullet.vx = (player.x + 60 - bullet.x) / (8 * 60 / bpm * fps) -- 8 beat until it gets player
        bullet.vx = -3
        bullet.vy = 0
        table.insert(bullets, bullet)
        next_bullet_summon_time = next_bullet_summon_time + 2
    end
end

function update_bullets()
    -- iterate reverse since table is modified when removing
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.Move(bullet.vx, bullet.vy)
        if bullet.x < -100 then
            bullet.Remove()
            table.remove(bullets, i)
        end
    end
end

function update_effects()
    for i = #effects, 1, -1 do
        local effect = effects[i]
        if(effect.lifespan < 0) then
            effect.Remove()
            table.remove(effects, i)
        else
            effect.lifespan = effect.lifespan - 1
        end
    end
end

function OnHit(projectile)
    bullet = wrap(projectile)
    if bullet.type == 'effect' then
        -- Ignore all effect type projectiles
        return
    end

    bullet.vx = 0
    bullet.vy = 0

    player.Hurt(1)
end

-- Below is the original example code

-- You've seen this one in the trailer (if you've seen the trailer).
-- spawntimer = 0
-- bullets = {}
-- yOffset = 180
-- mult = 0.5

-- function Update()
--     spawntimer = spawntimer + 1
--     if(spawntimer % 30 == 0) then
--         local numbullets = 10
--         for i=1,numbullets+1 do
--             local bullet = CreateProjectile('bullet', 0, yOffset)
--             bullet.SetVar('timer', 0)
--             bullet.SetVar('offset', math.pi * 2 * i / numbullets)
--             bullet.SetVar('negmult', mult)
--             bullet.SetVar('lerp', 0)
--             table.insert(bullets, bullet)
--         end
--         mult = mult + 0.05
--     end

--     for i=1,#bullets do
--         local bullet = bullets[i]
--         local timer = bullet.GetVar('timer')
--         local offset = bullet.GetVar('offset')
--         local lerp = bullet.GetVar('lerp')
--         local neg = 1
--         local posx = (70*lerp)*math.sin(timer*bullet.GetVar('negmult') + offset)
--         local posy = (70*lerp)*math.cos(timer + offset) + yOffset - lerp*50
--         bullet.MoveTo(posx, posy)
--         bullet.SetVar('timer', timer + 1/40)
--         lerp = lerp + 1 / 90
--         if lerp > 4.0 then
--             lerp = 4.0
--         end
--         bullet.SetVar('lerp', lerp)
--     end
-- end