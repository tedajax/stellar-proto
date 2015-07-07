Vec2 = require 'vec2'
require 'log'

function create_movement(body, feet)
    local self = {}

    self.body = body

    -- feet is the shape connected to the body that will be used for
    -- determining what's landed on.
    -- This is expected to be a CircleShape
    self.feet = feet

    -- movement properties
    self.ground = {}
    self.ground.acceleration = 300 -- horizontal acceleration on ground
    self.ground.max_speed = 800 -- horizontal speed on ground
    self.ground.friction = 0.5 -- how fast we slow down on the ground (horizontal)

    self.air = {}
    self.air.acceleration = 150 -- horizontal acceleration in air
    self.air.max_speed = 800
    self.air.friction = 0.1 -- how fast we slow down in air (horizontal)

    self.jump_force = 120
    self.jump_hold_force = 100
    self.jump_requested = false

    self.is_on_ground = false
    self.is_jumping = false

    self.input = { x = 0, y = 0, jump = false }

    self.set_input = function(self, x, y, jump)
        self.input.x = x
        self.input.y = y
        self.input.jump = jump or false
    end

    self.request_jump = function(self)
        self.jump_requested = true
    end

    self.check_on_ground = function(self)
        local bx, by = self.body:getPosition()
        local body_pos = Vec2(self.body:getPosition())
        local s = Vec2(feet:getPoint()) + body_pos
        local e = s + Vec2(0, feet:getRadius() + 10)
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

        if self.is_on_ground and self.jump_requested then
            self.is_jumping = true
            self.body:applyLinearImpulse(0, -self.jump_force)
        end

        Log:debug(tostring(self.input.jump))

        if self.is_jumping then
            if self.input.jump then
                local _, vy = self.body:getLinearVelocity()
                if vy > 0 then
                    self.body:applyForce(0, -self.jump_hold_force)
                end
            else
                self.is_jumping = false
            end
        end

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

        self.jump_requested = false
    end

    return self
end