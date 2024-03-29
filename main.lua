local _print = print
local json = require 'json'
local console = require 'console.console'
require 'input'
require 'game'
require 'log'
require 'camera'

function math.clamp(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

function love.load()
    Screen = {}
    Screen.width = love.graphics.getWidth()
    Screen.height = love.graphics.getHeight()
    Screen.base_width = 1280
    Screen.base_height = 720

    Defaults = json.load("defaults.json")

    local consoleFont = Defaults.console_font
    Console = console.new(consoleFont, Screen.width, 400, 4, function() end)
    console_register_commands(Console)
    Console:print_intro(Defaults.game.name, Defaults.game.version)

    Input = create_input()

    Input:add_axis("horizontal")
    Input:add_axis("vertical")

    Input:create_axis_binding("horizontal", "right", 1)
    Input:create_axis_binding("horizontal", "left", -1)
    Input:create_axis_binding("vertical", "up", -1)
    Input:create_axis_binding("vertical", "down", 1)

    Input:add_button("jump")
    Input:create_button_binding("jump", "z")

    Input:add_button("flag")
    Input:create_button_binding("flag", "x")

    Input:add_button("fire")
    -- Input:create_button_binding("fire", "x")

    Input:add_button("debug")
    Input:create_button_binding("debug", "g")

    Camera = create_camera()
    Camera.base_zoom = Screen.base_width / Screen.width
    Camera:look_at(0, 0)

    Game = create_game()
    Game:init()

    Timescale = 1

    Log = create_log()
end

function love.update(dt)
    Game:update(dt * Timescale)
    Camera:update(dt * Timescale)
    Input:update(dt)
    Log:update(dt)
    Console:update(dt)
end

function love.draw()
    Game:render()
    Log:render()
    Console:render()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "`" then
        Console:focus()
    end

    if not Console:has_focus() then
        Input:on_key_down(key)
        Game:on_key_down(key)
    end
end

function love.keyreleased(key)
    Input:on_key_up(key)
    Game:on_key_up(key)
end

local function command_set_gravity(gx, gy)
    if gy == nil then
        Game.collision.world:setGravity(0, gx)
    else
        Game.collision.world:setGravity(gx, gy)
    end
end

local function command_reload_movement(filename)
    filename = filename or Defaults.game.movement_props
    local movementProps = json.load(filename)
    if movementProps ~= nil then
        Game.player_controller.movement:setProperties(movementProps)
        print("Reloaded movement properties from "..filename..".")
    else
        perror("Unable to load movement properties from "..filename..".")
    end
end

local function command_set_font(p1, p2)
    if p2 == nil and tonumber(p1) ~= nil then
        Console:set_font({ ptsize = tonumber(p1) })
    elseif p2 ~= nil then
        Console:set_font({ filename = p1, ptsize = tonumber(p2) })
    else
        perror("Unable to parse font parameters.")
    end
end

local function command_display_commands()
    print("-------------------------------------------------------------------------------------------------------------------------------")
    print("Comands are executed as the name of the command followed by whitespace delimited parameters (e.g.):")
    print("> help")
    print("> clear")
    print("> gravity 1000")
    print("> font assets/fonts/VeraMono.ttf 18")
    print("> font 12")
    print(" ")
    print("A list of available commands follows:")
    for k, v in pairs(Console.commands) do
        if k ~= "commands" then
            local s = k
            if v[2] ~= nil then
                s = s.." "..v[2]
            end
            print(s)
        end
    end
    print("-------------------------------------------------------------------------------------------------------------------------------")
end

local function command_display_help()
    print("-------------------------------------------------------------------------------------------------------------------------------")
    print("Arbitrary Lua can be executed within this console.")
    print("> print(\"hello, world\")")
    print("hello, world")
    print(" ")
    print("This is quite useful for debugging as you can also directly manipulate variables.")
    print("> myvar = 5")
    print("> print(myvar)")
    print("5")
    print(" ")
    print("For ease of use there are also commands available that don't require function call syntax.")
    print("For a list of available commands use the 'commands' command")
    print("> commands")
    print("...")
    print(" ")
    print("You can also cycle through history with the up/down arrow keys.")
    print("Using the <tab> key will cycle through autocomplete with varying degrees of success.")
    print("-------------------------------------------------------------------------------------------------------------------------------")
end

local function command_memory()
    print("Memory in usage by Lua:")
    local count = collectgarbage("count")
    print(string.format("%.2fkb", count))
end

local function command_gotoxy(x, y)
    Game.player:set_position(Vec2(x, y))
end

local function command_getxy()
    print("Position:", tostring(Game.player.position.x)..", "..tostring(Game.player.position.y))
end

quit = love.event.quit
exit = love.event.quit
print = function(...) _print(...); Console:print(...) end
perror = function(...) _print(...); Console:error(...) end
help = command_display_help

function console_register_commands(console)
    console.commands = {
        help        = { command_display_help, "-- Display help message." },
        commands    = { command_display_commands, "-- Displays a list of commands." },
        quit        = { love.event.quit, "-- Quit game.." },
        exit        = { love.event.quit, "-- Exit game." },
        clear       = { function() Console:clear() end, "-- Clear the console." },
        gravity     = { command_set_gravity, "number -- Sets gravity to number." },
        movement    = { command_reload_movement, "<filename> -- Reload player movement properties." },
        font        = { command_set_font, "<filename> ptsize -- Set console font.  Don't provide filename to just change size." },
        noclip      = { function() Game:noclip() end, "noclip -- Toggle noclip mode." },
        coldbg      = { function() Game.debug_collision = not Game.debug_collision end, "coldbg -- Toggle collision debug render." },
        memory      = { command_memory, "memory -- display memory usage information." },
        gotoxy      = { command_gotoxy, "gotoxy <x> <y> -- put player at position." },
        getxy       = { command_getxy, "gotoxy <x> <y> -- put player at position." },
        timescale   = { function(ts) Timescale = ts or 1 end, "timescale <number> -- set timescale to value or reset if none provided." },
        resetflag   = { function() Game.flag:respawn() end, "resetflag -- put the flag back at the spawn poit." },
        kill        = { function() Game.player:respawn() end, "kill -- kill the player" },
    }
end