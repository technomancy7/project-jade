---@diagnostic disable-next-line: unused-local
---@diagnostic disable: unused-local
---@diagnostic disable-next-line: trailing-space
---@diagnostic disable: trailing-space

local class = require 'middleclass'
local techno = require 'techno'
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
CurrentMusic = nil
StoredMusic = nil
Paused = false
ConsoleOpen = false
DebugMode = false
GameSpeed = 1

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
        move_up = { "w" },
        move_down = { "s"},
        move_right = { "d" },
        move_left = { "a"},
        confirm = { "return", "space" },
        fire_up = { "up" },
        fire_down = { "down" },
        fire_right = { "right" },
        fire_left = { "left" },
        special1 = { "z", "1" },
        special2 = { "x", "2" },
        special3 = { "c", "3" },
        special4 = { "v", "4" },
        special5 = { "b", "5" },
        special6 = { "n", "6" },
        special7 = { "m", "7" },
    }
}

function Player()
    for _, ent in ipairs(EntityList) do if ent.player then return ent end end
end

Spawner = {
    player = function(x, y)
        local p = Entity:new(x, y)
        p.sprite = Sprites.player
        p.health = CurrentSave.player.health
        p.sounds["hit"] = A.newSource("sounds/hit.mp3", "static")
        p.sounds["shoot"] = A.newSource("sounds/shoot.mp3", "static")
        p:add_to_world()
        p.player = true
        return p
    end,
    basic_enemy = function(x, y) 
        local spawned = Entity:new(x, y)
        spawned.sprite = Sprites.enemy1
        spawned.alliance = 1
        spawned.direction = "down"
        spawned:attach("stationary_enemy")
        spawned.attack_delay = 90
        spawned.projectile_spawner = Spawner.projectile1_enemy
        spawned.sounds["hit"] = A.newSource("sounds/hit.mp3", "static")
        spawned.sounds["shoot"] = A.newSource("sounds/shoot.mp3", "static")
        
        spawned.on_hit = function(me, instigator)
            if me.health <= 0 then
                local r = math.random(1, 5)
                
                for i = 0, r do
                    local nex = math.random(-50, 50)
                    local ney = math.random(-50, 50)
                    local exp = Entity:new(me.x + nex, me.y + ney)
                    exp.pickup = true
                    exp.sprite = Sprites.pow
                    exp:attach("orb")
                    exp:add_to_world()
                end

            end
        end
        
        spawned:add_to_world()
        return spawned
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
        
        -- Play sound effect only for player shots
        owner:sfx("shoot")
        
        -- Add to the entity list
        spawned:add_to_world()
        
        return spawned
    end,
    projectile1_enemy = function(x, y, owner, direction) 
        local spawned = Entity:new(x, y)
        spawned.owner = owner.id
        spawned.direction = direction or owner.direction
        spawned.projectile = true
        spawned:attach("projectile")
        spawned.alliance = 1
        spawned.sprite = Sprites.projectile2
        spawned.move_speed = 2

        spawned:add_to_world()
        return spawned
    end
}

Events = {}

Scene = {
    name = "menu_main",
    
    get = function(name)
        if name == nil then name = Scene.name end
        return Scenes[name]
    end,
    
    set = function(name, skip_opening_event)
        if Scenes[Scene.name] ~= nil then Scenes[Scene.name].closing() end
        Scene.name = name
        if Scenes[name] ~= nil and skip_opening_event ~= true then Scenes[name].opening() end
    end,
}

function ActivateEvent(evt_id)
    if table.has_key(Events, evt_id) then
        Scene.set("event_container", true)
        SV().EvtId = evt_id
        SV().EvtData = Events[evt_id]
        Scenes["event_container"].opening()
    end
end

