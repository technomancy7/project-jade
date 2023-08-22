# spiffing
A work-in-progress roguelike space adventure themed after the old British TV show, Red Dwarf, with some FTL elements.

## Running
Requires Love2d runtime.

## Modding
Modding is supported right from the core.

This is an example mod file, it can be dropped in to the source directory /scripts/ folder, or the save directory /mods/ folder. The modding framework is the same way I'll be writing the core eventing systems, so anything I can do in the base, mods can also do, and since it's pure Lua all the way down, mods can do pretty much anything they want, giving full flexibility.

```lua
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

                local testEnemy2 = Spawner.basic_enemy(200, 200)
                testEnemy2.attack_delay = 50

                local testEnemy3 = Spawner.basic_enemy(300, 300)
                testEnemy3.attack_delay = 30
            
            end,
            update = function(dt)
                if #EntityList == 0 and Scenes.combat.vars.Cooldown >= 0 then
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

                Player:tick()
                
                if KB.isDown("f1") then 
                    Scene.set("ship_main") 
                    return
                end 

                for _, key in ipairs(GlobalSave.keys.fire_right) do
                    if KB.isDown(key) then
                        Player:fire("right")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_left) do
                    if KB.isDown(key) then
                        Player:fire("left")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_down) do
                    if KB.isDown(key) then
                        Player:fire("down")
                    end
                end

                for _, key in ipairs(GlobalSave.keys.fire_up) do
                    if KB.isDown(key) then
                        Player:fire("up")
                    end
                end
                
                
                for _, key in ipairs(GlobalSave.keys.move_right) do
                    if KB.isDown(key) then
                        Player:start_move("x", Player.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_left) do
                    if KB.isDown(key) then
                        Player:start_move("x", -Player.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_down) do
                    if KB.isDown(key) then
                        Player:start_move("y", Player.move_speed)
                    end
                end

                for _, key in ipairs(GlobalSave.keys.move_up) do
                    if KB.isDown(key) then
                        Player:start_move("y", -Player.move_speed)
                    end
                end

                Player:process_movement()

                for _, ent in ipairs(EntityList) do
                    if ent.ai ~= nil then ent:ai() end
                    ent:process_movement()
                    ent:tick()
                end
            end,
            draw = function()
                DrawHUD()
                DoFloatingText()

                Player:draw()

                for _, ent in ipairs(EntityList) do
                    ent:draw()

                end
                
                if #EntityList == 0 then
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
                Player = nil
            end
        },
    },
    
    -- Merged in to the global AI scripts
    ai_scripts = {}
}
```
