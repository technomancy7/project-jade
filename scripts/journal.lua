function OpenJournal()
    MenuDeactivated = true
    local send_search = function()
        print("Sending", WindowManager.entries["Search Bar"])
    end
    local new_entry = function()
        print("New", WindowManager.entries["New Entry"])
    end
    WindowManager.spawn("Journal", 100, 100, 600, 540)
    WindowManager.events["close"]["Journal"] = function()
        MenuDeactivated = false
    end
    WindowManager.focus = {elem = "entry", label = "Search Bar", callback = send_search}
    WindowManager.add_element("Journal", "controls", function(x, y, w, h, data)
        data = data or {}
        x = x+5

        y = y+10
        

        WindowManager.Button("New Entry", x, y, data, new_entry)
        x = x + 100
        WindowManager.TextEntry("Search Bar", x, y, 300, data, send_search)
        x = x - 100
        
        y = y + 30
        local entries = {"this is one", "second entry", "third", "fourth", "number 5", "letter 6"}
        
        WindowManager.ListBox("Journal Entries", x, y, 500, 25, entries, data, function(entry)
        
            AddNotify("Clicked "..entry.label)
        end)
        --print(WindowManager.focus.label)
    end)
                
end
return {
    -- Name of our script
    name = "journal",
    
    -- Author name
    author = "Techno",
    
    autoload = true, 
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Journal loaded.")
    end,

    hooks = {
        keypress = {
            open_journal = function(key)
                if key == "f5" then
                    OpenJournal()
                end
            end
            
        },
    },
    commands = {
        journal = function(line)
            OpenJournal()
        end
    }
}
