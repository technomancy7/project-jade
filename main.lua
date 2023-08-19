---@diagnostic disable-next-line: unused-local
---@diagnostic disable: unused-local
---@diagnostic disable-next-line: trailing-space
---@diagnostic disable: trailing-space

local class = require 'middleclass'
local lib = require 'lib'
JSON = require "json"

-- Constants
GlobalFileName = "global.json"
Green = {0, 1, 0}
Red = {1, 0, 0}

-- Aliases
G = love.graphics
KB = love.keyboard
FS = love.filesystem
M = love.mouse
A = love.audio

-- Variables
SaveDir = nil
Player = nil
CurrentMusic = nil
StoredMusic = nil
Paused = false
ConsoleOpen = false

-- Containers
Music = {}
MusicNames = {}
Sounds = {}
Sprites = {}
Fonts = {}
EntityList = {}

DefaultSave = {
    player = {
        name = "Testing",
        fuel = 1000,
        supplies = 1000,
        health = 100,
        level = 1,
        exp = 0
    },
    world = {
        level = 1
    }
}

CurrentSave = {}

GlobalSave = {
    system = {
        savefile = 0,
        music = true
    },
    keys = {
        move_up = { "w", "up" },
        move_down = { "s", "down" },
        move_right = { "d", "right" },
        move_left = { "a", "left" },
        fire = { "l", "return", "x", "space" },
    }
}

Spawner = {
    player = function(x, y)
        Player = Entity:new(x, y)
        Player.id = "player"
        Player.class_type = "player"
        Player.sprite = Sprites.player
        Player.health = CurrentSave.player.health
        Player.sounds["hit"] = A.newSource("sounds/hit.mp3", "static")
        Player.sounds["shoot"] = A.newSource("sounds/shoot.mp3", "static")
        return Player
    end,
    basic_enemy = function(x, y) 
        local spawned = Entity:new(x, y)
        spawned.sprite = Sprites.enemy1
        spawned.alliance = 1
        spawned:attach("stationary_enemy")
        spawned.attack_delay = 90
        spawned.sounds["hit"] = A.newSource("sounds/hit.mp3", "static")
        spawned.sounds["shoot"] = A.newSource("sounds/shoot.mp3", "static")
        
        spawned.on_hit = function(me)
            if me.health <= 0 then
                local r = math.random(1, 5)
                
                for i = 0, r do
                    local nex = math.random(-50, 50)
                    local ney = math.random(-50, 50)
                    local exp = Entity:new(me.x + nex, me.y + ney)
                    exp.sprite = Sprites.pow
                    exp:attach("orb")
                    exp.class_type = "exp"
                    exp:add_to_world()
                end

            end
        end
        
        spawned:add_to_world()
        return spawned
    end

}

Scene = {
    name = "menu_main",
    
    get = function(name)
        if name == nil then name = Scene.name end
        return Scenes[name]
    end,
    
    set = function(name)
        if Scenes[Scene.name] ~= nil then Scenes[Scene.name].closing() end
        Scene.name = name
        if Scenes[name] ~= nil then Scenes[name].opening() end
    end,
}

