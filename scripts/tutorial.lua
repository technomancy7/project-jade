
return {
    -- Name of our script
    name = "tutorial",
    
    -- Author name
    author = "Technomancer",
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Tutorial package loaded.")
    end,
    
    events = {
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
                {"The computer speaks to me...", "goto awakening2"}
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
            get_input = {default_text = "PlayerData().name", run = "PlayerData().name = \"|input|\" | goto awakening3"}
        },
        awakening3 = {
            title = "Awakening",
            conditions = nil,
            body = [[
            "Checking |PlayerData().name|...
            Yes, that does appear to be correct.
            And just for verification purposes, what is the name of your ship?"
            ]],
            get_input = {default_text = "PlayerData().ship_name", run = "PlayerData().ship_name = \"|input|\" | goto awakening4"}
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
    scenes = {},
    
    -- Merged in to the global AI scripts
    ai_scripts = {},
    
    -- Merged in to the global AI scripts
    spawners = {}
}
