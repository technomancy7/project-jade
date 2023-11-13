---@diagnostic disable-next-line: unused-local
---@diagnostic disable: unused-local
---@diagnostic disable-next-line: trailing-space
---@diagnostic disable: trailing-space
---@diagnostic disable-next-line: deprecated
---@diagnostic disable: deprecated

JADE_VERSION = "0.0.40"

local class = require 'middleclass'
local techno = require 'techno'

JSON = require "json"
require "entity"

-- TODO
--[[
Text Input box element for windows

load "terminal" font and use that for menus?

Everything rpg based on skills, weapons, armour, also hacking, fishing 

Also add a close button to notifs, and maybe a pin button to prevent auto closing

Sheets support for tiles and sprites
Tile properties table, to add values for each tile, like define wall with solid

Add support for gauges to have borders

System for screen covers, creating an image to cover the screen
For some transitions, create a cover of some loading screen
Different ways of creating and destroying, either using transparency to fade it out, or scrolling it out

Options to turn shooter section in to side or down scrollers, like locking direction of player, disabling certain movements (maybe those keys change speed instead)

Actually implement Continue from last save in menu, make sure last used save in global actual gets saved to file and loaded next time


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



move more story-specific functions to the story file (abyssal.lua) or abyssal_scripts.lua in the scripts directory



- Optional third entry in event choice for conditionals, if exists then only show if conditionals are true, same as main

- Variant of execute for NPCs, but range check sets a flag that highlights it and prompts for interaction

- create a generic function for spawning a circle and expand or contract it, with a set value that destroys it when reached, similar to the floating text, use for highlighting things like UI updates

- refine floating text system and use same API for the rings, add callbacks that let me define functions to run when it expires


Turn based, all actions consume energy, you can jump in with actions whenever by pressing the button related to the character, can only use actions if you have the energy for, and energy regains slowly over time
For resources, mp alternative, maybe have some charges or some other mp equivalent which are used for some actions that dont auto regen

For enemy AI, say they decide an action, then charge their energy up to use it


Card based battle system
System for loading cards from both cards.json main file, and /cards/ directory
Keep it simple, each character has X energy, maybe out of 100, and each character has their own deck of cards
Characters may regenerate a small amount of energy each turn based on some skills or upgrades, or discard a card to gain its cost as energy
Cards are simple rules, which represent as basic symbols or keywords
Cards can be modified by skills, like Armour X gives X+Your Armour skill

Cost (top corner)
In-card values:
Attack X - Deals X damage to adjacent enemy
Shoot X - Deals X damage to distant enemy in row
Armour X - Reduces damage by X amount, armour is reduced after each attack
Move X - Moves X tiles
Ghost - Usable once per combat
Destroy - Removed from deck completely
+ Inflict X - Only if Attack or Shoot, if attack hits, guarantees apply status effect on target
+ May inflict X - Only if Attack or Shoot, if attack hits, chance to apply status effect on target
Gain X - Apply status effect to self
Draw X - Draw X cards
If X then Y - X can be a conditional related to the battle
+ If target X then Y - Only if Attack or Shoot, if target conditional then do Y, such as if target has status
+ If self X then Y - Only if Attack or Shoot, conditional based on the caster
X =/-=/+= Y - Modifies status effect counter (called registers in-game)

Status effects/registers
Armour (Reduces damage taken by Armour amount, then reduces Armour amount by some fraction)
Dodge (Evades next attack)
Poison X (Takes X damage each turn, then reduce Poison by 1)
Regenerate X (Heals X each turn)
Curse (May fail next card use)
Psychic Poison X (Poison, but for energy)


For collision checking speedup
Build a 3d array of coordinates pointing to the tile info when map is loaded in, and use that for collision checking, keep the original list for rendering


Menus to create
In ship only
Deck management
Crew management (ground crew vs ship crew, moving around)

Universal
A button to bring up a help search where you can either type a query in or go down a list, used for defining terms in the world
Notes screen to let the player write anything they want in, either for remembering things or creating their own goals, plus API's for letting code interface with the notes system


Move colouring for buttons, menus, etc in to a theme global
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

SaveDir = ""
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

Theme = {}

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
            --SelectedSlot = GlobalSave.system.savefile,
            --Slots = {}
            saves = {}
        },
        keypress = function( key, scancode, isrepeat ) 
            if not IsMenuOpen() and not MenuDeactivated then
               -- print("Menu not open")
                Scenes.menu_main.opening()
            end
        end,
        opening = function() 
            SV().saves = ListSaves()
            print("Menus "..tostring(#MenuStack))
            CreateMenu({title = "Main", on_close = function() print("Main menu closed.") end})
            AddMenuCommand({text = "Continue", enabled = GlobalSave.system.savefile ~= 0 and SaveExists(GlobalSave.system.savefile)})
            
            AddMenuCommand({text = "New Story", hover_text = "Starts a brand new story.",
            
            callback = function()
                GlobalSave.system.savefile = GetNextSaveID()
                AddNotify("Initializing save slot "..tostring(GlobalSave.system.savefile))
                SaveFile(GetSaveFile(GlobalSave.system.savefile), DefaultSave)
                Sfx("confirm")
                CloseAllMenu()
                WindowManager.destroy("Development")
                LoadSave("default")
                if not CurrentSave.flags.done_tutorial then
                    ActivateEvent(STORY.start_scene)
                else
                    Scene.set(STORY.main_scene)
                end
            end})
            
            AddMenuCommand({text = "Load Save", callback = function()
                CreateMenu({title = "Load Saves"})
                for _, i in ipairs(SV().saves) do
                    AddMenuCommand({text = "Save "..tostring(i).." ("..ParseSave(i).player.name..")", data = {id = i}, callback = function(data)
                        print("Will load", data.id)
                        CloseAllMenu()
                        WindowManager.destroy("Development")
                        LoadSave(data.id)
                        if not CurrentSave.flags.done_tutorial then
                            ActivateEvent(STORY.start_scene)
                        else
                            Scene.set(STORY.main_scene)
                        end
                    end})
                end
                
                AddMenuCommand({text = "Back", callback = RemoveMenu})
            end})
            --[[AddMenuCommand({text = "Save Slot", hover_text = "Changes which save slot to use by default.",
            
            value = function() return GlobalSave.system.savefile end,
            
            scroll_left = function() GlobalSave.system.savefile = GlobalSave.system.savefile - 1 end,
    
            scroll_right = function() GlobalSave.system.savefile = GlobalSave.system.savefile + 1 end})
            ]]--
            AddMenuCommand({text = "Settings", callback = function()
                CreateMenu({title = "Settings", on_close = function() print("Settings menu closed.") end})
                AddMenuCommand({text = "Music", value = function() return GlobalSave.system.music end,
                
                callback = function() 
                    local r = ToggleMusic()
                    AddNotify("Music: "..r)
                end})
                AddMenuCommand({text = "Music Volume"})
                AddMenuCommand({text = "Open App Data Directory", callback = function()
                    love.system.openURL("file://"..love.filesystem.getSaveDirectory())
                end})
                AddMenuCommand({text = "Back", callback = RemoveMenu})
            end})
            
            AddMenuCommand({text = "Credits", callback = function()
                WindowManager.spawn("Development", 100, 100, 340, 200)
                --WindowManager.fmt("Development", "disable_titlebar", true)
                --WindowManager.fmt("Development", "show_namecard", true)
                WindowManager.add_element("Development", "text1", function(x, y, w, h, data)
                    data = data or {}
                    x = x+5
                    y = y+10
                    G.print("Jade Framework "..JADE_VERSION, x, y)
                    
                    y = y+10
                    local major, minor, revision, codename = love.getVersion( )
                    G.print("Built in Love2d "..major.."."..minor.."."..revision.." ("..codename..")", x, y)
                    
                    y = y+10
                    G.print("Written by Kaiser (@_technomancer)", x, y)
                    
                    y = y+20
                    G.print("Asset credits todo", x, y)
                    
                    y = y+20
                    WindowManager.Button("Github", x, y, data, function()
                        love.system.openURL("https://github.com/technomancy7/project-jade")
                    
                    end)
                    
                    y = y+20--h-20
                    WindowManager.Button("Close Window", x, y, data, function()
                        WindowManager.destroy("Development")
                    
                    end)
                end)
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

Templates = {}

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
    for _, tile in ipairs(Geometry[target].tiles) do
        G.draw(Tiles[tile[3]], tile[1], tile[2])
    end
end

function IsMusicEnabled()
    return GlobalSave.system.music
end

function ToggleMusic()
    if IsMusicEnabled() then
        DisableMusic()
        return "off"
    else
        EnableMusic()
        return "on"
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
    local s, m = FS.write(name, JSON.encode(data))
    print(s, m)
end

function LoadFile(name)
    local data = FS.read(name)
    return JSON.decode(data)
end

function WriteSave()
    SaveFile("saves/"..GetSaveFile(), CurrentSave)
    return GlobalSave.system.savefile
end

function ListSaves()
    local out = {}
    print("Scanning saves in", SaveDir)
    for _, item in ipairs(love.filesystem.getDirectoryItems("saves")) do
        if string.starts_with(item, "save") and string.ends_with(item, ".json") then 
            local f = tonumber(string.match(item, "%d+"))
            table.insert(out, f)
        end
    end
    return out
end

function GetNextSaveID()
    local lastid = -1
    local saves = ListSaves()
    
    if #saves == 0 then return 0 end

    while true do
        lastid = lastid + 1
        print("Checking", lastid)
        if not table.contains(saves, lastid) then return lastid end
    end
end

function ParseSave(id)
    return LoadFile("saves/"..GetSaveFile(id))
end

function LoadSave(newsave)
    if newsave == "default" then
        CurrentSave = DeepCopy(DefaultSave)
        return
    end
    GlobalSave.system.savefile = tonumber(newsave)
    if FS.getInfo("saves/"..GetSaveFile(newsave)) == nil then
        return false

    else
        print("Loading saves/"..GetSaveFile(newsave))
        CurrentSave = LoadFile("saves/"..GetSaveFile(newsave))
        return true
    end
end

function GetSaveFile(i)
    if i == nil then i = GlobalSave.system.savefile end
    return "save" .. tostring(i) .. ".json"
end

function SaveExists(i)
    return (FS.getInfo("saves/"..GetSaveFile(i)) ~= nil)
end

function GetKey(action)
    if GlobalSave.keys[action] == nil then return "undefined" end
    return " [ "..table.concat(GlobalSave.keys[action], " | ").." ] "
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
                if Hooks[k] == nil then Hooks[k] = {} end
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
    print("Initializing Jade Framework "..JADE_VERSION.."...")
    
    -- Defining state
    SaveDir = FS.getSaveDirectory()
    print("SaveDir", SaveDir)
    STORY = require 'stories.abyssal' --TODO add way to change story
    
    -- Loading assets
    Fonts.main = G.newFont("fonts/RobotoMonoNerdFontMono-Bold.ttf")--("FiraCodeNerdFont-Bold.ttf")
    Fonts.menu = G.newFont("fonts/FiraCodeNerdFont-Retina.ttf", 16)--("fonts/RobotoMonoNerdFontMono-Bold.ttf", 14)
    Fonts.notify = G.newFont("fonts/RobotoMonoNerdFontMono-Bold.ttf", 14)
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
    
    -- Loading maps  
    if FS.getInfo("maps") == nil then love.filesystem.createDirectory( "maps" ) end
    
    for _, item in ipairs(love.filesystem.getDirectoryItems( "maps" )) do
        if string.ends_with(item, ".json") then 
            local f = string.gsub(item, "%..+", "")
            print("Loading map", love.filesystem.getSource().."/maps/"..item.." as "..f)
            local data = LoadFile("maps/"..item)
            Geometry[f] = data
        end
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
    if Hooks.keypress ~= nil then
        for _, v in pairs(Hooks.keypress) do
            blocking = v(key, scancode, isrepeat)
        end
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
    ExecHook("textinput", {t})
    
    if Scene.get().textinput ~= nil then
        Scene.get().textinput(t)
    end
end

function ExecHook(name, data)
    if Hooks[name] == nil then return end

    for _, v in pairs(Hooks[name]) do
        if data == nil then 
            v()
        else
            v(unpack(data))
        end
    end
end

function love.mousepressed( x, y, button, istouch, presses )
    ExecHook("mousepressed", {x, y, button, istouch, presses})
    if Scene.get().mousepressed ~= nil then
        Scene.get().mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased( x, y, button, istouch, presses )
    ExecHook("mousereleased", {x, y, button, istouch, presses})
    if Scene.get().mousereleased ~= nil then
        Scene.get().mousereleased(x, y, button, istouch, presses)
    end
end

function love.mousemoved( x, y, dx, dy, istouch )
    ExecHook("mousemoved", {x, y, dx, dy, istouch})
    if Scene.get().mousemoved ~= nil then
        Scene.get().mousemoved(x, y, dx, dy, istouch)
    end
end

function love.draw() 
    ExecHook("predraw")
    
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
    
    if Scene.get().postdraw ~= nil then
        Scene.get().postdraw()
    end
    
    ExecHook("postdraw")
    
    
end

function love.quit()
    --TODO handle saving state on exit
    return false
end