Scenes = {
    menu_main = {
        vars = {
            SelectedSlot = GlobalSave.system.savefile,
            Slots = {}
        },
        keypress = function( key, scancode, isrepeat ) 
            if table.has_value(GlobalSave.keys.fire, key) then
                    GlobalSave.system.savefile = SV().SelectedSlot
                    if LoadSave() then
                        print("File exists")
                        Scene.set("ship_main")
                        Sfx("confirm")
                        return
                    else
                        print("File doesn't exist")
                        SaveFile(GetSaveFile(), DefaultSave)
                        SV().Slots[tostring(SV().SelectedSlot)] = DefaultSave
                        Sfx("confirm")
                        LoadSave()
                        --CurrentSave = DefaultSave.copy
                        return
                    end
                    return
            end
        end,
        opening = function() 
            PlayMusic("sky")
            if FS.getInfo(GetSaveFile(0)) ~= nil then
                print("File 0 exists")
                SV().Slots["0"] = LoadFile(GetSaveFile(0))
            else
                
            end
            if FS.getInfo(GetSaveFile(1)) ~= nil then
                print("File 1 exists")
                SV().Slots["1"] = LoadFile(GetSaveFile(1))
            end
            if FS.getInfo(GetSaveFile(2)) ~= nil then
                print("File 2 exists")
                SV().Slots["2"] = LoadFile(GetSaveFile(2))
            end
            if FS.getInfo(GetSaveFile(3)) ~= nil then
                print("File 3 exists")
                SV().Slots["3"] = LoadFile(GetSaveFile(3))
            end
        end,
        update = function(dt)
            --Scene.set("ship_main")
            if KB.isDown("up") and SV().SelectedSlot > 1 then
                SV().SelectedSlot = SV().SelectedSlot - 2
                Sfx("button")
            end
            if KB.isDown("down") and SV().SelectedSlot < 2 then
                SV().SelectedSlot = SV().SelectedSlot + 2
                Sfx("button")
            end
            if KB.isDown("left") and SV().SelectedSlot % 2 ~= 0 then
                SV().SelectedSlot = SV().SelectedSlot - 1
                Sfx("button")
            end
            if KB.isDown("right") and SV().SelectedSlot % 2 == 0 then
                SV().SelectedSlot = SV().SelectedSlot + 1
                Sfx("button")
            end
            -- fire key; saves selectedslot to globalsave system then call LoadSave
        end,
        draw = function()
            G.print(GetKey("fire").." to select save file", 0, 0)
            G.print("Music: "..tostring(GlobalSave.system.music), 400, 0)
            local x_off = 100
            local y_off = 100
            if SV().SelectedSlot == 0 then
                --love.graphics.setColor({0,0,0})
                G.rectangle("fill", 140,30, 260,260)
                if SV().Slots["0"] == nil then G.print({Red, "No data"}, 140 + x_off,30 + y_off) else G.print({Green, SV().Slots["0"].player.name}, 140 + x_off,30 + y_off) end
            else
                G.rectangle("line", 140,30, 260,260)
                if SV().Slots["0"] == nil then G.print({Red, "No data"}, 140 + x_off,30 + y_off) else G.print({Green, SV().Slots["0"].player.name}, 140 + x_off,30 + y_off) end
            end
            
            if SV().SelectedSlot == 1 then
                G.rectangle("fill", 420,30, 260,260)
                if SV().Slots["1"] == nil then G.print({Red, "No data"}, 420 + x_off,30 + y_off) else G.print({Green, SV().Slots["1"].player.name}, 420 + x_off,30 + y_off) end
            else
                G.rectangle("line", 420,30, 260,260)
                if SV().Slots["1"] == nil then G.print({Red, "No data"}, 420 + x_off,30 + y_off) else G.print({Green, SV().Slots["1"].player.name}, 420 + x_off,30 + y_off) end
            end
            
            if SV().SelectedSlot == 2 then
                G.rectangle("fill", 140,310, 260,260)
                if SV().Slots["2"] == nil then G.print({Red, "No data"}, 140 + x_off,310 + y_off) else G.print({Green, SV().Slots["2"].player.name}, 140 + x_off,310 + y_off) end
            else
                G.rectangle("line", 140,310, 260,260)
                if SV().Slots["2"] == nil then G.print({Red, "No data"}, 140 + x_off,310 + y_off) else G.print({Green, SV().Slots["2"].player.name}, 140 + x_off,310 + y_off) end
            end
            
            if SV().SelectedSlot == 3 then
                G.rectangle("fill", 420,310, 260,260)
                if SV().Slots["3"] == nil then G.print({Red, "No data"}, 420 + x_off,310 + y_off) else G.print({Green, SV().Slots["3"].player.name}, 420 + x_off,310 + y_off) end
            else
        
                G.rectangle("line", 420,310, 260,260)
                if SV().Slots["3"] == nil then G.print({Red, "No data"}, 420 + x_off,310 + y_off) else G.print({Green, SV().Slots["3"].player.name}, 420 + x_off,310 + y_off) end
            end
        end,
        closing = function() end
    },
    ship_main = {
        vars = {
            -- Cooldown for activator that enables heading to event
            cooldown = 0
        },
        keypress = function( key, scancode, isrepeat ) end,
        opening = function() 
            PlayMusic("code")
            SV().cooldown = 50
            UpdateBG(0, 0, 0, 0)
            --SetBG()
        end,
        update = function(dt)
            for _, key in ipairs(GlobalSave.keys.fire) do
                if KB.isDown(key) and SV().cooldown == 0 then
                    Scene.set("combat")
                    Sfx("start")
                    return
                end
            end
            if KB.isDown("f12") then 
                Scene.set("menu_main") 
                return
            end
            if SV().cooldown > 0 then SV().cooldown = SV().cooldown - 1 end
        end,
        draw = function() 
            DrawHUD()
            
            if Scenes.ship_main.vars.cooldown == 0 then
                G.print(" | Press "..GetKey("fire").." to start.", 400, 0)
            else
                G.print(" | "..tostring(Scenes.ship_main.vars.cooldown), 400, 0)
            end
        end,
        closing = function() end
    },
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
            LastID = 0
            -- Create the player
            Spawner.player(500, 200)

            -- Testing TODO remove later
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
            
            for _, key in ipairs(GlobalSave.keys.fire) do
                if KB.isDown(key) then
                    Player:fire()
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
}

