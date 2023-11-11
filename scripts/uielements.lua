---@diagnostic disable-next-line: deprecated
---@diagnostic disable: deprecated

-- Containers
FloatingTexts = {}
Notifications = {}
MenuStack = {}

-- Constructors
function AddFloatingText(data)
    if data.float == nil then data.float = true end
    table.insert(FloatingTexts,
        { x = data.x, y = data.y, text = tostring(data.text), lifespan = data.lifespan or 100, i = 0, speed = data.speed,
            direction = 0, float = data.float })
end

function AddNotify(text, lifespan)
    table.insert(Notifications, {text = text or "Missing notification text!", max_lifespan = lifespan or 500, lifespan = lifespan or 500})
end

WindowManager = {
    windows = {},
    emits = {},
    mouse_regions = {},
    spawn = function(label, x, y, width, height, elements, fmt)
        WindowManager.windows[label] = {x = x, y = y, width = width, height = height, elements = elements or {}, fmt = fmt or {}}
        WindowManager.emits[label] = {}
    end,

    edit = function(label, key, val)
        WindowManager.windows[label][key] = val
    end,

    fmt = function(label, key, val)
        WindowManager.windows[label]["fmt"][key] = val
    end,

    toggle_shade = function(label)
        WindowManager.windows[label]["fmt"]["shaded"] = not WindowManager.windows[label]["fmt"]["shaded"]
    end,

    destroy = function(label)
        for k, v in pairs(WindowManager.mouse_regions) do
            print("Killing mouse region ", k)
            if v.parent == label then WindowManager.mouse_regions[k] = nil end
        end
        WindowManager.windows[label] = nil
        WindowManager.emits[label] = nil
    end,
    
    destroy_all = function()
        for k, _ in pairs(WindowManager.windows) do
            WindowManager.destroy(k)
        end
    end,

    add_element = function(label, tag, fn)
        WindowManager.windows[label].elements[tag] = fn
    end,

    remove_element = function(label, tag)
        WindowManager.windows[label].elements[tag] = nil
    end,
    
    Button = function(label, x, y, data, callback)
        data = data or {}

        local mx = data.mx
        local my = data.my
        local font = data.font or Fonts.main
        local width = data.width or font:getWidth(label)
        width = width + 10
        local height = font:getHeight()
        local bg = data.bg or {0.3, 0.3, 0.3}
        local fg = data.fg or {1, 1, 1}
        local text_colour = data.text_colour or {1, 1, 1}
        --if WindowManager.mouse_regions[label] == nil then
        WindowManager.mouse_regions[label] = {parent = data.parent, x = x, y = y, width = width, height = height, callback = callback}
        --end
        if mx > x and mx < x+width and my > y and my < y+height then
            bg = data.sbg or {0.8, 0.8, 0.8}
            --[[if WindowManager.events["mouse_click"] == nil then
                
                WindowManager.events["mouse_click"] = callback
                print("cb", label, WindowManager.events["mouse_click"])
            end
        else
            if WindowManager.events["mouse_click"] ~= nil then
                WindowManager.events["mouse_click"] = nil
                print("cbnil", label, WindowManager.events["mouse_click"])
            end]]--
        end
        
        G.setColor(bg)
        G.rectangle("fill", x, y, width, height)
        
        G.setColor(fg)
        G.rectangle("line", x, y, width, height)
        
        G.setColor(text_colour)
        G.print(label, x+5, y)
        
    end,
    draw = function(label, x, y, width, height, elements, fmt)
        local titlebar_height = 20
        local mx, my = M.getPosition() 
        
        -- Title bar
        
        if fmt.disable_titlebar ~= true then
            G.setColor(fmt.bg or {0.3, 0.3, 0.3})
            G.rectangle("fill", x, y-titlebar_height, width, titlebar_height)
            
            G.setColor(fmt.fg or {1, 1, 1})
            G.rectangle("line", x, y-titlebar_height, width, titlebar_height)
            G.print(label, x+20, y-titlebar_height)
            
            if mx > x and mx < x+width-45 and my > y-titlebar_height and my < y then
                G.print("#", x+10, y-titlebar_height)
                WindowManager.emits[label]["hover_titlebar"] = true
            else
                WindowManager.emits[label]["hover_titlebar"] = false
            end
            
            if mx > x+width-45 and mx < x+width-45+Fonts.main:getWidth("[_]") and my < y and my > y-titlebar_height then
                G.print("[_]", x+width-45, y-titlebar_height+2)
                WindowManager.emits[label]["hover_shade"] = true
            else
                G.print("[_]", x+width-45, y-titlebar_height)
                WindowManager.emits[label]["hover_shade"] = false
            end
            
            if mx > x+width-25 and mx < x+width-25+Fonts.main:getWidth("[X]") and my < y and my > y-titlebar_height then
                G.print("[X]", x+width-25, y-titlebar_height+2)
                WindowManager.emits[label]["hover_close"] = true
            else
                G.print("[X]", x+width-25, y-titlebar_height)
                WindowManager.emits[label]["hover_close"] = false
            end
        else
            if fmt.show_namecard then
                G.setColor(fmt.bg or {0.3, 0.3, 0.3})
                local w = Fonts.main:getWidth(label)
                G.rectangle("fill", x+5, y-titlebar_height, w+10, titlebar_height)
                
                G.setColor(fmt.fg or {1, 1, 1})
                G.rectangle("line", x+5, y-titlebar_height, w+10, titlebar_height)
                G.print(label, x+10, y-titlebar_height)
            end
        end
        
        if fmt.shaded ~= true then
            -- Main Window
            G.setColor(fmt.bg or {0.5, 0.5, 0.5})
            G.rectangle("fill", x, y, width, height)
            
            G.setColor(fmt.fg or {1, 1, 1})
            G.rectangle("line", x, y, width, height)
            
            for k, v in pairs(elements) do
                if v ~= nil then
                    v(x, y, width, height, {mx = mx, my = my, parent = label})
                end
            end
        end
    end
}


