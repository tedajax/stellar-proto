local json = require 'json'
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

    Input = create_input()

    Input:add_axis("horizontal")
    Input:add_axis("vertical")

    Input:create_axis_binding("horizontal", "right", 1)
    Input:create_axis_binding("horizontal", "left", -1)
    Input:create_axis_binding("vertical", "up", -1)
    Input:create_axis_binding("vertical", "down", 1)

    Input:add_button("jump")
    Input:create_button_binding("jump", "z")

    Input:add_button("fire")
    Input:create_button_binding("fire", "x")

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
end

function love.draw()
    Game:render()

    Log:render()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "`" then
        debug.debug()
    end

    Input:on_key_down(key)
    Game:on_key_down(key)
end

function love.keyreleased(key)
    Input:on_key_up(key)
    Game:on_key_up(key)
end