AIScripts = {
    projectile_player = function(me)
        me:move_up(10)
        me:execute(20)
    end,
    projectile = function(me)
        me:move_down(2)
        me:execute(20)
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
}

BackgroundRGBA = {
    R = 0,
    G = 0,
    B = 0,
    A = 0
}

FloatingTexts = {}

-- BEGIN ENTITY
Entity = class('Entity')
LastID = 0

function Entity:initialize(x, y)
    -- Defining location on the screen
    self.x = x or 0
    self.y = y or 0

    -- How fast the sprite moves
    self.move_speed = 5

    -- How rapidly the velocity decays after initial movement
    self.velocity_decay = 1

    -- Current movement value
    self.velocity_x = 0
    self.velocity_y = 0

    -- Sprite info
    self.sprite = nil
    self.size = 2
    self.rotation = 0
    self.hidden = false
    
    -- Either index of entity, or special value, such as "player"
    self.id = nil

    -- Misc identifier for arbitrary checks
    self.class_type = nil
    
    -- Generic switch for wether this is a projectile, for quick excemptions from routines that should only effect living entities
    self.projectile = false
    
    -- Check for if attacks should land/aggro with eachother
    self.alliance = 0

    -- AI script function, ran each tick
    self.ai = nil
    
    -- Current health, destroyed when reaches 0
    self.health = 100

    -- Is this entity owned by another entity, such as in the case of a projectile, to register who the shooter was
    self.owner = nil

    -- Can only fire when this value is 0, decays by 1 each tick
    self.attack_cooldown = 0

    -- The value the cooldown is set to after each attack
    self.attack_delay = 10
    
    -- Table of sound effect instances for this object
    self.sounds = {}
    
    -- Events
    self.on_enter_world = nil
    self.on_leave_world = nil
    self.on_hit = nil
end

function Entity:draw()
    if self.sprite == nil then return end
    if self.hidden == true then return end
    
    G.draw(self.sprite, self.x, self.y, self.rotation, self.size, self.size, self.sprite:getWidth() / 2, self.sprite:getHeight() / 2)
    
    --G.rectangle("fill", self.x - (self.sprite:getWidth() / 2), self.y - (self.sprite:getHeight() / 2), 1,1)