Scenes = {
    menu_main = {
        vars = {
            SelectedSlot = GlobalSave.system.savefile,
            Slots = {}
        },
        keypress = function( key, scancode, isrepeat ) 
            if table.has_value(GlobalSave.keys.confirm, key) then
                    GlobalSave.system.savefile = SV().SelectedSlot
                    if LoadSave() then
                        Scene.set("ship_main")
                        Sfx("confirm")
                        return
                    else
                        SaveFile(GetSaveFile(), DefaultSave)
                        SV().Slots[tostring(SV().SelectedSlot)] = DefaultSave
                        Sfx("confirm")
                        LoadSave()
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
            if BackgroundRGBA.R > 0 then BackgroundRGBA.R = BackgroundRGBA.R - 1 end
            if BackgroundRGBA.G > 0 then BackgroundRGBA.G = BackgroundRGBA.G - 1 end
            if BackgroundRGBA.B > 0 then BackgroundRGBA.B = BackgroundRGBA.B - 1 end
            SetBG()
            
            G.print(GetKey("confirm").." to select save file", 0, 0)
            G.print("Music: "..tostring(GlobalSave.system.music), 400, 0)
            local x_off = 0
            local y_off = 40
            
            if SV().SelectedSlot == 0 then
                local s = SV().Slots["0"]
                G.rectangle("fill", 140,30, 260,260)
                if s == nil then G.print({Red, "No data"}, 140 + x_off,30 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 140 + x_off,30 + y_off) end
            else
            local s = SV().Slots["0"]
                G.rectangle("line", 140,30, 260,260)
                if SV().Slots["0"] == nil then G.print({Red, "No data"}, 140 + x_off,30 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 140 + x_off,30 + y_off) end
            end
            
            if SV().SelectedSlot == 1 then
                local s = SV().Slots["1"]
                G.rectangle("fill", 420,30, 260,260)
                if s == nil then G.print({Red, "No data"}, 420 + x_off,30 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 420 + x_off,30 + y_off) end
            else
                G.rectangle("line", 420,30, 260,260)
                local s = SV().Slots["1"]
                if s == nil then G.print({Red, "No data"}, 420 + x_off,30 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 420 + x_off,30 + y_off) end
            end
            
            if SV().SelectedSlot == 2 then
                local s = SV().Slots["2"]
                G.rectangle("fill", 140,310, 260,260)
                if SV().Slots["2"] == nil then G.print({Red, "No data"}, 140 + x_off,310 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 140 + x_off,310 + y_off) end
            else
                local s = SV().Slots["2"]
                G.rectangle("line", 140,310, 260,260)
                if s == nil then G.print({Red, "No data"}, 140 + x_off,310 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 140 + x_off,310 + y_off) end
            end
            
            if SV().SelectedSlot == 3 then
                local s = SV().Slots["3"]
                G.rectangle("fill", 420,310, 260,260)
                if s == nil then G.print({Red, "No data"}, 420 + x_off,310 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 420 + x_off,310 + y_off) end
            else
                local s = SV().Slots["3"]
                G.rectangle("line", 420,310, 260,260)
                if s == nil then G.print({Red, "No data"}, 420 + x_off,310 + y_off) else G.print({Green, s.player.name.."\nFuel: "..s.player.fuel.."\nSupplies: "..s.player.supplies.."\nLevel: "..s.player.level.." ("..s.player.exp..")"}, 420 + x_off,310 + y_off) end
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
            SV().cooldown = 30
            if CurrentSave.player.health <= 0 then CurrentSave.player.health = 5 end
        end,
        update = function(dt)
            for _, key in ipairs(GlobalSave.keys.confirm) do
                if KB.isDown(key) and SV().cooldown == 0 then
                    DispatchEvent()
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
            if BackgroundRGBA.R > 0 then BackgroundRGBA.R = BackgroundRGBA.R - 1 end
            if BackgroundRGBA.G > 0 then BackgroundRGBA.G = BackgroundRGBA.G - 1 end
            if BackgroundRGBA.B > 0 then BackgroundRGBA.B = BackgroundRGBA.B - 1 end
            SetBG()
            DrawHUD()
            
            if Scenes.ship_main.vars.cooldown == 0 then
                G.print(" | Press "..GetKey("confirm").." to start.", 400, 0)
            else
                G.print(" | "..tostring(Scenes.ship_main.vars.cooldown), 400, 0)
            end
        end,
        closing = function() end
    },
    event_container = {
        vars = {
            SelectionID = 1
        },
        keypress = function( key, scancode, isrepeat ) 
            if table.has_value(GlobalSave.keys.move_up, key) or table.has_value(GlobalSave.keys.fire_up, key) then
                if SV().SelectionID > 1 then
                    SV().SelectionID = SV().SelectionID - 1
                    Sfx("button")
                end
            end
            
            if table.has_value(GlobalSave.keys.move_down, key) or table.has_value(GlobalSave.keys.fire_down, key) then
                if SV().SelectionID < #SV().EvtData.choices then
                    SV().SelectionID = SV().SelectionID + 1
                    Sfx("button")
                end
            end
            
            if table.has_value(GlobalSave.keys.confirm, key) then
                print(SV().EvtData.choices[SV().SelectionID][1], SV().EvtData.choices[SV().SelectionID][2])
                ExecCommand(SV().EvtData.choices[SV().SelectionID][2])
                Sfx("confirm")
            end
            
            local number = tonumber(key)
            if number and number >= 1 and number <= #SV().EvtData.choices then
                print(SV().EvtData.choices[number][1], SV().EvtData.choices[number][2])
                ExecCommand(SV().EvtData.choices[number][2])
                Sfx("confirm")
            end
            
        end,
        opening = function() 
            print("event activated", SV("event_container").EvtId) 
            SV().SelectionID = 1
        end,
        update = function(dt) end,
        draw = function() 
            if DebugMode then
                G.print("DEBUG [ EvtId: "..SV().EvtId.." // SelectionID: "..SV().SelectionID.."]")
            end
            local text = SV().EvtData.body
            local text_x = (G.getWidth() - Fonts.main:getWidth(text)) / 2 
            local text_y = 100
            G.setColor({0.2,0.2,0.2, 1})
            G.rectangle("fill", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, Fonts.main:getHeight()+20)
            G.setColor({1, 1, 1, 1})
            G.rectangle("line", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, Fonts.main:getHeight()+20)
            G.print(text, text_x, text_y)
            
            text_x = 20
            text_y = 250
            for i, opt in ipairs(SV().EvtData.choices) do
                local mstr = tostring(i).." "..opt[1]
                if DebugMode then mstr = mstr.." { "..opt[2].." }" end
                if SV().SelectionID == i then
                    G.setColor({0.7,0.2,0.2, 1})
                    G.print("> "..mstr, text_x, text_y)
                    G.setColor({1, 1, 1, 1})
                else
                    G.print(mstr, text_x, text_y)
                end
                
                text_y = text_y + 20
            end
        end,
        closing = function() end
    }
}

