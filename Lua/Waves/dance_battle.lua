require "better_variables"
require "better_debugging"


-- Global effects
effects = {}
-- Global bullets
bullets = {}

-- Song related
bpm = 225
fps = 60
song_end_beat = 208
time_offset = 0.15

-- Global notes
notes = {}
-- Each note should have a function named `create_bullets` 
-- and it is executed at the first frame when current_beat > note.beat 

function distance(p1, p2)
    --- Calculate distance of two points p1, p2
    -- assummes p1.x, p1.y, p2.x, p2.y exists.
    return math.sqrt((p1.x-p2.x) * (p1.x-p2.x) + (p1.y-p2.y) * (p1.y-p2.y))
end

-- beat 
function current_beat()
    --- Get current beat in float
    -- not int because there can be beats that are not integer (e.g. 1/3 beats)
    return bpm / 60 * (Time.time - encounter.start_time - time_offset)
    -- note that start_time should be defined when audio starts
end


-- Bullet wrapper

function create_projectile(sprite, x, y)
    local projectile = wrap(CreateProjectile(sprite, x, y))
    projectile.created_time = Time.time
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

-- initialize notes

function generate_linear_bullet_note(beat, start_x, start_y, radius, sprite_name, beat_until_collision) 
    --- Linear Bullet Note
    -- Generates a bullet with start position `(start_x, start_y)`
    -- heading to `(player.x, player.y)`
    -- after beat_until_collision, bullet should be right in front of `(player.x, player.y)`
    -- to be percise, `distance(player, bullet)` should be `grace_distance`

    -- set defaults
    radius = radius or 4
    sprite_name = sprite_name or 'bullet_circle'
    beat_until_collision = beat_until_collision or 4
    grace_distance = 25


    -- generate note
    note = {}
    note.beat = beat
    note.beat_until_collision = beat_until_collision
    note.start_beat = note.beat - beat_until_collision
    note.create_bullets = function()
        -- calculate the goal point
        start = {x=start_x, y=start_y}
        d = grace_distance
        s = distance(start, player)
        goal = {
            x = ((s-d) * player.x + d * start.x) / s,
            y = ((s-d) * player.y + d * start.y) / s
        }

        bullet = create_bullet(sprite_name, start_x, start_y)
        time_until_collision = beat_until_collision * 60 / bpm
        bullet.vx = (goal.x - bullet.x) / time_until_collision / fps
        bullet.vy = (goal.y - bullet.y) / time_until_collision / fps
        bullet.r = radius
        bullet.update = function(self)
            self.Move(self.vx or 0, self.vy or 0)
        end
        table.insert(bullets, bullet)
    end
    return note
end

function generate_rhythmic_linear_bullet_note(beat, start_x, start_y, radius, sprite_name, beat_until_collision, t_step) 
    --- Rhythmic Linear Bullet Note
    -- It's a linear bullet, but moves 
    -- It was super hard to calcuate the position.
    -- Calculations are in the file rhythmic_bullet_calculation.JPG somewhere in the folder

    -- Argument parsing

    local radius = radius or 4
    local sprite_name = sprite_name or 'bullet_circle'
    local beat_until_collision = beat_until_collision or 4
    local grace_distance = 25
    local bullet_speed = 200 -- pixel per beat
    local t_step = t_step or 1

    -- generate note
    note = {}
    note.beat = beat
    note.beat_until_collision = beat_until_collision
    note.start_beat = note.beat - beat_until_collision
    note.sprite_name = sprite_name
    note.start_x = start_x
    note.start_y = start_y
    note.bullet_speed = bullet_speed
    note.radius = radius
    note.t_step = t_step

    note.create_bullets = function(self)
        local bullet = create_bullet(self.sprite_name, self.start_x, self.start_y)
        bullet.start = {x=self.start_x, y=self.start_y}
        bullet.beat = self.beat -- beat at the time of collision
        local s = distance(bullet.start, player)
        local g = grace_distance
        bullet.goal = {
            x = (g * bullet.start.x + (s-g) * player.x) / s,
            y = (g * bullet.start.y + (s-g) * player.y) / s
        }
        bullet.r = self.radius
        bullet.n_beat = beat_until_collision
        bullet.v = self.bullet_speed
        bullet.t_step = self.t_step

        bullet.update = function(self)
            -- See rhythmic_bullet_calculation.JPG for explanation of paramters
            local t = current_beat() - self.beat
            local n = bullet.n_beat -- beat until collision
            local d = distance(bullet.start, bullet.goal)
            local v = bullet.v
            local x0, y0 = bullet.start.x, bullet.start.y
            local x1, y1 = bullet.goal.x, bullet.goal.y 
            local t_step = bullet.t_step
            local step = math.floor((t + d/n/2 / v) / t_step)
            local tmp = ((t - n) + d/n/2 / v) % t_step
            local f
            if 0 <= tmp and tmp < d/n / v then
                f = step * d/n + v * (t - t_step * step)
            else
                f = step * d/n + d/n/2
            end
            local x = x1 + (x1-x0) * (f/d)
            local y = y1 + (y1-y0) * (f/d)
            self.MoveTo(x, y)
        end
        table.insert(bullets, bullet)
    end
    return note
end
function generate_notes()
    r = 300
    for i, n in ipairs({32, 34, 36, 38, 40, 42, 44, 46, 
                        48, 50, 52, 54, 56, 58, 60, 62,
                        64, 66, 68, 70, 72, 74, 76, 78,
                        80, 82, 84, 86, 88, 90, 92, 94,
                        96, 98, 100, 102, 104, 106, 108, 110, 
                        112, 114, 116, 118, 120, 122, 124, 126, 
                        128, 129.5, 132, 133.5, 136, 138, 140, 142,
                        144, 145.5, 148, 149.5, 152, 153, 154, 154 + 2/3, 154 + 4/3, 156, 158, 
                        160, 161.5, 164, 165.5, 168, 170, 172, 174, 
                        176, 177.5, 180, 181.5, 184, 185, 186, 186 + 2/3, 186 + 4/3, 188, 190, 
                        }) do
        theta = math.random() * math.pi
        table.insert(notes, generate_rhythmic_linear_bullet_note(n, r * math.cos(theta), r * math.sin(theta)))
        table.insert(notes, generate_rhythmic_linear_bullet_note(n, r * math.cos(math.pi + theta), r * math.sin(math.pi + theta)))
        if n >= 128 then
            table.insert(notes, generate_rhythmic_linear_bullet_note(n, r * math.cos(math.pi / 2 +theta), r * math.sin(math.pi / 2 + theta)))
            table.insert(notes, generate_rhythmic_linear_bullet_note(n, r * math.cos(math.pi * 3 / 2 + theta), r * math.sin(math.pi * 3 / 2 + theta)))
        end
    end
end
generate_notes()

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

protect_update()


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
    if(Input.Confirm == 1) then
        stomp()
    end 
end

function stomp()
    log('stomped:', current_beat())
    -- Play sound
    Audio.PlaySound('stomp1')

    -- Add stomping animation
    local stomp_effect = create_effect('stomp_effect', player.x, player.y)
    stomp_effect.lifespan = 20  -- lifespan frame
    stomp_effect.name = 'stomp' -- for debugging
    table.insert(effects, stomp_effect)

    -- Delete bullets in radius
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if distance(player, bullet) < 50 then
            bullet.Remove()
            table.remove(bullets, i)
        end
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
