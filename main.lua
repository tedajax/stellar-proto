require 'input'
require 'game'

function S(v)
    return (v * Screen.pixels_per_meter) * Screen.scale_x
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
    Screen.pixels_per_meter = 32
    Screen.scale_x = Screen.width / Screen.base_width
    Screen.scale_y = Screen.height / Screen.base_height

    Input = create_input()

    Game = create_game()
    Game:init()
end

function love.update(dt)
    Game:update(dt)
    Input:update(dt)
end

function love.draw()
    Game:render()
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