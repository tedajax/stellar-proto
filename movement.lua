Vec2 = require 'vec2'
require 'log'

function create_movement(body, feet, propertiesObj)
    local self = {}

    self.body = body

    -- feet is the shape connected to the body that will be used for
    -- determining what's landed on.
    -- This is expected to be a CircleShape
    self.feet = feet

    -- movement properties
    self.properties = propertiesObj

    -- properties object includes
    -- self.properties.ground = {}
    -- self.properties.ground.acceleration = 300 -- horizontal acceleration on ground
    -- self.properties.ground.max_speed = 200 -- horizontal speed on ground
    -- self.properties.ground.friction = 0.5 -- how fast we slow down on the ground (horizontal)

    -- self.properties.air = {}
    -- self.properties.air.acceleration = 150 -- horizontal acceleration in air
    -- self.properties.air.max_speed = 800
    -- self.properties.air.friction = 0.1 -- how fast we slow down in air (horizontal)

    -- self.properties.jump_force = 120
    -- self.properties.jump_hold_force = 100

    self.jump_requested = false

    self.is_on_ground = false
    self.is_jumping = false
    self.used_jumps = 0

    -- TODO: more robust input
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
        local prev_on_ground = self.is_on_ground
        self.is_on_ground = #hits > 0

        if prev_on_ground ~= self.is_on_ground then
            if self.is_on_ground then
                self:on_land_ground()
            else
                self:on_leave_ground()
            end
        end

        return self.is_on_ground
    end

    self.get_value = function(self, name)
        if self.is_on_ground then
            return self.properties.ground[name]
        else
            return self.properties.air[name]
        end
    end

    self.on_leave_ground = function(self)
        self.used_jumps = 1
    end

    self.on_land_ground = function(self)
        self.used_jumps = 0
    end

    self.update = function(self, dt)
        self:check_on_ground()

        if self.used_jumps < self.properties.max_jumps and self.jump_requested then
            self.is_jumping = true
            local vx, vy = self.body:getLinearVelocity()
            self.body:setLinearVelocity(vx, 0)
            self.body:applyLinearImpulse(0, -self.properties.jump_force)
            self.used_jumps = self.used_jumps + 1
        end

        if self.is_jumping then
            if self.input.jump then
                local _, vy = self.body:getLinearVelocity()
                if vy > 0 then
                    self.body:applyForce(0, -self.properties.jump_hold_force)
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

    self.setProperties = function(self, propertiesObj)
        self.properties = propertiesObj
    end

    return self
end