end

function Entity:sfx(name)
    local src = self.sounds[name]
    
    if src:isPlaying() then
        src:stop()
    end
    
    src:play()
end
-------------------------------------
-- Clean up the entity if it goes out of bounds.
-------------------------------------
function Entity:cleanup_out_of_bounds()
    if self.y < 0 then self:remove_from_world() end
    if self.y > (G.getHeight() - self.sprite:getHeight()) then self:remove_from_world() end
    if self.x < 0 then self:remove_from_world() end
    if self.x > (G.getWidth() - self.sprite:getWidth()) then self:remove_from_world() end
end

-------------------------------------
-- Callback that is run every tick.
-------------------------------------
function Entity:tick()
    if self.attack_cooldown > 0 then self.attack_cooldown = self.attack_cooldown - 1 end
    self:cleanup_out_of_bounds()
end

-------------------------------------
-- Move the entity in the specified direction.
-- @param s Distance to move.
-------------------------------------
function Entity:move_up(s)
    self.y = self.y - s
end

function Entity:move_down(s)
    self.y = self.y + s
end

function Entity:move_left(s)
    self.x = self.x - s
end

function Entity:move_right(s)
    self.x = self.x + s
end

-------------------------------------
-- Checks if objects are in range and executes its action based on what it is
-- @param power Damage to hit for.
-------------------------------------
function Entity:execute(power, single_use)
    if power == nil then power = 10 end
    if single_use == nil then single_use = true end
    
    if self.class_type == "enemy_projectile" then
        local ox = Player.sprite:getWidth()/2 
        local oy = Player.sprite:getHeight()/2 
        if self.x < Player.x + ox and self.x > Player.x - ox and self.y < Player.y + oy and self.y > Player.y - oy then
            AddFloatingText({ x = Player.x, y = Player.y, text = power, float = true })
            Player:take_damage(power)
            if single_use == true then self:remove_from_world() end
        end
    elseif self.class_type == "projectile" then
        for _, ent in ipairs(EntityList) do
            if self.owner == ent.tag then return end
            if self.class_type == ent.class_type then return end
            if self.alliance == ent.alliance then return end 
            if ent.projectile then return end
            local ox = ent.sprite:getWidth()/2 
            local oy = ent.sprite:getHeight()/2 
            if self.x < ent.x + ox and self.x >= ent.x - ox and self.y < ent.y + oy and self.y >= ent.y - oy then
                AddFloatingText({ x = ent.x, y = ent.y, text = power, float = true })
                ent:take_damage(power)
                if single_use == true then self:remove_from_world() end
            end
        end
    elseif self.class_type == "exp" then
        if self:get_distance_entity("player") <= 5 then
            CurrentSave.player.exp = CurrentSave.player.exp + power
            if single_use == true then self:remove_from_world() end
        end
    end
end

function Entity:take_damage(dam)
    self:sfx("hit")
    self.health = self.health - dam
    if self.id == "player" then CurrentSave.player.health = self.health end
    
    if self.health <= 0 then 
        if self.id == "player" then
            self.health = 100 --TODO handle some death state
        else
            self:died() 
        end
    end
    
    local has_died = self.health <= 0
    
    if self.on_hit ~= nil then
        self:on_hit()
    end
end

function Entity:died()
    self:remove_from_world()
end

function Entity:add_to_world()
    table.insert(EntityList, self)
    self.id = LastID
    LastID = LastID + 1
    --print("Added to world as " .. tostring(self.id))
    
    if self.on_enter_world ~= nil then
        self:on_enter_world()
    end
end

