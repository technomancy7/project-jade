
return {
    -- Name of our script
    name = "testcombat",
    
    -- Author name
    author = "Techno",
    
    -- Container that gets filled with the main runtime global functions
    globals = {},
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Test extension loaded.")
    end,
    
    events = {
        testalt = {
            title = "A test encounter?",
            conditions = {"true == true", "1 == 1"},
            body = "There's nothing here!?",
            choices = {
                {"Okay! [back to ship]", "end"},
                {"Wait, what's that over there!", "goto test2"},
            }
        },
        test1 = {
            title = "A test encounter!",
            conditions = {"true == true", "1 == 1"},
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
                {"Nah, I'm good [back to ship]", "end"}
            }
        },
    },
    -- Table that is merged in to the global scens
    scenes = {
        combat = {
            vars = {
                ReverseBG = false,
                Cooldown = 100,
                PlayedVictory = false
            },
            keypress = function( key, scancode, isrepeat ) end,
            opening = function()
                PlayMusic("space")
                Scenes.combat.vars.Cooldown = 100
                Scenes.combat.vars.PlayedVictory = false
                
                -- Reset the entity ID counter
                LastID = 0
                
                -- Create the player
                Spawner.player(500, 200)

                -- Spawn the three testing enemies
                local testEnemy = Spawner.basic_enemy(100, 100)
                testEnemy.attack_delay = 90
                testEnemy.projectile_spawner = Spawner.projectile1_enemy

                local testEnemy2 = Spawner.basic_enemy(200, 200)
                testEnemy2.attack_delay = 50
                testEnemy2.projectile_spawner = Spawner.projectile1_enemy
                
                local testEnemy3 = Spawner.basic_enemy(500, 50)
                testEnemy3.attack_delay = 40
                testEnemy3.projectile_spawner = Spawner.projectile1_enemy

                local r = math.random(1, 5)
                for i = 0, r do
                    local nex = math.random(0, G.getWidth())
                    local ney = math.random(0, G.getHeight())
                    local exp = Spawner.meteor1(nex, ney)
                end
                
                
            end,
            update = function(dt)
                if #EntityList == 1 and Scenes.combat.vars.Cooldown >= 0 then
                    if SV().PlayedVictory == false then
                        Sfx("yay")
                        SV().PlayedVictory = true
                    end
                    Scenes.combat.vars.Cooldown = Scenes.combat.vars.Cooldown - 1
                    if Scenes.combat.vars.Cooldown == 0 then
                        Scene.set("ship_main")
                        return
                    end
                end
                
                
                if Scenes.combat.vars.ReverseBG then
                    BackgroundRGBA.R = BackgroundRGBA.R - 1
                    if BackgroundRGBA.R < 50 then Scenes.combat.vars.ReverseBG = false end
                    SetBG()
                else
                    BackgroundRGBA.R = BackgroundRGBA.R + 1
                    if BackgroundRGBA.R > 150 then Scenes.combat.vars.ReverseBG = true end
                    SetBG()
                end
                
                if KB.isDown("f1") then 
                    Scene.set("ship_main") 
                    return
                end 
                local p = Player()
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
                DoFloatingText()

                for _, ent in ipairs(EntityList) do
                    ent:draw()

                end
                
                if #EntityList == 1 then
                    G.print("Encounter complete!", 300, 300)
                end
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
    },
    
    -- Merged in to the global AI scripts
    ai_scripts = {}
}
