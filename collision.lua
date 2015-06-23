function create_collision()
    local self = {}

    self.world = love.physics.newWorld()
    love.physics.setMeter(Screen.pixels_per_meter)

    return self
end