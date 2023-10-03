
return {
    -- Name of our script
    name = "edit",
    
    -- Author name
    author = "Techno",
    
    -- Container that gets filled with the main runtime global functions
    globals = {},
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Text Editor loaded.")
    end,
    
    -- Table that is merged in to the global scens
    scenes = {
        editor = {
            vars = {
                Text = "",
                Cursor = {0, 0}
            },
            keypress = function( key, scancode, isrepeat ) end,
            opening = function() end,
            update = function(dt) end,
            draw = function() end,
            closing = function() end
        },
    },
    commands = {
        edit = function(line)
            print("EDIT: ", line)
        end
    }
}
