local class = require 'middleclass'
EntityList = {}

-- BEGIN ENTITY
Entity = class('Entity')
LastID = 0

function Entity:initialize(x, y)
    -- Generic variables container, useful to not clutter up the main namespace
    self.v = {}
    
    self.player = false
    
    self.name = ""
    
    -- Defining location on the screen
    self.x = x or 0
    self.y = y or 0
    
    -- Defining location of sprite for field scene, seperate from the raw object location, to allow smoth sprite movement when snapping between cells
    self.fsx = 0
    self.fsy = 0
    
    self.sprite_speed = 4
    
    -- Ugly switch for changing between logic, behaving as tile-based instead of pure movement
    self.tile_based = false
    
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
    local myx = self.x
    local myy = self.y
    if self.tile_based then
        myx = self.fsx-- * 32
        myy = self.fsy-- * 32
        G.print("\n"..self.name, myx-40, myy-40)
    end
    
    G.draw(self.sprite, myx, myy, self.rotation, self.size, self.size, self.sprite:getWidth() / 2, self.sprite:getHeight() / 2)
    
    if DebugMode then
        G.print("\nID: "..tostring(self.id).."\nALLIANCE: "..tostring(self.alliance).."\nOWNER: "..tostring(self.owner).."\nLOC: "..tostring(myx).."."..tostring(myy).."\nSPRITE: "..self.sprite:getWidth().."x"..self.sprite:getHeight(), myx, myy+20)
        
        local ox = self.sprite:getWidth()/2 
        local oy = self.sprite:getHeight()/2 
        G.rectangle("line", myx - ox, myy - oy, ox * 2, oy * 2)
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

function Entity:fmove(dir, amt)
    if dir == "x" or dir == "y" then
        self[dir] = self[dir] + amt
    end
end

function Entity:start_move(dir, amt)
    --print(self.tile_based, dir, amt)
    if self.tile_based then
        local new_value = self[dir] + (amt * 32)
        if new_value <= 0 then return end
        
        if dir == "x" then
            local max_wid = G.getWidth()
            if new_value >= max_wid then return end
            self[dir] = new_value
        elseif dir == "y" then
            local max_height = G.getHeight()
            if new_value >= max_height then return end
            self[dir] = new_value
        end
    else
        if dir == "x" or dir == "y" then
            self["velocity_" .. dir] = amt
        end
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
    if self.tile_based then
        if self.fsx > self.x then
            self.fsx = self.fsx - self.sprite_speed
        end
        if self.fsy > self.y then
            self.fsy = self.fsy - self.sprite_speed
        end
        if self.fsx < self.x then
            self.fsx = self.fsx + self.sprite_speed
        end
        if self.fsy < self.y then
            self.fsy = self.fsy + self.sprite_speed
        end
        --print(self.name, self.player, self.fsx, self.fsy, self.x, self.y)
    else
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
    

end

-- END ENTITY

-- Get the current Player entity
function Player()
    for _, ent in ipairs(EntityList) do if ent.player then return ent end end
end

function GetEntity(id)
    if id == "player" then return Player() end

    for _, ent in ipairs(EntityList) do
        if tostring(ent.id) == tostring(id) then return ent end
    end
end