function Entity:remove_from_world()
    if self.on_leave_world ~= nil then
        self:on_leave_world()
    end
    
    -- Cleanup sound effect instances
    for _, sfx in ipairs(self.sounds) do
        sfx:release()
    end
    
    -- Remove from entity list
    --table.remove(EntityList, self.id)
    
    for index, ent in ipairs(EntityList) do
        
        --print("Shifting " .. tostring(ent.id) .. " to " .. tostring(id))
        --ent.id = id
        if ent.id == self.id then
            table.remove(EntityList, index)
            break
        end
    end
    
    -- Release self
    self = nil
end

-- Attach an AI script to this entity
function Entity:attach(ai)
    self.ai = AIScripts[ai]
end

function Entity:fire()
    if self.attack_cooldown > 0 then
        return
    end
    
    if self.class_type == "player" then
        local proj = Entity:new()

        -- Defined as a projectile, owned by the player
        proj.owner = "player"
        proj.class_type = "projectile"
        proj.projectile = true

        proj.sprite = Sprites.projectile1
        proj:move_to_entity("player")

        -- Handle sprite offset
        --proj.x = proj.x + 16
        --proj.y = proj.y + 10

        -- Attach AI script
        proj:attach("projectile_player")

        proj:add_to_world()

        -- Delay the players next shot
        self.attack_cooldown = self.attack_delay
        
        -- Play sound effect
        self:sfx("shoot")
    else
        local proj = Entity:new()

        -- Defined as a projectile, owned by the enemy
        proj.owner = self.id
        proj.class_type = "enemy_projectile"
        proj.alliance = 1
        proj.projectile = true
        
        proj.sprite = Sprites.projectile2
        proj:move_to_entity(self.id)

        -- Handle sprite offset
        --proj.x = proj.x + 16
        --proj.y = proj.y + 10

        -- Attach AI script
        proj:attach("projectile")

        proj:add_to_world()

        -- Delay the entities next shot
        self.attack_cooldown = self.attack_delay
    end
end

function Entity:get_distance_entity(id)
    local target = GetEntity(id)
    if target ~= nil then
        return self:get_distance(target.x, target.y)
    end
end

function Entity:get_distance(x, y)
  return math.sqrt((self.x - x)^2 + (self.y - y)^2)
end

function Entity:move_to_entity(id)
    local target = GetEntity(id)

    if target ~= nil then
        self:move_to(target.x, target.y)
    end
end

function Entity:move_to(x, y)
    self.x = x
    self.y = y
end

function Entity:shift_to_entity(id)
    local target = GetEntity(id)

    if target ~= nil then
        self:shift_to(target.x, target.y)
    end
end

function Entity:shift_to(x, y)
    if self.x < x then self.x = self.x + self.move_speed end
    if self.x > x then self.x = self.x - self.move_speed end
    if self.y < y then self.y = self.y + self.move_speed end
    if self.y > y then self.y = self.y - self.move_speed end
end

function Entity:start_move(dir, amt)
    if dir == "x" or dir == "y" then
        self["velocity_" .. dir] = amt
    end
end

function Entity:start_move_up(amt)
    self:start_move("y", -amt)
end

function Entity:start_move_down(amt)
    self:start_move("y", amt)
end

function Entity:start_move_left(amt)
    self:start_move("x", -amt)
end

function Entity:start_move_right(amt)
    self:start_move("x", amt)
end

function Entity:process_movement()
    if self.velocity_x > 0 then
        self.velocity_x = self.velocity_x - self.velocity_decay
        if self.x < (G.getWidth() - (self.sprite:getWidth() / 2)) then
            self.x = self.x + self.velocity_x
        end
    end

    if self.velocity_y > 0 then
        self.velocity_y = self.velocity_y - self.velocity_decay
        if self.y <  (G.getHeight() - (self.sprite:getHeight() / 2)) then
            self.y = self.y + self.velocity_y
        end
    end

    if self.velocity_x < 0 then
        self.velocity_x = self.velocity_x + self.velocity_decay
        if self.x > (self.sprite:getWidth() / 2) then
            self.x = self.x - -self.velocity_x
        end
    end

    if self.velocity_y < 0 then
        self.velocity_y = self.velocity_y + self.velocity_decay
        if self.y > (self.sprite:getHeight() / 2) then
            self.y = self.y - -self.velocity_y
        end
    end
