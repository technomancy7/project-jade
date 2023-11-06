
return {
    -- Name of our script
    name = "abyssal",
    
    autoload = false,
    
    -- Author name
    author = "Technomancer",
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Abyssal Story scripts loaded.")
    end,
    hooks = {
    },
    events = {
        testalt = {
            title = "A test encounter?",
            conditions = {"true == true"},
            body = [[
            There's nothing here!?
            why?
            ]],
            choices = {
                {"Okay! [back to ship]", "end"},
                {"Wait, what's that over there!", "goto test2"},
                {"Start Tutorial", "goto awakening"}
            }
        },
        need_help = {
            title = "Need some help?",
            conditions = {"CurrentSave.player.fuel <= 10"},
            body = "Here's something to keep you going.",
            choices = {
                {"Okay! [1000 fuel, back to ship]", "CurrentSave.player.fuel = 1000 | end"},
                {"Nah, I'm good.", "end"},
            }
        },
        test1 = {
            title = "A test encounter!",
            conditions = {"true == true"},
            body = "Some dummy ships are hanging around in space, shoot them down.",
            choices = {
                {"Okay! [start combat]", "scene combat"},
                {"Wait, what's that over there!", "goto test2"},
                {"Nah, I'm good [back to ship]", "end"}
            }
        },
        test2 = {
            -- The title shown of the current event
            title = "A second test encounter!",
            
            -- Conditions as strings, evaluated to decide if the event is elligable for the random selection, nil to never add, * to always be available, use a table of strings for multiple operations
            conditions = nil,
            
            -- Text shown for the body
            body = "Surprise, it's enemies.",
            
            -- Choices which the player can select
            -- Arg 1 is the text shown, arg 2 is the action
            -- Actions are special commands, with the following options
            -- scene <scene name>  =  transition to defined scene
            -- goto <event id>  =  switch to another event, can be used to have multiple layers or branches
            -- run <code>  =  execute arbitrary lua code
            -- end  =  go back to the ship scene, essentially sugar for `scene ship_main`
            choices = {
                {"Okay! [start combat]", "scene combat"},
                {"Nah, I'm good [back to ship]", "end"},
                {"Go to tutorial", "goto awakening"}
            }
        },
        awakening = {
            -- The title shown of the current event
            title = "Awakening",
            
            -- Conditions as strings, evaluated to decide if the event is elligable for the random selection, nil to never add, * to always be available, use a table of strings for multiple operations
            conditions = nil,
            
            -- Text shown for the body
            body = [[
            In the depths of a ship silently drifting in the abyss of deep space...
            One chamber is filled with a blue glow. 
            The endless silence is finally broken, the hiss of the chamber fills the room, the door swings open.
            Within is a human, frozen in statis, now awakening in to a foreign universe...
            ]],
            
            -- Choices which the player can select
            -- Arg 1 is the text shown, arg 2 is the action
            -- Actions are special commands, with the following options
            -- scene <scene name>  =  transition to defined scene
            -- goto <event id>  =  switch to another event, can be used to have multiple layers or branches
            -- run <code>  =  execute arbitrary lua code
            -- end  =  go back to the ship scene, essentially sugar for `scene ship_main`
            choices = {
                {"The computer speaks to me...", "goto awakening2"},
                {"Skip intro! [start encounter]", "scene field_scene"},
            }
        },
        awakening2 = {
            title = "Awakening",
            conditions = nil,
            body = [[
            "Greetings, Captain. You have been in statis for ERROR years. 
            You were awakened due to a malfunction on the ship which presented risk to your life.
            Before we begin the debriefing, do you remember your name?"
            ]],
            
            -- if get_input is present, choices are not shown, instead it will be a text box for getting user input
            -- the input text is then used for the $input value in the on_send paramater
            get_input = {default_text = function() return PlayerData().name end, run = "PlayerData().name = \"|input|\" | goto awakening3"}
        },
        awakening3 = {
            title = "Awakening",
            conditions = nil,
            body = [[
            "Checking |PlayerData().name|...
            Yes, that does appear to be correct.
            And just for verification purposes, what is the name of your ship?"
            ]],
            get_input = {default_text = function() return PlayerData().ship_name end, run = "PlayerData().ship_name = \"|input|\" | goto awakening4"}
        },
        awakening4 = {
            title = "Awakening",
            conditions = nil,
            body = [[
            "|PlayerData().ship_name|, correct...
            Now for the briefing. The ship has been drifting in space for ERROR years.
            We should return to Earth.
            First, you should awaken your crew.
            "
            ]],
            choices = {
                {"[Begin mission] (TODO)", "end | STORY.add_crew(CurrentSave.player.name)"}
            }
        },
    },
    
    -- Table that is merged in to the global scenes
    -- TODO split the logic of the combat/field scene in to a generic template that can be re-used
    scenes = {
        combat = {
            vars = {
                ReverseBG = false,
                Cooldown = 100,
                PlayedVictory = false,
                SpawnCooldown = 0,
                kills = 0
                --TODO victory condition, enemies spawn randomly if there is not many on screen, each one adds score, end when score > 5
            },
            keypress = function( key, scancode, isrepeat ) end,
            opening = function()
                PlayMusic("space")
                SV().Cooldown = 100
                SV().PlayedVictory = false
                
                -- Reset the entity ID counter
                LastID = 0
                
                -- Create the player
                Spawner.player(500, 200)
                

                local starts = math.random(1, 4)
                for i = 0, starts do
                    local ss = math.random(100, 500)
                    local su = math.random(0, 150)
                    local testEnemy = Spawner.basic_enemy(ss, su)
                    testEnemy.attack_delay = math.random(50, 90)
                end
                
                local r = math.random(1, 5)
                for i = 0, r do
                    local nex = math.random(0, G.getWidth())
                    local ney = math.random(0, G.getHeight())
                    local exp = Spawner.meteor1(nex, ney)
                end
                
                
            end,
            update = function(dt)
                if SV().SpawnCooldown > 0 then SV().SpawnCooldown = SV().SpawnCooldown - 1 end
                
                if #EntityList == 1 and Scenes.combat.vars.Cooldown >= 0 then
                    if SV().PlayedVictory == false then
                        Sfx("yay")
                        SV().PlayedVictory = true
                    end
                    SV().Cooldown = SV().Cooldown - 1
                    if SV().Cooldown == 0 then
                        Scene.set("ship_main")
                        return
                    end
                end
                
                
                if Scenes.combat.vars.ReverseBG then
                    BackgroundRGBA.R = BackgroundRGBA.R - 1
                    if BackgroundRGBA.R < 50 then SV().ReverseBG = false end
                    SetBG()
                else
                    BackgroundRGBA.R = BackgroundRGBA.R + 1
                    if BackgroundRGBA.R > 150 then SV().ReverseBG = true end
                    SetBG()
                end
                
                if KB.isDown("f1") then 
                    Scene.set("ship_main") 
                    return
                end 
                
                local p = Player()
                if p == nil then 
                    Scene.set("ship_main") 
                    return
                end
                for _, key in ipairs(GlobalSave.keys.fire_right) do
                    if KB.isDown(key) then
                        p:fire("right")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_left) do
                    if KB.isDown(key) then
                        p:fire("left")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_down) do
                    if KB.isDown(key) then
                        p:fire("down")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_up) do
                    if KB.isDown(key) then
                        p:fire("up")
                    end
                end
                
                
                for _, key in ipairs(GlobalSave.keys.move_right) do
                    if KB.isDown(key) then
                        p:start_move("x", p.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_left) do
                    if KB.isDown(key) then
                        p:start_move("x", -p.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_down) do
                    if KB.isDown(key) then
                        p:start_move("y", p.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_up) do
                    if KB.isDown(key) then
                        p:start_move("y", -p.move_speed)
                    end
                end

                for _, ent in ipairs(EntityList) do
                    if ent.ai ~= nil then ent:ai() end
                    ent:process_movement()
                    ent:tick()
                end
            end,
            draw = function()
                DrawHUD()

                for _, ent in ipairs(EntityList) do ent:draw() end
                
                if #EntityList == 1 then G.print("Encounter complete!", 300, 300) end
            end,
            closing = function()
                print("Cleaning up "..tostring(#EntityList).." entities.")
                while #EntityList > 0 do
                    for _, ent in ipairs(EntityList) do
                        ent:remove_from_world()
                    end
                end
                
                print("Entity cleanup complete. "..tostring(#EntityList))
            end
        },
        field_scene = { --TODO work on field system logic here
            vars = {
                CombatMode = false
            },
            keypress = function( key, scancode, isrepeat ) 
            
                local p = Player()
                --print(p.name)
                if table.contains(GlobalSave.keys.move_right, key) then
                    p:start_move("x", 1)
                end

                if table.contains(GlobalSave.keys.move_left, key) then
                    p:start_move("x", -1)
                end

                if table.contains(GlobalSave.keys.move_down, key) then
                    p:start_move("y", 1)
                end

                if table.contains(GlobalSave.keys.move_up, key) then
                    p:start_move("y", -1)
                end
            
            end,
            opening = function()
                PlayMusic("space")
                LastID = 0
                local p = Spawner.fieldcrew(5, 5, CurrentSave.crew[1])
                p.player = true
                
                Spawner.fieldcrew(10, 10, CurrentSave.crew[2])
                --p.player = true
            end,
            update = function(dt)
                

                for _, ent in ipairs(EntityList) do
                    if ent.ai ~= nil then ent:ai() end
                    ent:process_movement()
                end
            end,
            draw = function()
                --DrawHUD()
                DoFloatingText()

                for _, ent in ipairs(EntityList) do ent:draw() end
            end,
            closing = function()
                print("Cleaning up "..tostring(#EntityList).." entities.")
                while #EntityList > 0 do
                    for _, ent in ipairs(EntityList) do
                        ent:remove_from_world()
                    end
                end
                
                print("Entity cleanup complete. "..tostring(#EntityList))
            end
        }
    },
    
    -- Merged in to the global AI scripts
    ai_scripts = {
        meteor = function(me)
            -- Generate the boundaries of the screen based on current sprite size
            local x = me.x - me.sprite:getWidth()/2
            local y = me.y - me.sprite:getHeight()/2
            
            local ox = me.x + me.sprite:getWidth()/2
            local oy = me.y + me.sprite:getHeight()/2

            -- If the sprite is touching the walls, bounce it off
            -- TODO add a bit of random spin
            if x <= 0 or y <= 0 or ox >= G.getWidth() or oy >= G.getHeight() then 
                me.velocity_y = -me.velocity_y
            end
            
            if x <= 0 or ox >= G.getWidth() then 
                me.velocity_x = -me.velocity_x
            end
            
            -- Check for collisions
            me:execute(me.hit_damage)
        end,
        projectile = function(me)
            me:move_forward(me.move_speed)
            me:execute(me.hit_damage)
        end, 
        stationary_enemy = function(me)
            me:fire()
        end, 
        orb = function(me)
            if me:get_distance_entity("player") < 200 then
                me:shift_to_entity("player")
                me:execute(20)
            end
        end,
    },
    
    -- Merged in to the global AI scripts
    spawners = {
        -- Field Crew, for tile-based players
        fieldcrew = function(x, y, crew_member)
            local p = Entity:new(x * 32, y*32)
            print(crew_member.name)
            p.tile_based = true
            p.sprite = Sprites.crew
            p.health = crew_member.health
            p.energy = crew_member.energy
            p.name = crew_member.name
            p.sounds["hit"] = A.newSource("sounds/hit.mp3", "static")
            p.sounds["shoot"] = A.newSource("sounds/shoot.mp3", "static")
            --p.player = true
            p:add_to_world()
            
            return p
        end,
        meteor1 = function(x, y) 
            local spawned = Entity:new(x, y)
            spawned.alliance = -1
            spawned.health = 10
            spawned.decoration = true
            
            spawned.velocity_x = math.random(-1, 1)
            spawned.velocity_y = math.random(-1, 1)
            spawned.velocity_decay = 0
            spawned:attach("meteor")
            
            
            spawned.sprite = Sprites["meteor"..tostring(math.random(1, 5))]

            -- Add to the entity list
            spawned:add_to_world()
            
            return spawned
        end,
        projectile1 = function(x, y, owner, direction) 
            local spawned = Entity:new(x, y)
            
            -- Setting the projectile owner, to attribute damage done to the target to the entity who fired it
            spawned.owner = owner.id
            
            -- Setting direction, if none defined in parameters, then inherit the owner's'
            spawned.direction = direction or owner.direction
            
            -- Flag to say this is a projectile
            spawned.projectile = true
            
            -- Attaching the AI script to make this behave like a projectile
            spawned:attach("projectile")
            
            -- Setting the sprite
            spawned.sprite = Sprites.projectile1
            
            -- How fast this moves
            spawned.move_speed = 10
            
            -- Play sound effect on the projectiles owner, in this case it's the player'
            owner:sfx("shoot")
            
            -- Add to the entity list
            spawned:add_to_world()
            
            return spawned
        end,
    }
}
