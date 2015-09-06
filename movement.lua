Vec2 = require 'vec2'
require 'log'
require 'util'

WALL_CONTACTS = {
    cNone = 0,
    cLeft = 1,
    cRight = 2,
}

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
    self.against_wall = WALL_CONTACTS.cNone
    self.pushing_against_wall = WALL_CONTACTS.cNone
    self.is_stuck_to_wall = false
    self.wall_stick_timer = 0
    self.wall_jump_requested_timer = 0

    self.movement_time = 0

    -- TODO: more robust input
    self.input = { x = 0, y = 0, jump = false }
    self.prev_input = { x = 0, y = 0, jump = false }

    self.set_input = function(self, x, y, jump)
        self.input.x = x
        self.input.y = y
        self.input.jump = jump or false
    end

    self.request_jump = function(self)
        self.jump_requested = true
    end

    self.raycast_relative = function(self, to, offset)
        offset = offset or Vec2(0, 0)
        local body_pos = (Vec2(self.body:getPosition()))
        local s = offset + body_pos
        local e = s + to
        return Collision:ray_cast(s, e)
    end

    self.check_on_ground = function(self)
        local hits = self:raycast_relative(Vec2(0, 10), Vec2(self.feet:getPoint()))
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

    self.check_wall_contacts = function(self)
        -- todo these numbers should be data driven
        local right_hits = self:raycast_relative(Vec2(16, 0))
        local left_hits = self:raycast_relative(Vec2(-16, 0))

        local on_right = #right_hits > 0
        local on_left = #left_hits > 0

        -- favors being against the right wall
        -- if being against both walls at once is a desired thing then this
        -- should be changed to be bitfields
        if on_right == false and on_left == false then
            self.against_wall = WALL_CONTACTS.cNone
        elseif on_right == true then
            self.against_wall = WALL_CONTACTS.cRight
        else
            self.against_wall = WALL_CONTACTS.cLeft
        end
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

    self.on_wall_stick = function(self)
        self.is_stuck_to_wall = true
        self.wall_stick_timer = self.properties.wall_stick_delay
    end

    self.on_wall_unstick = function(self)
        self.is_stuck_to_wall = false
        self.wall_stick_timer = 0
        self.body:setGravityScale(1.0)
        self.wall_jump_requested_timer = 0
    end

    self.jump = function(self)
        self.is_jumping = true
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, 0)
        self.body:applyLinearImpulse(0, -self.properties.jump_force)
        self.used_jumps = self.used_jumps + 1
    end

    self.wall_jump = function(self, scalar)
        self:on_wall_unstick()
        self.wall_jump_requested_timer = 0
        self.is_jumping = true
        self.used_jumps = 1
        local _, vy = self.body:getLinearVelocity()
        if vy > 0 then vy = 0 end
        self.body:setLinearVelocity(0, vy)
        self.body:applyLinearImpulse(scalar * self.properties.wall_jump_force.x, -self.properties.wall_jump_force.y)
    end

    self.update = function(self, dt)
        self:check_on_ground()
        self:check_wall_contacts()

        if self.used_jumps < self.properties.max_jumps and self.jump_requested and not self.is_stuck_to_wall then
            self:jump()
        end

        if self.is_jumping then
            if self.input.jump then
                local _, vy = self.body:getLinearVelocity()
                if vy > 0 and not self.is_stuck_to_wall then
                    self.body:applyForce(0, -self.properties.jump_hold_force)
                end
            else
                self.is_jumping = false
            end
        end

        if math.sign(self.input.x) ~= math.sign(self.prev_input.x) then
            self.movement_time = 0
        else
            self.movement_time = self.movement_time + dt
        end

        local acceleration = self:get_value("acceleration")
        local friction = self:get_value("friction")
        local max_speed = self:get_value("max_speed")

        local move_delay = self:get_value("move_delay")
        if self.is_stuck_to_wall then
            move_delay = self.properties.wall_stick_delay
        end

        local move_x = 0

        if self.movement_time >= move_delay then
            move_x = self.input.x
        end

        local velocity = Vec2(move_x, self.input.y)

        velocity = velocity * acceleration * dt

        self.body:applyLinearImpulse(velocity.x, 0)

        if self.input.x > 0 and self.against_wall == WALL_CONTACTS.cRight then
            self.pushing_against_wall = WALL_CONTACTS.cRight
        elseif self.input.x < 0 and self.against_wall == WALL_CONTACTS.cLeft then
            self.pushing_against_wall = WALL_CONTACTS.cLeft
        else
            self.pushing_against_wall = WALL_CONTACTS.cNone
        end

        if self.is_on_ground == false then
            local _, vy = self.body:getLinearVelocity()

            if self.is_stuck_to_wall then
                if self.against_wall == WALL_CONTACTS.cNone then
                    self:on_wall_unstick()
                end

                if vy > 0 then
                    self.body:setGravityScale(self.properties.wall_gravity_modifier)
                end

                if self.wall_jump_requested_timer > 0 then
                    self.wall_jump_requested_timer = self.wall_jump_requested_timer - dt
                end

                if self.jump_requested then
                    self.wall_jump_requested_timer = self.properties.wall_jump_response_time
                end

                if self.wall_stick_timer > 0 then
                    if self.pushing_against_wall == WALL_CONTACTS.cNone then
                        self.wall_stick_timer = self.wall_stick_timer - dt

                        if self.wall_stick_timer <= 0 then
                            self:on_wall_unstick()
                        end
                    end

                    if self.wall_jump_requested_timer > 0 then
                        if self.against_wall == WALL_CONTACTS.cRight and self.input.x < 0 then
                            self:wall_jump(-1)
                        elseif self.against_wall == WALL_CONTACTS.cLeft and self.input.x > 0 then
                            self:wall_jump(1)
                        end
                    end
                end
            else
                self.body:setGravityScale(1.0)

                if self.pushing_against_wall ~= WALL_CONTACTS.cNone then
                   self:on_wall_stick()
                end
            end
        else
            if self.is_stuck_to_wall then
                self:on_wall_unstick()
            end
        end

        local lvx, lvy = self.body:getLinearVelocity()

        if self.input.x == 0 then
            lvx = lvx * (1 - friction)
        end

        if self.is_stuck_to_wall and lvy > self.properties.wall_slide_max_speed then
            lvy = self.properties.wall_slide_max_speed
        end

        self.body:setLinearVelocity(
            math.clamp(lvx, -max_speed, max_speed),
            lvy
        )

        self.jump_requested = false

        Log:debug("Wall stick: "..tostring(self.is_stuck_to_wall))
        Log:debug("Is on ground: "..tostring(self.is_on_ground))
        Log:debug("Wall stick timer: "..tostring(self.wall_stick_timer))
        Log:debug("Against wall: "..tostring(self.against_wall))
        Log:debug("Pushging against: "..tostring(self.pushing_against_wall))
        Log:debug("Input X: "..tostring(self.input.x))

        for k, v in pairs(self.input) do
            self.prev_input[k] = v
        end
    end

    self.setProperties = function(self, propertiesObj)
        self.properties = propertiesObj
    end

    return self
end