---@diagnostic disable-next-line: unused-local
---@diagnostic disable: unused-local
---@diagnostic disable-next-line: trailing-space
---@diagnostic disable: trailing-space

local class = require 'middleclass'
local techno = require 'techno'

JSON = require "json"
require "entity"

-- TODO
--[[
menu system (
make command menu font inherit from the menu object, which inherits from global, but can be overwritten
add options for command menu
text input, same as for events, saves to a variable in the menu object when typed
number, format as Text < 0 >, left and right change the number, saved to a variable each change
Add a popout value, which displays the text in a new box below or above the menu (the menu itself should have a popout location value, "above" or "below")

Continue (Only active if there is save files, and resumes last used file, uses Global save file index)
New Story (Starts new, default save)
Load (Shows list of all save files)
Options [
    Music on/off
    Music volume (Need to implement in the music player)
    Menu colour settings
]
Quit

Add support for menu titles which shows above the menu
In the menu, try making all values show not just selected ones
Replace the string load value system with a lambda function return
See if some of the load logic in events can be changed to lambdas
Menu hooks for exit

Show story info on main menu screen


Maybe group up ai scripts and spawners by game mode so rpg and space can have their own space

make the story loading flexible

remake the floating text as entities instead of their own system
add the expanding/contracting rings idea also as an entity

move more story-specific functions to the story file (abyssal.lua) or abyssal_scripts.lua in the scripts directory



- Optional third entry in event choice for conditionals, if exists then only show if conditionals are true, same as main
- Variant of execute for NPCs, but range check sets a flag that highlights it and prompts for interaction
- create a generic function for spawning a circle and expand or contract it, with a set value that destroys it when reached, similar to the floating text, use for highlighting things like UI updates
- refine floating text system and use same API for the rings, add callbacks that let me define functions to run when it expires
- add system for clickable zones, debug spawns a blue rectangle around it



Turn based, all actions consume energy, you can jump in with actions whenever by pressing the button related to the character, can only use actions if you have the energy for, and energy regains slowly over time
For resources, mp alternative, maybe have some charges or some other mp equivalent which are used for some actions that dont auto regen

For enemy AI, say they decide an action, then charge their energy up to use it



For maps
Geometry table loads from both the /maps directory, and also can be integrated by scripts like other containers
Sprites will need to be stored as strings and converted to the relevant object when loaded

For collision checking speedup
Build a 3d array of coordinates pointing to the tile info when map is loaded in, and use that for collision checking, keep the original list for rendering
]]--


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
TotalDelta = 0
TotalSeconds = 0
ShowGrid = false
CurrentMap = nil
-- Containers

Music = {}
MusicNames = {}
Sounds = {}
Sprites = {}
Tiles = {}
Fonts = {}
Geometry = {
    map_edit_debug = {
        {0, 0, "wall"},
        {32, 0, "wall"},
        {0, 32, "wall"},
    }
}


Hooks = {
    textinput = {},
    postdraw = {},
    predraw = {},
    update = {},
    keypress = {}
}

-- Template save file to use for creating new ones
DefaultSave = {
    player = {
        name = "Testing",
        fuel = 1000,
        supplies = 1000,
        health = 100,
        level = 1,
        exp = 0,
        ship_name = "Nameless"
    },
    world = {
        level = 1
    },
    crew = {},
    flags = {
        done_tutorial = false
    }
}

-- Current safe file data
CurrentSave = DefaultSave

-- Universal settings stored outside of individual save file scope
GlobalSave = {
    system = {
        savefile = 0,
        music = true,
        music_volume = 1.0
    },
    keys = {
        move_up = { "w" },
        move_down = { "s"},
        move_right = { "d" },
        move_left = { "a"},
        confirm = { "return", "space" },
        cancel = { "c", "backspace", "escape" },
        fire_up = { "up" },
        fire_down = { "down" },
        fire_right = { "right" },
        fire_left = { "left" },
        command_menu = { "z", "1" },
    }
}

TranslationTable = {
    main = "RobotoMonoNerdFontMono-Bold",
    menu = "RobotoMonoNerdFontMono-Bold",
    space = "Andy G. Cohen - Space",
    clouds = "Beat Mekanik - Making Clouds",
    code = "Mystery Mammal - Code Composer",
    sky = "TeknoAxe - Infinite Sky",
}

-- Container for custom command line actions, also used for Events triggers
CustomCommands = {}

-- Container for AI scripts, how entities should behave
AIScripts = {}

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

function ActivateEvent(evt_id)
    if table.has_key(Events, evt_id) then
        Scene.set("event_container", true)
        SV().EvtId = evt_id
        SV().EvtData = Events[evt_id]
        Scenes["event_container"].opening()
    end
end

function DispatchEvent()
    local valid_events = {}

    for evt_id, event in pairs(Events) do
        print("Checking event "..evt_id)
        if type(event.conditions) == "string" then
            --print("string type")
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
            --print("table type")
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
        Scene.set(STORY.main_scene)
    elseif #valid_events == 1 then
        ActivateEvent(valid_events[1])
    else
        local randomevt = valid_events[math.random(1, #valid_events)]
        ActivateEvent(randomevt)
    end    
end

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

Scenes = {
    menu_main = {
        vars = {
            SelectedSlot = GlobalSave.system.savefile,
            Slots = {}
        },
        keypress = function( key, scancode, isrepeat ) 
            if not IsMenuOpen() then
                Scenes.menu_main.opening()
            end
        end,
        opening = function() 
            CreateMenu({title = "Main", on_close = function() print("Main menu closed.") end})
            AddMenuCommand({text = "Continue", enabled = GlobalSave.system.savefile ~= 0 and SaveExists(GlobalSave.system.savefile)})
            
            AddMenuCommand({text = "New Story", hover_text = "Starts a brand new story.",
            
            callback = function()
                    if LoadSave() then
                        if not CurrentSave.flags.done_tutorial then
                            ActivateEvent(STORY.start_scene)
                        else
                            Scene.set(STORY.main_scene)
                        end
                        Sfx("confirm")
                        CloseAllMenu()
                        return
                    else
                        SaveFile(GetSaveFile(), DefaultSave)
                        SV().Slots[tostring(SV().SelectedSlot)] = DefaultSave
                        Sfx("confirm")
                        CloseAllMenu()
                        LoadSave()
                        if not CurrentSave.flags.done_tutorial then
                            ActivateEvent(STORY.start_scene)
                        else
                            Scene.set(STORY.main_scene)
                        end
                        return
                    end
            end})
            AddMenuCommand({text = "Load Save"})
            AddMenuCommand({text = "Save Slot", hover_text = "Changes which save slot to use by default.",
            
            value = function() return GlobalSave.system.savefile end,
            
            scroll_left = function() GlobalSave.system.savefile = GlobalSave.system.savefile - 1 end,
    
            scroll_right = function() GlobalSave.system.savefile = GlobalSave.system.savefile + 1 end})
            
            AddMenuCommand({text = "Settings", callback = function()
                CreateMenu({title = "Settings", on_close = function() print("Settings menu closed.") end})
                AddMenuCommand({text = "Music"})
                AddMenuCommand({text = "Music Volume"})
                AddMenuCommand({text = "Back", callback = RemoveMenu})
            end})
            
            AddMenuCommand({text = "Credits", callback = function()
                CreateMenu()
                AddMenuCommand({text = "It's me!"})
                AddMenuCommand({text = "Back", callback = RemoveMenu})
            end})
            AddMenuCommand({text = "Quit", callback = love.event.quit})
            
            PlayMusic("sky")
        end,
        update = function(dt)

        end,
        draw = function()
            FadeBGTo(100, 0, 0)
            
            if not IsMenuOpen() then
                G.print("Press any button to start.", 100, 100)
            end
        end,
        closing = function() end
    },
    ship_main = {
        vars = {
            -- Cooldown for activator that enables heading to event
            cooldown = 0,
            
            searching_for_event = false,
            search_time = 0
        },
        keypress = function( key, scancode, isrepeat ) 
            if key == "f2" then 
                WriteSave()
                print("Saved.")
            end
        end,
        opening = function() 
            PlayMusic("code")
            SV().cooldown = 30
            SV().searching_for_event = false
            SV().search_time = 0
            if CurrentSave.player.health <= 0 then CurrentSave.player.health = 5 end
            
            -- TODO make a toggle for whether or not to auto-save
            print("Saving.")
            WriteSave()
        end,
        update = function(dt)
            if SV().searching_for_event then 
                for _, key in ipairs(GlobalSave.keys.cancel) do
                    if KB.isDown(key) then
                        SV().searching_for_event = false
                        SV().search_time = 0
                        SV().cooldown = 30
                        return
                    end
                end
                return
            end
            
            for _, key in ipairs(GlobalSave.keys.confirm) do
                if KB.isDown(key) and SV().cooldown == 0 then
                    --DispatchEvent()
                    Sfx("start")
                    SV().searching_for_event = true
                    return
                end
            end
            
            if KB.isDown("f12") then 
                Scene.set("menu_main") 
                return
            end
            
            if SV().cooldown > 0 then SV().cooldown = SV().cooldown - 1 end
        end,
        second = function()
            if SV().searching_for_event then
                SV().search_time = SV().search_time + 1
                PlayerData().fuel = PlayerData().fuel - 1
                
                local randomNum = math.random(1, 50)
                if randomNum <= SV().search_time then
                    DispatchEvent()
                end
            end
        end,
        draw = function() 
            if SV().searching_for_event then
                FadeBGTo(100, 25, 25)
                
                if TotalSeconds % 3 == 0 then
                    G.print(" Drifting in the depths of space..", 0, 250)
                    
                elseif TotalSeconds % 3 == 1 then
                    G.print(" Drifting in the depths of space...", 0, 250)
                    
                elseif TotalSeconds % 3 == 2 then
                    G.print(" Drifting in the depths of space....", 0, 250)
                end
                G.print(" "..tostring(SV().search_time).." seconds since last event.", 0, 270)
                G.print(" "..tostring(PlayerData().fuel).." fuel remaining.", 0, 290)
                G.print(GetKey("cancel").." to stop the engines.", 400, 0)
            else
                FadeBGTo(0, 0, 0)
                DrawHUD()
                
                if SV().cooldown == 0 then
                    G.print(" | Press "..GetKey("confirm").." to launch.", 400, 0)
                else
                    G.print(" | Engines charging: "..tostring(SV().cooldown), 400, 0)
                end
                
                G.print("Crew: "..tostring(#CurrentSave.crew), 0, 400)
                G.print("Crew 1: "..CurrentSave.crew[1].name, 0, 425)
            end

        end,
        closing = function() end
    },
    event_container = {
        vars = {
            SelectionID = 1,
            tt_text = "",
            tt_opts = {},
            modified_text = "",
            input_text = "",
            cooldown = 25
        },
        keypress = function( key, scancode, isrepeat ) 
            if SV().EvtData == nil then return end
            if SV().EvtData.choices ~= nil then
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
                
                if table.has_value(GlobalSave.keys.confirm, key) and SV().cooldown == 0 then
                    print(SV().EvtData.choices[SV().SelectionID][1], SV().EvtData.choices[SV().SelectionID][2])
                    ExecCommand(SV().EvtData.choices[SV().SelectionID][2])
                    Sfx("confirm")
                    return
                end
                
                local number = tonumber(key)
                if number and number >= 1 and number <= #SV().EvtData.choices then
                    print(SV().EvtData.choices[number][1], SV().EvtData.choices[number][2])
                    ExecCommand(SV().EvtData.choices[number][2])
                    Sfx("confirm")
                end
            end
            
            if SV().EvtData.get_input ~= nil then
                if key == "backspace" then
                    SV().input_text = string.sub(SV().input_text, 1, -2)
                end
                
                if key == "return" and SV().cooldown <= 0 then
                    if SV().EvtData.get_input.run ~= nil then
                        ExecCommand(SV().EvtData.get_input.run:gsub("|input|", SV().input_text))
                        --"\""..SV().input_text.."\""))
                    end
                end
            end
            
        end,
        opening = function() 
            local function deindent(str)
                local lines = {}
                for line in str:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end
                local minIndent = math.huge
                for _, line in ipairs(lines) do
                    local indent = line:match("^%s*")
                    if #indent > 0 and #indent < minIndent then
                    minIndent = #indent
                    end
                end
                for i, line in ipairs(lines) do
                    lines[i] = line:sub(minIndent + 1)
                end
                return table.concat(lines, "\n")
            end
            print("event activated: ", SV("event_container").EvtId) 
            SV().SelectionID = 1
            SV().tt_text = ""
            SV().tt_opts = {}
            SV().input_text = ""
            SV().cooldown = 25
            
            if SV().EvtData.get_input ~= nil and SV().EvtData.get_input.default_text ~= nil then
                if type(SV().EvtData.get_input.default_text) == "string" then
                    SV().input_text = tostring(SV().EvtData.get_input.default_text)
                elseif type(SV().EvtData.get_input.default_text) == "function" then
                    SV().input_text = tostring(SV().EvtData.get_input.default_text())
                end
                --[[print("RUNNING get "..SV().EvtData.get_input.default_text)
                local t = ExecCommand("get "..SV().EvtData.get_input.default_text)
                if t ~= nil then
                    SV().input_text = tostring(t)
                end]]--
            end
            
            if SV().EvtData.choices ~= nil then
                for i, _ in ipairs(SV().EvtData.choices) do
                    SV().tt_opts[i] = ""
                end
            end
            
            local text = SV().EvtData.body
            text:gsub("|(.-)|", function(match)
                print("getting "..match)
                local reps = ExecCommand("get "..match)
                local toget = string.gsub("|"..match.."|", "[()]", "%%%1")
                print("replacing "..toget.." with "..reps)
                text = text:gsub(toget, reps)
                print("post edit: ", text)
            --end
            end)
            

            SV().modified_text = deindent(text)
            
        end,
        update = function(dt) 
            if SV().cooldown > 0 then SV().cooldown = SV().cooldown - 1 end
            if SV().modified_text ~= SV().tt_text then
                local cursor = #SV().tt_text + 1
                local extractedChar = string.sub(SV().modified_text, cursor, cursor)
                SV().tt_text = SV().tt_text .. extractedChar
            end
            
            if SV().EvtData.choices ~= nil then
                for i, opt in ipairs(SV().EvtData.choices) do
                    local cursor = #SV().tt_opts[i] + 1
                    if SV().tt_opts[i] ~= opt[1] then 
                        local extractedChar = string.sub(opt[1], cursor, cursor)
                        SV().tt_opts[i] = SV().tt_opts[i] .. extractedChar
                    end

                end
            end
            
        end,
        second = function()
            --if SV().cooldown > 0 then SV().cooldown = SV().cooldown - 1 end
        end,
        textinput = function(t)
            SV().input_text = SV().input_text .. t
        end,
        draw = function() 
            FadeBGTo(0, 0, 0)
            if DebugMode then
                G.print("DEBUG [ EvtId: "..SV().EvtId.." // SelectionID: "..SV().SelectionID.." // CD "..SV().cooldown.."]")
            end
            
            local title = SV().EvtData.title
            G.print(title, (G.getWidth() - Fonts.main:getWidth(title)) / 2 , 50)
            
            
            local lines = 0

            local text = SV().modified_text

            local text_x = (G.getWidth() - Fonts.main:getWidth(text)) / 2 
            local text_y = 100
            
            for _ in text:gmatch("\n") do lines = lines + 1 end
            
            local rectHeight = Fonts.main:getHeight() + 20
            
            if lines > 0 then rectHeight = ((rectHeight - 20) * lines) + 20 end
            
            G.setColor({0.2,0.2,0.2, 1})
            G.rectangle("fill", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, rectHeight)
            G.setColor({1, 1, 1, 1})
            G.rectangle("line", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, rectHeight)
            G.print(SV().tt_text, text_x, text_y)
            

            
            if SV().EvtData.get_input ~= nil then
                text_y = text_y + rectHeight
                --G.print("Input text: ", text_x, text_y-25)
                G.setColor({0.6,0.2,0.2, 1})
                G.rectangle("fill", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, Fonts.main:getHeight() + 20)
                G.setColor({0.8, 0.8, 0.8, 1})
                G.rectangle("line", text_x-10, text_y-10, Fonts.main:getWidth(text)+20, Fonts.main:getHeight() + 20)
                --G.getWidth()-20
                G.print(SV().input_text.."_", text_x, text_y)
                G.setColor({1, 1, 1, 1})
                G.print("(Enter)", text_x, text_y+25)
            end
            

            
            if SV().EvtData.choices ~= nil then
                text_x = 20
                text_y = 250
                for i, opt in ipairs(SV().EvtData.choices) do
                    local mstr = tostring(i).." "..SV().tt_opts[i]
                    
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
            end
        end,
        closing = function() end
    }
}

Templates = {
    

}
MenuStack = {}

MenuSystems = {
    command = {
        draw = function(current) 
            local x = current.x
            local y = current.y
            local w = current.width
            local h = current.height
            local font = Fonts.menu
            local bt = current.border_thickness

            local auto_w = (w == -1)
            local auto_h = (h == -1)
            local cent_x = (x == -1)
            local cent_y = (y == -1)

            for i, cmd in ipairs(current.commands) do
                if auto_w then
                    if font:getWidth("> "..cmd.text) > w then
                        w = font:getWidth("> "..cmd.text)
                    end
                end
                
                if auto_h then
                    h = h + font:getHeight()
                end
            end

            if cent_x then
                x = (G.getWidth() - w) / 2
            end

            if cent_y then
                y = (G.getHeight() - h) / 2
            end

            local text_x = x
            local text_y = y

            if DebugMode then
                G.print("H "..tostring(h).." // W "..tostring(w), text_x-25, text_y-50)
                G.print("FH "..tostring(font:getHeight()), text_x-25, text_y-25)
            end


            G.setColor(current.bg)
            G.rectangle("fill", x-5, y, w+10, h)
            G.setColor(current.border)
            G.setLineWidth(bt)
            G.rectangle("line", x-5, y, w+10, h)
            G.setLineWidth(1)
            G.setColor({1, 1, 1, 1})

            if current.title ~= "" then
                local tf = Fonts.main
                G.setColor(current.bg)
                G.rectangle("fill", x-5, y-tf:getHeight(), tf:getWidth(current.title)+10, tf:getHeight())
                G.setColor(current.border)
                G.setLineWidth(bt)
                G.rectangle("line", x-5, y-tf:getHeight(), tf:getWidth(current.title)+10, tf:getHeight())
                G.setLineWidth(1)
                G.setColor({1, 1, 1, 1})
                G.print(current.title, x, y-tf:getHeight())
            end

            for i, cmd in ipairs(current.commands) do        
                local prefix = ""
                
                if cmd.value ~= nil then
                    local base_x = text_x+5+w
                    local base_y = text_y
                    local txt = "< "..tostring(cmd.value()).." >"
                    
                    G.setColor(current.bg)
                    G.rectangle("fill", base_x, base_y, font:getWidth(txt), font:getHeight())
                    G.setColor(current.border)
                    G.setLineWidth(bt)
                    G.rectangle("line", base_x, base_y, font:getWidth(txt), font:getHeight())
                    G.setLineWidth(1)
                    G.setColor({1, 1, 1, 1})
                    
                    G.setFont(font)
                    G.print(txt, base_x, base_y)
                    G.setFont(Fonts.main)
                        
                end
                
                if i == current.cursor and cmd.hover_text ~= "" then
                    local pf = font
                    local px = 0
                    local py = 0
                    
                    if current.hover_popout_location == "screen_top" then
                        px = (G.getWidth() - pf:getWidth(cmd.hover_text)) / 2 
                        py = 0
                    elseif current.hover_popout_location == "screen_bottom" then
                        px = (G.getWidth() - pf:getWidth(cmd.hover_text)) / 2 
                        py = (G.getHeight() - (pf:getHeight() * 2))
                    end

                    G.setFont(font)
                    G.setColor(current.bg)
                    G.rectangle("fill", px, py+pf:getHeight(), pf:getWidth(cmd.hover_text)+10, pf:getHeight())
                    G.setColor(current.border)
                    G.setLineWidth(bt)
                    G.rectangle("line", px, py+pf:getHeight(), pf:getWidth(cmd.hover_text)+10, pf:getHeight())
                    G.setLineWidth(1)
                    G.setColor({1, 1, 1, 1})
                    G.print(cmd.hover_text, px, py+pf:getHeight())
                    --print(py,cmd.hover_text)
                    G.setFont(Fonts.main)
                end
                
                if i == current.cursor and cmd.enabled == false then
                    G.setColor(current.disabled_colour)
                    prefix = "X "
                elseif cmd.enabled == false then
                    G.setColor(current.disabled_colour)
                elseif i == current.cursor then 
                    G.setColor(current.select_colour) 
                    prefix = "> "
                else
                    G.setColor(current.text_colour) 
                end
                    
                G.setFont(font)
                G.print(prefix..cmd.text, text_x, text_y)
                G.setFont(Fonts.main)
                if DebugMode then G.print(tostring(text_y), text_x-40, text_y) end
                
                G.setColor({1, 1, 1, 1})
                text_y = text_y + font:getHeight()
            end
        end, 
        key = function(key)
            if table.contains(GlobalSave.keys.fire_left, key) or table.contains(GlobalSave.keys.move_left, key) then
                local cmd = GetSelectedMenuCommand()
                if cmd.scroll_left ~= nil then
                    cmd.scroll_left()
                end
                return true
            end

            if table.contains(GlobalSave.keys.fire_right, key) or table.contains(GlobalSave.keys.move_right, key) then
                local cmd = GetSelectedMenuCommand()
                if cmd.scroll_right ~= nil then
                    cmd.scroll_right()
                end
                return true
            end

            if table.contains(GlobalSave.keys.fire_up, key) or table.contains(GlobalSave.keys.move_up, key) then
                local m = GetCurrentMenu()
                
                if m.cursor > 1 then 
                    m.cursor = m.cursor - 1 
                else
                    m.cursor = #m.commands
                end
                
                return true
            end

            if table.contains(GlobalSave.keys.fire_down, key) or table.contains(GlobalSave.keys.move_down, key) then
                local m = GetCurrentMenu()
                
                if m.cursor < #m.commands then 
                    m.cursor = m.cursor + 1 
                else
                    m.cursor = 1
                end
                
                return true
            end

            if table.contains(GlobalSave.keys.confirm, key) then
                local m = GetCurrentMenu()
                
                if m.commands[m.cursor].callback ~= nil and m.commands[m.cursor].enabled then
                    Sfx(m.commands[m.cursor].sfx)
                    m.commands[m.cursor].callback() 
                end
                return true
            end

            if table.contains(GlobalSave.keys.cancel, key) then
                local m = GetCurrentMenu()
                print(#MenuStack, m.back_can_close_last)
                if #MenuStack == 1 and m.back_can_close_last then
                    RemoveMenu()
                elseif #MenuStack > 1 then
                    RemoveMenu()
                end
                return true
            end
        end
    }
}

function IsMenuOpen()
    return (#MenuStack > 0)
end

function GetCurrentMenu()
    return MenuStack[#MenuStack]
end

function CreateMenu(opts)
    if opts == nil then opts = {} end
    
    local newmenu = {
        x = -1,
        y = -1,
        width = -1,
        height = -1,
        bg = {0.2, 0.2, 0.6, 1},
        border = {1, 1, 1, 1},
        border_thickness = 2,
        commands = {},
        text_colour = {1, 1, 1, 1},
        select_colour = {0.5, 1, 1, 1},
        disabled_colour = {0.2, 0.2, 0.2, 0.2},
        cursor = 1,
        menu_type = "command",
        back_can_close_last = true,
        title = "",
        hover_popout_location = "screen_top",
        on_close = nil
    }
    
    MergeObj(newmenu, opts)
    table.insert(MenuStack, newmenu)
end

function RemoveMenu()
    if MenuStack[#MenuStack].on_close ~= nil then
        MenuStack[#MenuStack].on_close()
    end
    table.remove(MenuStack)
end

function CloseAllMenu()
    while #MenuStack ~= 0 do
        RemoveMenu()
    end
end

function AddMenuCommand(opts)
    if opts == nil then opts = {} end
    local current = MenuStack[#MenuStack]
    local newcmd = {
        text = "Default Command",
        callback = nil,
        enabled = true,
        sfx = "confirm",
        value_type = nil,
        value = nil,
        hover_text = ""
    }
    MergeObj(newcmd, opts)
    table.insert(current.commands, newcmd)
end

function GetSelectedMenuCommand()
    local m = MenuStack[#MenuStack]
    return m.commands[m.cursor]
end

function RemoveMenuCommand(idx)
    local current = MenuStack[#MenuStack]
    table.remove(current.commands, idx)
end

function RenderMenu()
    if #MenuStack == 0 then return end
    
    local current = MenuStack[#MenuStack]
    if MenuSystems[current.menu_type] ~= nil then
        MenuSystems[current.menu_type].draw(current)
        return true
    end
end

function HandleMenuInput(ik)
    if IsMenuOpen() then
        local current = MenuStack[#MenuStack]
        if MenuSystems[current.menu_type] ~= nil then
            return MenuSystems[current.menu_type].key(ik)
        end
    end

end


function FadeBGTo(r, g, b, scale)
    if scale == nil then scale = 1 end
    if BackgroundRGBA.R > r then BackgroundRGBA.R = BackgroundRGBA.R - scale end
    if BackgroundRGBA.G > g then BackgroundRGBA.G = BackgroundRGBA.G - scale end
    if BackgroundRGBA.B > b then BackgroundRGBA.B = BackgroundRGBA.B - scale end
    if BackgroundRGBA.R < r then BackgroundRGBA.R = BackgroundRGBA.R + scale end
    if BackgroundRGBA.G < g then BackgroundRGBA.G = BackgroundRGBA.G + scale end
    if BackgroundRGBA.B < b then BackgroundRGBA.B = BackgroundRGBA.B + scale end
    SetBG()
end

BackgroundRGBA = { R = 0, G = 0, B = 0,  A = 0 }


-- Functions

function RenderMap(target)
    if Geometry[target] == nil then print("Can't render map: "..target) return end
    for _, tile in ipairs(Geometry[target]) do
        --print(tile[1], tile[2], tile[3])
        G.draw(Tiles[tile[3]], tile[1], tile[2])
    end
end

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

function PlayerData()
    return CurrentSave.player
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
    src:setVolume(GlobalSave.system.music_volume)
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

function SaveExists(i)
    return (FS.getInfo(GetSaveFile(i)) ~= nil)
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

function LoadEScript(extpath)
    local ext = dofile(love.filesystem.getSource().."/scripts/"..extpath..".lua")
    ConnectExtension(ext)
end

function ConnectExtension(f)
    print("Adding extension: ",f.name)
    --local rancscript = false
    local iscenes = 0
    local iai = 0
    local ispawners = 0
    local ievents = 0
    local icmd = 0
    local ims = 0
    
    if f.on_connect ~= nil then 
        f.on_connect() 
        --rancscript = true
    end
    
    if f.scenes ~= nil then
        for k, v in pairs(f.scenes) do
            print("Linked scene:      ",k)
            Scenes[k] = v
            iscenes = iscenes + 1
        end
    end
    if f.ai_scripts ~= nil then
        for k, v in pairs(f.ai_scripts) do
            print("Linked AI script: ", k)
            AIScripts[k] = v
            iai = iai + 1
        end
    end
    if f.spawners ~= nil then
        for k, v in pairs(f.spawners) do
            print("Linked Spawner: ",k)
            Spawner[k] = v
            ispawners = ispawners + 1
        end
    end
    if f.events ~= nil then
        for k, v in pairs(f.events) do
            print("Linked Event:      ", k.." // "..v.title)
            Events[k] = v
            ievents = ievents + 1
        end
    end
    if f.commands ~= nil then
        for k, v in pairs(f.commands) do
            print("Linked Command: ",k)
            CustomCommands[k] = v
            icmd = icmd + 1
        end
    end
    
    if f.menu_systems ~= nil then
        for k, v in pairs(f.menu_systems) do
            print("Linked Menu System: ",k)
            MenuSystems[k] = v
            ims = ims + 1
        end
    end
    
    if f.hooks ~= nil then
        for k, v in pairs(f.hooks) do
            print("Linking "..k.." Hook...")
            for hk, hv in pairs(v) do
                print("Linked "..k.." Hook: ",hk)
                Hooks[k][hk] = hv
            end
        end
    end

    --print("Scenes: "..iscenes.." | AI scripts: ".. iai.." | Spawners: "..ispawners.." | Events: "..ievents.." | Commands: "..icmd.." | Menus: "..ims)
end
    

-- Callbacks
-- TODO make it auto-load all sprites
-- clear out sprites directory 
-- make fonts and music follow the same rules too
-- for music, keep a json database of the file names and the song names,
-- so i can make the file name `space.mp3` while still keeping the full name for the Now Playing track
-- replace references to MusicNames with TranslationTable
function love.load()
    -- Defining state
    SaveDir = FS.getSaveDirectory()
    
    STORY = require 'stories.abyssal' --TODO add way to change story
    
    -- Loading assets
    Fonts.main = G.newFont("fonts/RobotoMonoNerdFontMono-Bold.ttf")--("FiraCodeNerdFont-Bold.ttf")
    Fonts.menu = G.newFont("fonts/RobotoMonoNerdFontMono-Bold.ttf", 16)
    Fonts.notify = G.newFont("fonts/RobotoMonoNerdFontMono-Bold.ttf", 16)
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
    
    -- Loading sounds    
    for _, item in ipairs(love.filesystem.getDirectoryItems( "sounds" )) do
        if string.ends_with(item, ".mp3") then 
            local f = string.gsub(item, "%..+", "")
            print("Loading sound", love.filesystem.getSource().."/sounds/"..item)
            Sounds[f] = A.newSource('sounds/'..item, "static")
        end
    end
    
    --[[Sounds.button = A.newSource("sounds/button.mp3", "static")
    Sounds.confirm = A.newSource("sounds/confirm.mp3", "static")
    Sounds.start = A.newSource("sounds/start.mp3", "static")
    Sounds.yay = A.newSource("sounds/yay.mp3", "static")]]--
    
    -- Loading sprites    
    for _, item in ipairs(love.filesystem.getDirectoryItems( "sprites" )) do
        if string.ends_with(item, ".png") then 
            local f = string.gsub(item, "%..+", "")
            print("Loading sprite", love.filesystem.getSource().."/sprites/"..item)
            Sprites[f] = G.newImage('sprites/'..item)
        end
    end
    
    --Sprites.player = G.newImage('sprites/playerblue.png')
    --Sprites.crew = G.newImage('sprites/crew.png')
    --Sprites.wall = G.newImage('sprites/wall.png')
    --Sprites.enemy1 = G.newImage('sprites/enemyb.png')
    --prites.projectile1 = G.newImage('sprites/shot.png')
    --Sprites.projectile2 = G.newImage('sprites/enemy_shot.png')
    --Sprites.pow = G.newImage('sprites/pow.png')
    --[[Sprites.meteor1 = G.newImage('sprites/Meteors/meteorBrown_med1.png')
    Sprites.meteor2 = G.newImage('sprites/Meteors/meteorBrown_med3.png')
    Sprites.meteor3 = G.newImage('sprites/Meteors/meteorBrown_big1.png')
    Sprites.meteor4 = G.newImage('sprites/Meteors/meteorBrown_big2.png')
    Sprites.meteor5 = G.newImage('sprites/Meteors/meteorBrown_big3.png')]]--
    
    -- Loading tiles    
    for _, item in ipairs(love.filesystem.getDirectoryItems( "tiles" )) do
        if string.ends_with(item, ".png") then 
            local f = string.gsub(item, "%..+", "")
            print("Loading tile", love.filesystem.getSource().."/tiles/"..item, "as", f)
            Tiles[f] = G.newImage('tiles/'..item)
        end
    end
    
    -- Setting up save files
    if FS.getInfo(GlobalFileName) == nil then
        print("Creating global config")
        SaveFile(GlobalFileName, GlobalSave)
    else
        print("Loading default globals")
        GlobalSave = LoadFile(GlobalFileName)
    end

    -- Loading extra scripts        
    for _, item in ipairs(love.filesystem.getDirectoryItems( "scripts" )) do
        if string.ends_with(item, ".lua") then 
            print("Loading script", love.filesystem.getSource().."/scripts/"..item)
            local ext = dofile(love.filesystem.getSource().."/scripts/"..item)
            if ext.autoload then ConnectExtension(ext) end
        end
    end
    
    -- Loading mods
    if FS.getInfo("mods") == nil then love.filesystem.createDirectory( "mods" ) end
    
    for _, item in ipairs(love.filesystem.getDirectoryItems( "mods" )) do
        if string.ends_with(item, ".lua") then 
            print("Loading", SaveDir.."/mods/"..item)
            ConnectExtension(dofile(SaveDir.."/mods/"..item))
        end
    end
    
    Scene.set("menu_main")
end

function love.keypressed( key, scancode, isrepeat )
    -- Global system binds
    local blocking = false
    
    for _, v in pairs(Hooks.keypress) do
        blocking = v(key, scancode, isrepeat)
    end
    
    if blocking then return end
    
    --TODO delete this once options menu is complete
    if key == "f11" then 
        if GlobalSave.system.music == true then DisableMusic() else EnableMusic() end
        return
    end
    
    if key == "f10" or key == "pause" then
        Paused = not Paused
        return
    end

    
    if not ConsoleOpen then
        if HandleMenuInput(key) then return end
        
        Scene.get().keypress(key, scancode, isrepeat)
    end
end

function love.update(dt)
    TotalDelta = TotalDelta + dt
    local s = math.floor(TotalDelta)
    
    if s ~= TotalSeconds then
        TotalSeconds = s
        if Scene.get().second ~= nil then
            Scene.get().second()
        end
        
    end
    if not Paused and Scene.get().update ~= nil then
        Scene.get().update(dt)
        for _, v in pairs(Hooks.update) do
            v()
        end
    end
end

ShowMusic = true


function love.textinput(t)
    for _, v in pairs(Hooks.textinput) do
        v(t)
    end
    
    if Scene.get().textinput ~= nil then
        Scene.get().textinput(t)
    end
end

function love.mousepressed( x, y, button, istouch, presses )
    if Scene.get().mousepressed ~= nil then
        Scene.get().mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousemoved( x, y, dx, dy, istouch )
    if Scene.get().mousemoved ~= nil then
        Scene.get().mousemoved(x, y, dx, dy, istouch)
    end
end

function love.draw() 
    for _, v in pairs(Hooks.predraw) do
        v()
    end
    
    if ShowGrid then
        love.graphics.setColor({1, 1, 1, 0.5})
        local tileSize = 32
        local rows = math.ceil(G.getHeight() / tileSize)
        local cols = math.ceil(G.getWidth() / tileSize)
        for i = 1, rows do
            for j = 1, cols do
                G.rectangle("line", (j - 1) * tileSize, (i - 1) * tileSize, tileSize, tileSize)
            end
        end
        love.graphics.setColor({1, 1, 1, 1})
    end
    
    if Scene.get().draw ~= nil then
        Scene.get().draw()
    end
    
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
    
    RenderMenu()

    for _, v in pairs(Hooks.postdraw) do
        v()
    end
    
    
end

function love.quit()
    --TODO handle saving state on exit
    return false
end
