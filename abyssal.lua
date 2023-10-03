
return {
    start_scene = "awakening",
    main_scene = "ship_main",
    
    add_crew = function(name) 
        table.insert(CurrentSave.crew, { name = name, health = 100, energy = 100, commands = {} })
        return #CurrentSave.crew
    end
}