end

-- END ENTITY


-- Functions
function DisableMusic()
    PlayMusic(nil)
    GlobalSave.system.music = false
    SaveFile(GlobalFileName, GlobalSave)
end

function EnableMusic()
    GlobalSave.system.music = true
    SaveFile(GlobalFileName, GlobalSave)
    PlayMusic(StoredMusic)
end

function GetEntity(id)
    if id == "player" then return Player end

    for _, ent in ipairs(EntityList) do
        if ent.id == id then return ent end
    end
end

function AddFloatingText(data)
    if data.lifespan == nil then data.lifespan = 100 end
    table.insert(FloatingTexts,
        { x = data.x, y = data.y, text = tostring(data.text), lifespan = data.lifespan, i = 0, speed = data.speed,
            direction = 0, float = data.float })
end

function SV()
    return Scenes[Scene.name].vars
end

function PlayMusic(name)
    if name == nil and CurrentMusic ~= nil and CurrentMusic:isPlaying() then
        CurrentMusic:stop()
        CurrentMusic = nil
        return
    end
    StoredMusic = name
    if GlobalSave.system.music == false then return end
    
    local src = Music[name]
    
    if CurrentMusic ~= nil then
        if CurrentMusic:isPlaying() then
            CurrentMusic:stop()
        end
    end
    
    if src:isPlaying() then
        src:stop()
    end
    
    CurrentMusic = src
    src:play()
end

function Sfx(name)
    local src = Sounds[name]
    
    if src:isPlaying() then
        src:stop()
    end
    src:play()
end


function UpdateBG(r, g, b, a)
    BackgroundRGBA.R = r
    BackgroundRGBA.G = g
    BackgroundRGBA.B = b
    BackgroundRGBA.A = a
    G.setBackgroundColor(r, g, b, a)
end

function SetBG()
    local red = BackgroundRGBA.R / 255
    local green = BackgroundRGBA.G / 255
    local blue = BackgroundRGBA.B / 255
    local alpha = BackgroundRGBA.A / 100
    G.setBackgroundColor(red, green, blue, alpha)
end

function SaveFile(name, data)
    FS.write(name, JSON.encode(data))
end

function LoadFile(name)
    local data = FS.read(name)
    return JSON.decode(data)
end

function WriteSave()
    SaveFile(GetSaveFile(), CurrentSave)
end

function LoadSave()
    if FS.getInfo(GetSaveFile()) == nil then
        return false

    else
        print("Loading " .. GetSaveFile())
        CurrentSave = LoadFile(GetSaveFile())
        return true
    end
end

function GetSaveFile(i)
    if i == nil then i = GlobalSave.system.savefile end
    return "save" .. tostring(i) .. ".json"
end

function DoFloatingText()
    for id, t in ipairs(FloatingTexts) do
        if t.speed == nil then t.speed = 1 end
        if t.lifespan == nil then t.lifespan = 100 end

        if t.float then
            if t.direction == 0 then
                t.x = t.x + 0.5
            else
                t.x = t.x - 0.5
            end

            if t.i % 25 == 0 then
                if t.direction == 0 then t.direction = 1 else t.direction = 0 end
            end
        end
        t.y = t.y - t.speed
        t.i = t.i + 1

        G.print(t.text, t.x, t.y)

        if t.i >= t.lifespan then table.remove(FloatingTexts, id) end
    end
end

function GetKey(action)
    if GlobalSave.keys[action] == nil then return "undefined" end
    return " [ "..table.concat(GlobalSave.keys[action], " | ").." ] "
end

