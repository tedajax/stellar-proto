require 'input'
require 'game'
require 'log'

function math.clamp(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

function S(v)
    return (v * Screen.pixels_per_meter) * Screen.scale_x
end

function SX(v)
    return (v * Screen.pixels_per_meter) * Screen.scale_x
end

function SY(v)
    return (v * Screen.pixels_per_meter) * Screen.scale_y
end

function X(x)
    return (x * Screen.pixels_per_meter) * Screen.scale_x + (Screen.width / 2)
end

function Y(y)
    return (y * Screen.pixels_per_meter) * Screen.scale_y + (Screen.height / 2)
end

function love.load()
    Screen = {}
    Screen.width = love.graphics.getWidth()
    Screen.height = love.graphics.getHeight()
    Screen.base_width = 1280
    Screen.base_height = 720
    Screen.pixels_per_meter = 1
    Screen.scale_x = Screen.width / Screen.base_width
    Screen.scale_y = Screen.height / Screen.base_height

    Input = create_input()

    Input:add_axis("horizontal")
    Input:add_axis("vertical")

    Input:create_axis_binding("horizontal", "right", 1)
    Input:create_axis_binding("horizontal", "left", -1)
    Input:create_axis_binding("vertical", "up", -1)
    Input:create_axis_binding("vertical", "down", 1)

    Input:add_button("select")
    Input:create_button_binding("select", "z")

    Input:add_button("cancel")
    Input:create_button_binding("cancel", "x")

    Game = create_game()
    Game:init()

    Log = create_log()
end

function love.update(dt)
    Game:update(dt)
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
    end

    Input:on_key_down(key)
end

function love.keyreleased(key)
    Input:on_key_up(key)
end