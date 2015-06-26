Vec2 = require 'vec2'

function create_movement(body, feet)
    local self = {}

    self.body = body

    -- feet is the shape connected to the body that will be used for
    -- determining what's landed on.
    -- This is expected to be a CircleShape
    self.feet = feet

    -- movement properties
    self.ground = {}
    self.ground.acceleration = 1000 -- horizontal acceleration on ground
    self.ground.max_speed = 250 -- horizontal speed on ground
    self.ground.friction = 0.5 -- how fast we slow down on the ground (horizontal)

    self.air = {}
    self.air.acceleration = 100 -- horizontal acceleration in air
    self.air.max_speed = 250
    self.air.friction = 0.5 -- how fast we slow down in air (horizontal)

    self.is_on_ground = false

    self.input = { x = 0, y = 0 }

    self.set_input = function(self, x, y)
        self.input.x = x
        self.input.y = y
    end

    self.check_on_ground = function(self)
        local s = Vec2(feet:getPoint())
        local e = s + Vec2(0, feet:getRadius() + 1)
        local hits = Collision:ray_cast(s, e)
        self.is_on_ground = #hits > 0
        return self.is_on_ground
    end

    self.get_value = function(self, name)
        if self.is_on_ground then
            return self.ground[name]
        else
            return self.air[name]
        end
    end

    self.update = function(self, dt)
        self:check_on_ground()

        local acceleration = self:get_value("acceleration")
        local friction = self:get_value("friction")
        local max_speed = self:get_value("max_speed")

        local velocity = Vec2(self.input.x, self.input.y)

        velocity = velocity * acceleration * dt

        self.body:applyLinearImpulse(velocity.x, 0)

        local lvx, lvy = self.body:getLinearVelocity()

        if self.input.x == 0 then
            lvx = lvx * (1 - friction)
        end

        self.body:setLinearVelocity(
            math.clamp(lvx, -max_speed, max_speed),
            lvy
        )
    end

    return self
end