function DrawHUD()
    G.print("User: " .. CurrentSave.player.name .. "   //   Supplies: " .. tostring(CurrentSave.player.supplies) .. "   //   Fuel:  " ..tostring(CurrentSave.player.fuel), 0, 0)
    local x = CurrentSave.player.health
    local pointer = tonumber(10 * (x / 100.0))
    local gauge = 
        "|"
        .. "-" * pointer
        .. " " * (10 - pointer)
        .. "|\n "
        .. tostring(x)
        .. "% "

    --G.print("Health: "..tostring(Player.health), 0, 10)
    G.print(gauge, 0, 15)
    
    G.print("EXP: "..tostring(CurrentSave.player.exp), 0, 50)
end

-- Callbacks

function love.load()
    -- Defining state
    --UpdateBG(100, 0, 0, 0)
    SaveDir = FS.getSaveDirectory()

    -- Loading assets
    Fonts.main = G.newFont("FiraCodeNerdFont-Bold.ttf")
    G.setFont(Fonts.main)

    Music.space = A.newSource("music/Andy G. Cohen - Space.mp3", "stream")
    Music.space:setVolume(0.4)
    MusicNames["space"] = "Andy G. Cohen - Space"
    
    Music.clouds = A.newSource("music/Beat Mekanik - Making Clouds.mp3", "stream")
    Music.clouds:setVolume(0.4)
    MusicNames["clouds"] = "Beat Mekanik - Making Clouds"
    
    Music.sky = A.newSource("music/Infinite_Sky.mp3", "stream")
    Music.sky:setVolume(0.4)
    MusicNames["sky"] = "TeknoAxe - Infinite Sky"
    
    Music.code = A.newSource("music/Mystery Mammal - Code Composer.mp3", "stream")
    Music.code:setVolume(0.4)
    MusicNames["code"] = "Mystery Mammal - Code Composer"
    
    Sounds.button = A.newSource("sounds/button.mp3", "static")
    Sounds.confirm = A.newSource("sounds/confirm.mp3", "static")
    Sounds.start = A.newSource("sounds/start.mp3", "static")
    Sounds.yay = A.newSource("sounds/yay.mp3", "static")
    
    Sprites.player = G.newImage('sprites/player.png')
    Sprites.enemy1 = G.newImage('sprites/enemy.png')
    Sprites.projectile1 = G.newImage('sprites/shot.png')
    Sprites.projectile2 = G.newImage('sprites/enemy_shot.png')
    Sprites.pow = G.newImage('sprites/pow.png')
    
    -- Setting up save files
    if FS.getInfo(GlobalFileName) == nil then
        print("Creating global config")
        SaveFile(GlobalFileName, GlobalSave)
    else
        print("Loading default globals")
        GlobalSave = LoadFile(GlobalFileName)
    end

    Scene.set("menu_main")
end

function OpenConsole()
    --ConsoleInput = ""
    ConsoleOpen = true
    Paused = true
end

function CloseConsole()
    --ConsoleInput = ""
    ConsoleOpen = false
    Paused = false
end

function love.keypressed( key, scancode, isrepeat )
    -- Global system binds

    if key == "f11" then 
        if GlobalSave.system.music == true then DisableMusic() else EnableMusic() end
        return
    end
    
    if key == "f10" or key == "pause" then
        Paused = not Paused
        return
    end
    
    if key == "`" then
        if ConsoleOpen then CloseConsole() else OpenConsole() end
        return
    end
    
    if key == "backspace" and ConsoleOpen then
        --print("Deleting")
        ConsoleInput = string.sub(ConsoleInput, 1, -2)
        return
    end
    
    if key == "return" and ConsoleOpen then
        HandleConsole()
        return
    end
    
    if key == "pageup" and ConsoleOpen then
    if ConsoleLogStart >= #ConsoleMsgs then return end 
        ConsoleLogStart = ConsoleLogStart + 1
    end
    
    if key == "pagedown" and ConsoleOpen then
        if ConsoleLogStart <= 1 then return end 
        ConsoleLogStart = ConsoleLogStart - 1
    end
    
    if key == "down" and ConsoleOpen then
        if ConsoleLogPointer <= 1 then 
            ConsoleInput = ""
            return
        end
        ConsoleLogPointer = ConsoleLogPointer - 1
        ConsoleInput = ConsoleLog[ConsoleLogPointer]
        return
    end
    
    if key == "up" and ConsoleOpen then
        if ConsoleLogPointer >= #ConsoleLog then return end
        ConsoleLogPointer = ConsoleLogPointer + 1
        ConsoleInput = ConsoleLog[ConsoleLogPointer]
        return
    end
    
    if not ConsoleOpen then
        Scene.get().keypress(key, scancode, isrepeat)
    end
