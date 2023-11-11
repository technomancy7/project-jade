
return {
    -- Name of our script
    name = "edit",
    
    -- Author name
    author = "Techno",
    
    -- Container that gets filled with the main runtime global functions
    globals = {},
    
    autoload = true, 
    
    -- Function that runs on loading, if any setup is needed
    on_connect = function()
        print("Editors loaded.")
    end,
    
    -- Table that is merged in to the global scens
    scenes = {
        text_editor = {
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
        map_editor = {
            vars = {
                CurrentTile = "",
                TileIndex = 1,
                CurTileSolid = false,
                CurrentMap = "",
                MouseXRaw = 0,
                MouseYRaw = 0,
                MouseXTile = 0,
                MouseYTile = 0,
                ForceTileAlign = true
            },
            keypress = function( key, scancode, isrepeat ) 
                if key == "f1" then
                    AddNotify("-- Help Notify --")
                    AddNotify("F5 = Tile Alignment")
                    AddNotify("F4 = Tile Solidity")
                    AddNotify("G = Show Grid")
                    AddNotify("A/S = Cycle Tile")
                end
                
                if key == "f5" then 
                    SV().ForceTileAlign = not SV().ForceTileAlign 
                    AddNotify("Tile Alignment: "..tostring(SV().ForceTileAlign), 100)
                end
                
                if key == "f4" then 
                    SV().CurTileSolid = not SV().CurTileSolid
                    AddNotify("Tile Solidity: "..tostring(SV().CurTileSolid), 100)
                end
                
                if key == "g" then
                    ShowGrid = not ShowGrid
                    AddNotify("Grid: "..tostring(ShowGrid))
                end
                
                local GetTileIndex = function(target)
                    --print("Getting tile at "..target)
                    local index = 1
                    for k, v in pairs(Tiles) do
                        if index == target then
                            --print("Returning ", k, v)
                            return k, v
                        end
                        index = index + 1
                    end
                end
                
                if key == "a" then
                    SV().TileIndex = SV().TileIndex - 1
                    if SV().TileIndex <= 0 then SV().TileIndex = table.len(Tiles) end
                    SV().CurrentTile, _ = GetTileIndex(SV().TileIndex)
                    AddNotify("Tile Change: "..SV().TileIndex.."/"..table.len(Tiles).." "..SV().CurrentTile, 50)
                end
                
                if key == "s" then
                    SV().TileIndex = SV().TileIndex + 1
                    if SV().TileIndex > table.len(Tiles) then SV().TileIndex = 1 end
                    SV().CurrentTile, _ = GetTileIndex(SV().TileIndex)
                    AddNotify("Tile Change: "..SV().TileIndex.."/"..table.len(Tiles).." "..SV().CurrentTile, 50)
                end
                
            end,
            mousepressed = function( x, y, button, istouch, presses )
                --TODO delete any existing entries on that space first
                -- may need to write some helper functions, one for GetTile, SetTile, DeleteTile
                if SV().ForceTileAlign then
                    table.insert(Geometry[SV().CurrentMap].tiles, {SV().MouseXTile, SV().MouseYTile, SV().CurrentTile})
                else
                    table.insert(Geometry[SV().CurrentMap].tiles, {SV().MouseXRaw, SV().MouseYRaw, SV().CurrentTile})
                end
                
                
            end,
            mousemoved = function( x, y, dx, dy, istouch ) 
                SV().MouseXRaw = x
                SV().MouseYRaw = y
                SV().MouseXTile = math.floor(SV().MouseXRaw / 32) * 32
                SV().MouseYTile = math.floor(SV().MouseYRaw / 32) * 32
            end,
            opening = function() end,
            update = function(dt) 
                FadeBGTo(0, 0, 0)
            end,
            draw = function() 
                local s = SV()
                local filename = s.CurrentMap
                RenderMap(filename)
                
                if SV().ForceTileAlign then
                    G.print("<A "..SV().TileIndex..": "..SV().CurrentTile.." S>", SV().MouseXTile, SV().MouseYTile-15)
                    G.draw(Tiles[SV().CurrentTile], SV().MouseXTile, SV().MouseYTile)
                else
                    G.print("<A "..SV().TileIndex..": "..SV().CurrentTile.." S>", SV().MouseXRaw, SV().MouseYRaw-15)
                    G.draw(Tiles[SV().CurrentTile], SV().MouseXRaw, SV().MouseYRaw)
                end
                
                G.print("Map: "..filename.." // Tile: "..s.CurrentTile.." (Solid (F4): "..tostring(s.CurTileSolid)..") // Mouse: "..s.MouseXRaw.."/"..s.MouseYRaw.." ("..math.floor(SV().MouseXRaw / 32).."/"..math.floor(s.MouseYRaw / 32)..") [Toggle Alignment: F5] // Grid: "..tostring(ShowGrid).." (G)")
                
                local ti = Geometry[filename].name or "Undefined"
                local aut = Geometry[filename].author or "Undefined"
                G.print("Name: "..ti.." // Author: "..aut, 0, 20)
            end,
            closing = function() end
        },
    },
    commands = {
        edit = function(line)
            print("EDIT: ", line)
        end,
        map = function(line)
            local cmd = ""
            local val = ""
            
            -- If there is spaces in the string, split the input so word 1 is the command and the rest is the parameters
            if select(2, string.gsub(line, " ", "")) >= 1 then
                cmd, val = string.match(line, "(%S+)%s(.*)")
            else
                cmd = line
            end
            
            if cmd == "edit" then
                if val == "" then AddNotify("Map name required.") else                     
                    if Geometry[val] == nil then
                        Geometry[val] = {author = "", tiles = {}, name = ""}
                        AddNotify("New project created as "..val..".")
                    else
                        AddNotify("Loaded map "..val)
                    end
                    
                    Scene.set("map_editor")
                    SV().CurrentMap = val
                    SV().CurrentTile, _ = next(Tiles, nil)
                    SV().CurTileSolid = true
                    CloseAllMenu()
                    CloseConsole()
                end
            elseif cmd == "name" then
                Geometry[SV().CurrentMap].name = val
            elseif cmd == "author" then
                Geometry[SV().CurrentMap].author = val    
            elseif cmd == "save" then
                    if Scene.name ~= "map_editor" then return AddNotify("Map editor not open.") end
                    local m = SV().CurrentMap
                    if Geometry[m] ~= nil then
                        local data = Geometry[m]
                        SaveFile("maps/"..m..".json", data)
                        AddNotify("Saved map maps/"..m..".json")
                    else
                        AddNotify("Missing map data...")
                    end
            end
        end
    }
}
