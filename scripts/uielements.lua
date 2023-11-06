FloatingTexts = {}
Notifications = {}

function AddFloatingText(data)
    if data.float == nil then data.float = true end
    table.insert(FloatingTexts,
        { x = data.x, y = data.y, text = tostring(data.text), lifespan = data.lifespan or 100, i = 0, speed = data.speed,
            direction = 0, float = data.float })
end

function AddNotify(text, lifespan)
    table.insert(Notifications, {text = text or "Missing notification text!", max_lifespan = lifespan or 500, lifespan = lifespan or 500})
end

function DrawGauge(value, max, gx, gy, gw, gh, colours)
    local gaugeWidth = gw or 200 -- width of the gauge
    local gaugeHeight = gh or 20 -- height of the gauge
    local gaugeX = gx or 100 -- x-coordinate of the gauge
    local gaugeY = gy or 100 -- y-coordinate of the gauge
    
    colours = colours or {}
    
    -- Draw the gauge background
    if colours.bf_off ~= true then
        G.setColor(colours.bg_r or 0.5, colours.bg_g or 0.5, colours.bg_b or 0.5)
        G.rectangle("fill", gaugeX, gaugeY, gaugeWidth, gaugeHeight)
    end
    -- Draw the gauge fill
    G.setColor(colours.fg_r or 1, colours.fg_g or 1, colours.fg_b or 1)
    G.rectangle("fill", gaugeX, gaugeY, gaugeWidth * value / max, gaugeHeight)

    -- Draw the gauge value line
    G.setColor(colours.vg_r or 1, colours.vg_g or 0, colours.vg_b or  0)
    G.setLineWidth(2)
    G.line(gaugeX + gaugeWidth * value / max, gaugeY, gaugeX + gaugeWidth * value / max, gaugeY + gaugeHeight)
    G.setColor(1, 1, 1)
end

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
                        
                        DrawGauge(notif.lifespan, notif.max_lifespan, text_x-10, text_y+rectHeight, Fonts.notify:getWidth(text)+20, 1, {vg_r = 1, vg_g = 1, vg_b = 1, bg_off = true})
                        
                        notif.lifespan = notif.lifespan - 1
                        if notif.lifespan <= 0 then table.remove(Notifications, i) end
                    end

                    G.setFont(Fonts.main)
                end
            end,
            handle_floating_text = function()
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
        }
        
        
    
    },
    commands = {}
}