end

function love.update(dt)
    if not Paused then
        Scene.get().update(dt)
    end
end

ShowMusic = true
ConsoleInput = ""
ConsoleLogPointer = 0
ConsoleLog = {}
ConsoleMsgs = {}

function AddLog(t)
    table.insert(ConsoleMsgs, 1, tostring(t))
end

function HandleConsole()
    if ConsoleInput == "" then return end
    table.insert(ConsoleLog, 1, ConsoleInput)
    table.insert(ConsoleMsgs, 1, "$ "..ConsoleInput)
    local cmd = ""
    local val = ""
    
    -- If there is spaces in the string, split the input so word 1 is the command and the rest is the parameters
    if select(2, string.gsub(ConsoleInput, " ", "")) >= 1 then
        cmd, val = string.match(ConsoleInput, "(%S+)%s(.*)")
    else
        cmd = ConsoleInput
    end
    

    if cmd == "run" then
        local success, result = pcall(function()
            local chunk = load(val)
            if chunk ~= nil then
                chunk()
            end
        end)
        print(success, result)
        if result ~= nil then
            if success then
            -- Code executed successfully
                AddLog("Result:" .. result)
            else
            -- Error occurred
                AddLog("Error:" .. result)
            end
        end
    end
    
    ConsoleInput = ""
end

function love.textinput(t)
    if ConsoleOpen and t ~= "`" then
        ConsoleInput = ConsoleInput .. t
    end
end
ConsoleLogStart = 1
function love.draw()
    ---print(G.getColor())
    --love.graphics.clear()
    --if not ConsoleOpen then
    Scene.get().draw()
    --end
    
    if ShowMusic and GlobalSave.system.music then
        local name = MusicNames[StoredMusic]
        if name ~= nil then
            local msg = "Now Playing: "..name
            local w = Fonts.main:getWidth(msg)
            local h = 0
            if ConsoleOpen then h = h - 20 end
            
            G.print(msg, G.getWidth() - w - 20, G.getHeight() - 15 + h)
        end
    end
    
    if ConsoleOpen then
        
        local ci = "> "..ConsoleInput
        love.graphics.setColor({0,0,0, 1})
        love.graphics.rectangle("fill", 0, G.getHeight()-15, Fonts.main:getWidth(ci), Fonts.main:getHeight())
        love.graphics.setColor({1, 1, 1, 1})
        G.print(ci, 0, G.getHeight()-15)
        
        local range = {}
        local endpoint = ConsoleLogStart + 20
        table.move(ConsoleLog, ConsoleLogStart, endpoint - 1, 1, range)

        local i = 25
        for ln, log in ipairs(range) do
            local text = ConsoleLogStart - 1 + ln.." " .. log
            love.graphics.setColor({0, 0, 0, 1})
            love.graphics.rectangle("fill", 0, G.getHeight()-15-i, Fonts.main:getWidth(text), Fonts.main:getHeight())
            love.graphics.setColor({1, 1, 1, 1})
            G.print(text, 0, G.getHeight()-15-i)
            i = i + 20
            if ln >= endpoint then break end
        end
        --
    end
end

function love.quit()
    --TODO handle saving state on exit
    return false
end
