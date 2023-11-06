ConsoleInput = ""
ConsoleLogPointer = 0
ConsoleLog = {}
ConsoleMsgs = {}
ConsoleLogStart = 1

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
    cmdln = string.strip(cmdln)
    if string.contains(cmdln, "|") then
        for _, newln in ipairs(string.split(cmdln, "|")) do
            print("Branching command: ", newln)
            ExecCommand(newln)
        end
        return
    end
    local cmd = ""
    local val = ""
    
    -- If there is spaces in the string, split the input so word 1 is the command and the rest is the parameters
    if select(2, string.gsub(cmdln, " ", "")) >= 1 then
        cmd, val = string.match(cmdln, "(%S+)%s(.*)")
    else
        cmd = cmdln
    end
    
    if cmd == "run" then
        print("Running ", val)
        local success, result = pcall(function()
            local chunk = load(val)
            if chunk ~= nil then
                chunk()
            end
        end)
        print("result: ", success, result)
        if result ~= nil then
            if success then
            -- Code executed successfully
                AddLog("Result:" .. result)
            else
            -- Error occurred
                AddLog("Error:" .. result)
            end
        end
        return true
    elseif cmd == "goto" or cmd == "event" then
        ActivateEvent(val)
        return true
    elseif cmd == "scene" then
        Scene.set(val)
        return true
    elseif cmd == "debug" then
        DebugMode = not DebugMode
        AddLog("Debug Mode: "..tostring(DebugMode))
        return true
    elseif cmd == "end" then
        Scene.set(STORY.main_scene)
        return true
    elseif cmd == "get" then
        local str = "return "..val
        print("EXEC: ",str)
        local func = load(str)
        return func()
    else
        for k, v in pairs(CustomCommands) do
            if cmd == k then 
                return v(val)
            end
        end
        return ExecCommand("run "..cmdln)
    end
end

function OpenConsole()
    ConsoleOpen = true
    Paused = true
end

function CloseConsole()
    ConsoleOpen = false
    Paused = false
end

return {
    -- Name of our script
    name = "console",
    
    -- Author name
    author = "Techno",
    
    autoload = true, 
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Console module loaded.")
    end,
    
    hooks = {
        keypress = {
            console_controls = function(key, scancode, isrepeat) 
                if key == "`" then
                    if ConsoleOpen then CloseConsole() else OpenConsole() end
                    return true
                end
                
                if key == "backspace" and ConsoleOpen then
                    ConsoleInput = string.sub(ConsoleInput, 1, -2)
                    return true
                end
                
                if key == "return" and ConsoleOpen then
                    HandleConsole()
                    return true
                end
                
                if key == "pageup" and ConsoleOpen then
                    if ConsoleLogStart >= #ConsoleMsgs then return end 
                    ConsoleLogStart = ConsoleLogStart + 1
                    return true
                end
                
                if key == "pagedown" and ConsoleOpen then
                    if ConsoleLogStart <= 1 then return end 
                    ConsoleLogStart = ConsoleLogStart - 1
                    return true
                end
                
                if key == "down" and ConsoleOpen then
                    if ConsoleLogPointer <= 1 then 
                        ConsoleInput = ""
                        return true
                    end
                    ConsoleLogPointer = ConsoleLogPointer - 1
                    ConsoleInput = ConsoleLog[ConsoleLogPointer]
                    return true
                end
                
                if key == "up" and ConsoleOpen then
                    if ConsoleLogPointer >= #ConsoleLog then return end
                    ConsoleLogPointer = ConsoleLogPointer + 1
                    ConsoleInput = ConsoleLog[ConsoleLogPointer]
                    return true
                end
            end
        },
        textinput = {
            console_text_input = function(t)
                if ConsoleOpen and t ~= "`" then
                    ConsoleInput = ConsoleInput .. t
                end
            end
        },
        
        
        postdraw = {
            console_main = function()
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
        }
        
        
    
    },
    commands = {
        quit = function(val) love.event.quit() end,
        notif = function(val) AddNotify(val) end,
    }
}