function DispatchEvent()
    local valid_events = {}

    for evt_id, event in pairs(Events) do
        print("Checking event "..evt_id)
        if type(event.conditions) == "string" then
            print("string type")
            if event.conditions == "*" then
                table.insert(valid_events, evt_id)
            else
                local success, result = pcall(function()
                    local chunk = load("return "..event.conditions)
                    if chunk ~= nil then
                        if chunk() == true then table.insert(valid_events, evt_id) end
                    end
                end)
            end
        elseif type(event.conditions) == "table" then
            print("table type")
            for _, cond in ipairs(event.conditions) do 
                local success, result = pcall(function()
                    local chunk = load("return "..cond)
                    if chunk ~= nil then
                        if table.contains(valid_events, evt_id) == false and chunk() == true then 
                            table.insert(valid_events, evt_id) 
                        end
                    end
                end)
            end
        end
    end
    print("Valid events: ", #valid_events)
    if #valid_events == 0 then
        Scene.set("ship_main")
    elseif #valid_events == 1 then
        ActivateEvent(valid_events[1])
    else
        local randomevt = valid_events[math.random(1, #valid_events)]
        ActivateEvent(randomevt)
    end    
end

AIScripts = {
    meteor = function(me)
        local x = me.x - me.sprite:getWidth()/2
        local y = me.y - me.sprite:getHeight()/2
        local ox = me.x + me.sprite:getWidth()/2
        local oy = me.y + me.sprite:getHeight()/2

        if x <= 0 or y <= 0 or ox >= G.getWidth() or oy >= G.getHeight() then 
            me.velocity_y = -me.velocity_y-- + math.random(-1, 1)
        end
        if x <= 0 or ox >= G.getWidth() then 
            me.velocity_x = -me.velocity_x-- + math.random(-1, 1)
        end
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
    -- Generic variables container, useful to not clutter up the main namespace
    self.v = {}
    
    self.player = false
    
    -- Defining location on the screen
    self.x = x or 0
    self.y = y or 0

    -- How fast the sprite moves
    self.move_speed = 5

    -- Direction this entity is facing, usually used for "move forward" calls
    self.direction = "up"
    
    -- How rapidly the velocity decays after initial movement
    self.velocity_decay = 1

    -- Current movement value
    self.velocity_x = 0
    self.velocity_y = 0

    -- Sprite info
    self.sprite = nil
    self.size = 1
    self.rotation = 0
    self.hidden = false
    
    -- Either index of entity, or special value, such as "player"
    self.id = nil
    
    -- Generic switch for wether this is a projectile, for quick exclusion from routines that should only effect living entities
    self.projectile = false
    
    -- The spawner function to trigger when "fire" is called
    self.projectile_spawner = Spawner.projectile1
    
    -- Generic switch for wether this is a pickup, some item on the field
    self.pickup = false
    
    -- Generic switch for inanimate objects in the field
    self.decoration = false
    
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
    
    self.execute_cooldown = 0

    -- How much damage does this entity do when it hits another
    self.hit_damage = 20
    
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
    
    if DebugMode then
        G.print("\nID: "..tostring(self.id).."\nALLIANCE: "..tostring(self.alliance).."\nOWNER: "..tostring(self.owner).."\nLOC: "..tostring(self.x).."."..tostring(self.y).."\nSPRITE: "..self.sprite:getWidth().."x"..self.sprite:getHeight(), self.x, self.y+20)
        
        local ox = self.sprite:getWidth()/2 
        local oy = self.sprite:getHeight()/2 
        G.rectangle("line", self.x - ox, self.y - oy, ox * 2, oy * 2)
    end
    
end

function Entity:fire(dir)
    if dir == nil then dir = self.direction end
    
    if self.attack_cooldown > 0 then return end

    self.projectile_spawner(self.x, self.y, self, dir)

    -- Delay the players next shot
    self.attack_cooldown = self.attack_delay
end

function Entity:sfx(name)
    --print("sfx", self.id, name)
    local src = self.sounds[name]
    
    if src == nil then return end
    
    if src:isPlaying() then
        src:stop()
    end
    
    src:play()
end
-------------------------------------
-- Clean up the entity if it goes out of bounds.
-------------------------------------
function Entity:cleanup_out_of_bounds()
    local outbounds = false
    if self.y < 0 then outbounds = true end
    if self.y > (G.getHeight()) then outbounds = true end -- - self.sprite:getHeight()
    if self.x < 0 then outbounds = true end
    if self.x > (G.getWidth()) then outbounds = true end --  - self.sprite:getWidth()
    
    if outbounds then
        if not self.player then
            self:remove_from_world() 
        end
    end
end

-------------------------------------
-- Callback that is run every tick.
-------------------------------------
function Entity:tick()
    local m = 1 * GameSpeed
    if self.attack_cooldown > 0 then self.attack_cooldown = self.attack_cooldown - m end
    if self.execute_cooldown > 0 then self.execute_cooldown = self.execute_cooldown - m end
    if self.attack_cooldown < 0 then self.attack_cooldown = 0 end
    if self.execute_cooldown < 0 then self.execute_cooldown = 0 end
    self:cleanup_out_of_bounds()
end

-------------------------------------
-- Move the entity in the specified direction.
-- @param s Distance to move.
-------------------------------------
function Entity:move_forward(s)
    --print("dir", self.id, self.direction)
    self["move_"..self.direction](self, s)
    if self.direction == "right" then self.rotation = 1.6 end
    if self.direction == "down" then self.rotation = 3.15 end
    if self.direction == "left" then self.rotation = 4.7 end
    if self.direction == "up" then self.rotation = 0 end
end

function Entity:move_up(s)
    s = s * GameSpeed
    self.y = self.y - s
end

function Entity:move_down(s)
    s = s * GameSpeed
    self.y = self.y + s
end

function Entity:move_left(s)
    s = s * GameSpeed
    self.x = self.x - s
end

function Entity:move_right(s)
    s = s * GameSpeed
    self.x = self.x + s
end

-------------------------------------
-- Checks if objects are in range and executes its action based on what it is
-- @param power Damage to hit for.
-------------------------------------
function Entity:execute(power, single_use)
    if self.execute_cooldown > 0 then return end
    
    if power == nil then power = 10 end
    if single_use == nil then single_use = true end
    
    --[[if self.projectile and self.alliance == 1 then
        local p = Play er()
        local ox = p.sprite:getWidth()/2 
        local oy = p.sprite:getHeight()/2 
        if self.x < p.x + ox and self.x > p.x - ox and self.y < p.y + oy and self.y > p.y - oy then
            AddFloatingText({ x = p.x, y = p.y, text = power, float = true })
            p:take_damage(power)
            if single_use == true then self:remove_from_world() end
        end]]--
    if self.projectile then
        for _, ent in ipairs(EntityList) do
            if ent.projectile then goto continue end
            if ent.id == self.id then goto continue end
            if self.alliance == ent.alliance then goto continue end 
            --print(self.id, self.owner)
            local ox = ent.sprite:getWidth()/2 
            local oy = ent.sprite:getHeight()/2 

            if self.x < ent.x + ox and self.x >= ent.x - ox and self.y < ent.y + oy and self.y >= ent.y - oy then
                AddFloatingText({ x = ent.x, y = ent.y, text = power, float = true })
                ent:take_damage(power, self.owner)
                if single_use == true then self:remove_from_world() end
            end
            ::continue::
        end
    elseif self.pickup then
        if self:get_distance_entity("player") <= 5 then
            CurrentSave.player.exp = CurrentSave.player.exp + power
            if single_use == true then self:remove_from_world() end
        end
    elseif self.decoration then
        --if self.velocity_x ~= 0 and self.velocity_y ~= 0 then
            for _, ent in ipairs(EntityList) do
                if ent.id == self.id then goto continue end
                if self.alliance == ent.alliance then goto continue end
                local ox = ent.sprite:getWidth()/2 
                local oy = ent.sprite:getHeight()/2 
                if self.x < ent.x + ox and self.x >= ent.x - ox and self.y < ent.y + oy and self.y >= ent.y - oy then
                    AddFloatingText({ x = ent.x, y = ent.y, text = power, float = true })
                    ent:take_damage(power, self.id)
                    AddFloatingText({ x = self.x, y = self.y, text = math.round(power/3), float = true })
                    self:take_damage(math.round(power/3), ent.id)
                    self.execute_cooldown = 50
                end
                ::continue::
            end
            
        --end
    end
end

function Entity:take_damage(dam, instigator)
    --print("Instigated "..dam.." damage from "..instigator)
    self:sfx("hit")
    self.health = self.health - dam
    if self.player then CurrentSave.player.health = self.health end
    
    if self.health <= 0 then 
        --if self.player then
            --self.health = 100 --TODO handle some death state
        --else
            local i = GetEntity(instigator)
            local attribs = self.id
            if self.projectile then attribs = self.owner end
            if i ~= nil then i:score_kill(attribs) end
            self:died(instigator) 
        --end
    end
    
    --local has_died = self.health <= 0
    
    if self.on_hit ~= nil then
        self:on_hit(instigator)
    end
end

function Entity:score_kill(target)
    print(self.id.." has killed "..target)
end
function Entity:died(instigator)
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
    if self.x < x then self.x = self.x + (self.move_speed * GameSpeed) end
    if self.x > x then self.x = self.x - (self.move_speed * GameSpeed) end
    if self.y < y then self.y = self.y + (self.move_speed * GameSpeed) end
    if self.y > y then self.y = self.y - (self.move_speed * GameSpeed) end
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
        self.direction = "right"
        self.rotation = 1.6
        self.velocity_x = self.velocity_x - (self.velocity_decay * GameSpeed)
        if self.x < (G.getWidth() - (self.sprite:getWidth() / 2)) then
            self.x = self.x + (self.velocity_x * GameSpeed)
        end
    end

    if self.velocity_y > 0 then
        self.direction = "down"
        self.rotation = 3.15
        self.velocity_y = self.velocity_y - (self.velocity_decay * GameSpeed)
        if self.y <  (G.getHeight() - (self.sprite:getHeight() / 2)) then
            self.y = self.y + (self.velocity_y * GameSpeed)
        end
    end

    if self.velocity_x < 0 then
        self.direction = "left"
        self.rotation = 4.7
        self.velocity_x = self.velocity_x + (self.velocity_decay * GameSpeed)
        if self.x > (self.sprite:getWidth() / 2) then
            self.x = self.x - -(self.velocity_x * GameSpeed)
        end
    end

    if self.velocity_y < 0 then
        self.direction = "up"
        self.rotation = 0
        self.velocity_y = self.velocity_y + (self.velocity_decay * GameSpeed)
        if self.y > (self.sprite:getHeight() / 2) then
            self.y = self.y - -(self.velocity_y * GameSpeed)
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
    if id == "player" then return Player() end

    for _, ent in ipairs(EntityList) do
        if tostring(ent.id) == tostring(id) then return ent end
    end
end

function AddFloatingText(data)
    if data.lifespan == nil then data.lifespan = 100 end
    table.insert(FloatingTexts,
        { x = data.x, y = data.y, text = tostring(data.text), lifespan = data.lifespan, i = 0, speed = data.speed,
            direction = 0, float = data.float })
end

function SV(name)
    if name == nil then name = Scene.name end
    return Scenes[name].vars
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
        
    G.print(gauge, 0, 15)
    
    G.print("EXP: "..tostring(CurrentSave.player.exp), 0, 50)
    
    if DebugMode then
        G.print("Debug Mode Enabled", 0, 65)
    end
end

-- Callbacks

function love.load()
    -- Defining state
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
    
    Sprites.player = G.newImage('sprites/playerblue.png')
    Sprites.enemy1 = G.newImage('sprites/enemyb.png')
    Sprites.projectile1 = G.newImage('sprites/shot.png')
    Sprites.projectile2 = G.newImage('sprites/enemy_shot.png')
    Sprites.pow = G.newImage('sprites/pow.png')
    Sprites.meteor1 = G.newImage('sprites/Meteors/meteorBrown_med1.png')
    Sprites.meteor2 = G.newImage('sprites/Meteors/meteorBrown_med3.png')
    Sprites.meteor3 = G.newImage('sprites/Meteors/meteorBrown_big1.png')
    Sprites.meteor4 = G.newImage('sprites/Meteors/meteorBrown_big2.png')
    Sprites.meteor5 = G.newImage('sprites/Meteors/meteorBrown_big3.png')
    
    -- Setting up save files
    if FS.getInfo(GlobalFileName) == nil then
        print("Creating global config")
        SaveFile(GlobalFileName, GlobalSave)
    else
        print("Loading default globals")
        GlobalSave = LoadFile(GlobalFileName)
    end

    -- Loading extra scripts
    local connect_extension = function(f)
        f.globals = _G
        if f.on_connect ~= nil then f.on_connect() end
        
        if f.scenes ~= nil then
            for k, v in pairs(f.scenes) do
                print("Linked scene "..k)
                Scenes[k] = v
            end
        end
        if f.ai_scripts ~= nil then
            for k, v in pairs(f.ai_scripts) do
                print("Linked AI script "..k)
                AIScripts[k] = v
            end
        end
        if f.spawners ~= nil then
            for k, v in pairs(f.spawners) do
                print("Linked Spawner "..k)
                Spawner[k] = v
            end
        end
        if f.events ~= nil then
            for k, v in pairs(f.events) do
                print("Linked Event "..k.." "..v.title)
                Events[k] = v
                print(#Events, Events[k].title)
                --table.insert(Events, v)
            end
        end
        print("Events:", #Events)
    end
    
    local sc = love.filesystem.getDirectoryItems( "scripts" )
    
    for _, item in ipairs(sc) do
        if string.ends_with(item, ".lua") then 
            print("Loading", love.filesystem.getSource().."scripts/"..item)
            connect_extension(dofile(love.filesystem.getSource().."/scripts/"..item))
        end
    end
    
    -- Loading mods
    if FS.getInfo("mods") == nil then love.filesystem.createDirectory( "mods" ) end
    
    local mods = love.filesystem.getDirectoryItems( "mods" )
    
    for _, item in ipairs(mods) do
        if string.ends_with(item, ".lua") then 
            print("Loading", SaveDir.."/mods/"..item)
            connect_extension(dofile(SaveDir.."/mods/"..item))
        end
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
    table.insert(ConsoleLog, 1, tostring(t))
end

function HandleConsole()
    if ConsoleInput == "" then return end
    table.insert(ConsoleLog, 1, ConsoleInput)
    table.insert(ConsoleMsgs, 1, "$ "..ConsoleInput)
    ExecCommand(ConsoleInput)
    ConsoleInput = ""
end

function ExecCommand(cmdln)
    local cmd = ""
    local val = ""
    
    -- If there is spaces in the string, split the input so word 1 is the command and the rest is the parameters
    if select(2, string.gsub(cmdln, " ", "")) >= 1 then
        cmd, val = string.match(cmdln, "(%S+)%s(.*)")
    else
        cmd = cmdln
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
    elseif cmd == "goto" or cmd == "event" then
        ActivateEvent(val)
    elseif cmd == "scene" then
        Scene.set(val)
    elseif cmd == "debug" then
        DebugMode = not DebugMode
        AddLog("Debug Mode: "..tostring(DebugMode))
    elseif cmd == "end" then
        Scene.set("ship_main")
    elseif cmd == "quit" then
        love.event.quit()
    else
        ExecCommand("run "..cmdln)
    end
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