-- Menus
MenuSystems = {
    command = {
        mouse_click = function(current, mx, my, button)
            local font = Fonts.menu
            
            for i, cmd in ipairs(current.commands) do     
                local base_x = cmd.real_x or 0
                local base_y = cmd.real_y or 0
                --print(mx, base_x, my, base_y, font:getHeight())
                if mx > base_x and mx < base_x + font:getWidth(cmd.text) and my > base_y and my < base_y + font:getHeight() then
                    Sfx(cmd.sfx)
                    cmd.callback(cmd.data) 
                end
            end
        end,
        
        mouse_select = function(current, mx, my)
            local font = Fonts.menu
            
            for i, cmd in ipairs(current.commands) do     
                local base_x = cmd.real_x or 0
                local base_y = cmd.real_y or 0
                --print(mx, base_x, my, base_y, font:getHeight())
                if mx > base_x and mx < base_x + font:getWidth(cmd.text) and my > base_y and my < base_y + font:getHeight() then
                    current.cursor = i
                end
            end
        end,
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

            if cent_x then x = (G.getWidth() - w) / 2 end

            if cent_y then y = (G.getHeight() - h) / 2 end

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
                cmd.real_x = text_x
                cmd.real_y = text_y
                G.setFont(Fonts.main)
                if DebugMode then G.print(tostring(text_y), text_x-40, text_y) end
                
                G.setColor({1, 1, 1, 1})
                text_y = text_y + font:getHeight()
            end
        end, 
        key = function(current, key)
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
                --local m = GetCurrentMenu()
                
                if current.cursor > 1 then 
                    current.cursor = current.cursor - 1 
                else
                    current.cursor = #current.commands
                end
                
                return true
            end

            if table.contains(GlobalSave.keys.fire_down, key) or table.contains(GlobalSave.keys.move_down, key) then
                --local m = GetCurrentMenu()
                
                if current.cursor < #current.commands then 
                    current.cursor = current.cursor + 1 
                else
                    current.cursor = 1
                end
                
                return true
            end

            if table.contains(GlobalSave.keys.confirm, key) then
                local m = current
                
                if m.commands[m.cursor].callback ~= nil and m.commands[m.cursor].enabled then
                    Sfx(m.commands[m.cursor].sfx)
                    m.commands[m.cursor].callback() 
                end
                return true
            end

            if table.contains(GlobalSave.keys.cancel, key) then
                local m = current
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
        bg = {0.5, 0.5, 0.5, 1},
        border = {1, 1, 1, 1},
        border_thickness = 2,
        commands = {},
        text_colour = {1, 1, 1, 1},
        select_colour = {0, 0, 0, 1},
        disabled_colour = {0, 0, 0, 0.2},
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

function HandleMenuMouseSelect(x, y)
    if IsMenuOpen() then
        local current = MenuStack[#MenuStack]
        if MenuSystems[current.menu_type] ~= nil then
            return MenuSystems[current.menu_type].mouse_select(current, x, y)
        end
    end
end

function HandleMenuMouseClick(x, y, button)
    if IsMenuOpen() then
        local current = MenuStack[#MenuStack]
        if MenuSystems[current.menu_type] ~= nil then
            return MenuSystems[current.menu_type].mouse_click(current, x, y, button)
        end
    end
end

function HandleMenuInput(ik)
    if IsMenuOpen() then
        local current = MenuStack[#MenuStack]
        if MenuSystems[current.menu_type] ~= nil then
            return MenuSystems[current.menu_type].key(current, ik)
        end
    end
end

-- Utilities
function DrawGauge(value, max, gx, gy, gw, gh, colours)
    local gaugeWidth = gw or 200 -- width of the gauge
    local gaugeHeight = gh or 20 -- height of the gauge
    local gaugeX = gx or 100 -- x-coordinate of the gauge
    local gaugeY = gy or 100 -- y-coordinate of the gauge
    
    colours = colours or {}
    
    -- Draw the gauge background
    if colours.bg_off ~= true then
        G.setColor(colours.bg or {0.5, 0.5, 0.5})
        G.rectangle("fill", gaugeX, gaugeY, gaugeWidth, gaugeHeight)
    end
    -- Draw the gauge fill
    G.setColor(colours.fg or {1, 1, 1})
    G.rectangle("fill", gaugeX, gaugeY, gaugeWidth * value / max, gaugeHeight)

    -- Draw the gauge value line
    G.setColor(colours.vg or {1, 0, 0})
    G.setLineWidth(2)
    G.line(gaugeX + gaugeWidth * value / max, gaugeY, gaugeX + gaugeWidth * value / max, gaugeY + gaugeHeight)
    G.setColor(1, 1, 1)
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


-- Data
return {
    -- Name of our script
    name = "uielements",
    
    -- Author name
    author = "Techno",
    
    autoload = true, 
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("UI Elements module loaded.")
    end,
    
    hooks = {
        postdraw = {
            debug = function()
                if DebugMode then
                    local mx, my = M.getPosition()
                    G.print(mx.." "..my, mx, my)
                end
            end,
            windows = function()
                for k, v in pairs(WindowManager.windows) do
                    if v ~= nil then
                        WindowManager.draw(k, v["x"], v["y"], v["width"], v["height"], v["elements"], v["fmt"])
                    end
                end
            end,
            
            notifications = function()
                if #Notifications > 0 then
                    G.setFont(Fonts.notify)
                    local text_y = 20
                    for i, notif in ipairs(Notifications) do
                        local text = notif.text
                        local text_x = G.getWidth() - Fonts.notify:getWidth(text) - 30
                        text_y = text_y + 25
                        local rectHeight = Fonts.notify:getHeight()
                        
                        G.setColor({0.2,0.2,0.2, 1})
                        G.rectangle("fill", text_x-10, text_y, Fonts.notify:getWidth(text)+20, rectHeight)
                        G.setColor({1, 1, 1, 1})
                        G.rectangle("line", text_x-10, text_y, Fonts.notify:getWidth(text)+20, rectHeight)

                        
                        G.print(text, text_x, text_y)
                        
                        DrawGauge(notif.lifespan, notif.max_lifespan, text_x-10, text_y+rectHeight, Fonts.notify:getWidth(text)+20, 2, {vg = {1, 1, 1}})--, bg_off = true})
                        
                        notif.lifespan = notif.lifespan - 1
                        if notif.lifespan <= 0 then table.remove(Notifications, i) end
                    end

                    G.setFont(Fonts.main)
                end
            end,
            floating_text = function()
                if #FloatingTexts > 0 then
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
            end
        },
        mousemoved = {
            menu_select = function( x, y, dx, dy, istouch )
                HandleMenuMouseSelect(x, y)
            
            end,
            window_move = function( x, y, dx, dy, istouch )
                for k, v in pairs(WindowManager.emits) do
                    if v ~= nil then
                        if v["hover_titlebar"] == true and v["mousedown_titlebar"] == true then
                            WindowManager.windows[k]["x"] = WindowManager.windows[k]["x"] + dx
                            WindowManager.windows[k]["y"] = WindowManager.windows[k]["y"] + dy
                            return
                        end
                    end
                end
            end
        },
        mousereleased = {
            window_move = function( x, y, button, istouch, presses )
                for k, v in pairs(WindowManager.emits) do
                    v["mousedown_titlebar"] = false
                end
            end
        },
        mousepressed = {
            window_move = function( x, y, button, istouch, presses )
                for k, v in pairs(WindowManager.emits) do
                    if v ~= nil then
                        if v["hover_titlebar"] == true then
                            v["mousedown_titlebar"] = true
                            local w = WindowManager.windows[k]
                            WindowManager.windows[k] = nil
                            WindowManager.windows[k] = w
                            return
                        end
                    end
                end
                
                for k, v in pairs(WindowManager.mouse_regions) do
                    if x > v.x and x < v.x+v.width and y > v.y and y < v.y+v.height then
                        v.callback()

                    end
                end
                --[[if WindowManager.events["mouse_click"] ~= nil then
                    WindowManager.events["mouse_click"]()
                end]]--
            end,
            menu_click = function( x, y, button, istouch, presses )
                HandleMenuMouseClick(x, y, button)
            end,
            window_controls = function( x, y, button, istouch, presses )
                for k, v in pairs(WindowManager.emits) do
                    if v ~= nil then
                        if v["hover_shade"] == true then
                            WindowManager.toggle_shade(k)
                            return
                        end
                        if v["hover_close"] == true then
                            WindowManager.destroy(k)
                            return
                        end
                    end
                end
            
            end
        }
        
    
    },
    commands = {}
}
