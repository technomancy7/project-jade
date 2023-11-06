print("Loading story Abyssal Odyssey")

LoadEScript("abyssal_scripts")

return {
    start_scene = "awakening",
    main_scene = "ship_main",
    story_name = "Abyssal Odyssey",
    story_author = "Technomancer",
    
    add_crew = function(name) --TODO use same method as menus to change arbitrary values
        table.insert(CurrentSave.crew, { name = name, health = 100, energy = 100, commands = {} })
        return #CurrentSave.crew
    end,

}
