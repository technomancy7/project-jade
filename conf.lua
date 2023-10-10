function love.conf(t)
    local name = "Abyssal Odyssey"
    t.identity = name
    t.window.title = name
    --t.modules.joystick = false
    t.modules.physics = false
    t.window.width = 1280
    t.window.height = 640
    t.window.resizable = false
end
